// Small helper so Supabase functions can (1) check a Firebase login token
// and (2) read/update Firestore using a service account.
// The service account bypasses Firestore security rules, which is exactly
// why only THIS server can mark an order as "paid".
import {
  SignJWT,
  importPKCS8,
  createRemoteJWKSet,
  jwtVerify,
} from "npm:jose@5";

const projectId = Deno.env.get("FIREBASE_PROJECT_ID")!;
const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL")!;
const privateKey = (Deno.env.get("FIREBASE_PRIVATE_KEY") ?? "").replace(/\\n/g, "\n");

const DB = `projects/${projectId}/databases/(default)/documents`;
const DOCS = `https://firestore.googleapis.com/v1/${DB}`;

const ID_PATTERN = /^[A-Za-z0-9]+$/; // Firestore auto-ids; blocks path tricks
const num = (v: any) => Number(v?.doubleValue ?? v?.integerValue ?? 0);

// ---------- 1) Verify the Firebase ID token sent by the app ----------
const jwks = createRemoteJWKSet(
  new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"),
);

/** Returns the user's uid, or throws if the token is invalid. */
export async function verifyFirebaseToken(idToken: string): Promise<string> {
  const { payload } = await jwtVerify(idToken, jwks, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
  });
  if (!payload.sub) throw new Error("Token has no user id");
  return payload.sub;
}

// ---------- 2) Get a Google access token for Firestore ----------
let cached: { token: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;

  const key = await importPKCS8(privateKey, "RS256");
  const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/datastore" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(clientEmail)
    .setSubject(clientEmail)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error("Google token error: " + await res.text());
  const data = await res.json();
  cached = { token: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return cached.token;
}

// ---------- 3) Firestore helpers ----------
export type Order = {
  id: string;
  userId: string;
  status: string;
  total: number;
  items: { productId: string; quantity: number }[];
};

export async function getOrder(orderId: string): Promise<Order | null> {
  if (!ID_PATTERN.test(orderId)) return null;
  const res = await fetch(`${DOCS}/orders/${orderId}`, {
    headers: { Authorization: `Bearer ${await accessToken()}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(await res.text());

  const f = (await res.json()).fields ?? {};
  return {
    id: orderId,
    userId: f.userId?.stringValue ?? "",
    status: f.status?.stringValue ?? "",
    total: num(f.totalAmount),
    items: (f.items?.arrayValue?.values ?? []).map((v: any) => ({
      productId: v.mapValue.fields.productId.stringValue,
      quantity: num(v.mapValue.fields.quantity),
    })),
  };
}

/** Current price of a product in Firestore (null if it doesn't exist). */
export async function getProductPrice(productId: string): Promise<number | null> {
  if (!ID_PATTERN.test(productId)) return null;
  const res = await fetch(`${DOCS}/products/${productId}`, {
    headers: { Authorization: `Bearer ${await accessToken()}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(await res.text());
  return num((await res.json()).fields?.price);
}

/** Sets the order status. When "paid", also lowers each product's stock. */
export async function markOrder(order: Order, status: "paid" | "failed") {
  const writes: unknown[] = [{
    update: { name: `${DB}/orders/${order.id}`, fields: { status: { stringValue: status } } },
    updateMask: { fieldPaths: ["status"] },
  }];

  if (status === "paid") {
    for (const item of order.items) {
      writes.push({
        transform: {
          document: `${DB}/products/${item.productId}`,
          fieldTransforms: [{
            fieldPath: "stock",
            increment: { integerValue: String(-item.quantity) },
          }],
        },
      });
    }
  }

  const res = await fetch(`${DOCS}:commit`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${await accessToken()}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ writes }),
  });
  if (!res.ok) throw new Error(await res.text());
}
