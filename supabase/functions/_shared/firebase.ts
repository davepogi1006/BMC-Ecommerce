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

function requireConfig(name: string): string {
  const value = Deno.env.get(name) ?? "";
  if (!value || value.includes("your-") || value.includes("paste_")) {
    throw new Error(
      `Missing Firebase configuration: ${name}. Set it in supabase/.env or your deployed Supabase secrets and restart the function.`,
    );
  }
  return value;
}

const projectId = requireConfig("FIREBASE_PROJECT_ID");
const clientEmail = requireConfig("FIREBASE_CLIENT_EMAIL");
const firebaseApiKey = Deno.env.get("FIREBASE_API_KEY") ?? "";
const privateKey = requireConfig("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n");
export const firebaseServiceIdentity = {
  projectId,
  clientEmail,
};

const DB = `projects/${projectId}/databases/(default)/documents`;
const DOCS = `https://firestore.googleapis.com/v1/${DB}`;

const ID_PATTERN = /^[A-Za-z0-9_-]+$/; // Firestore document IDs accept alphanumerics + _ and -, but not `/`.
const num = (v: any) => Number(v?.doubleValue ?? v?.integerValue ?? 0);

function isSafeFirestoreId(value: string): boolean {
  return typeof value === "string" && value.length > 0 && ID_PATTERN.test(value);
}

export class FirebaseApiError extends Error {
  constructor(
    readonly service: string,
    readonly status: number,
    readonly apiStatus?: string,
    readonly permission?: string,
    readonly fallbackError?: FirebaseApiError,
    readonly apiMessage?: string,
  ) {
    super(
      `${service} request failed (HTTP ${status}${
        apiStatus ? `, ${apiStatus}` : ""
      })`,
    );
    this.name = "FirebaseApiError";
  }
}

async function firebaseApiError(
  service: string,
  response: Response,
): Promise<FirebaseApiError> {
  let apiStatus: string | undefined;
  let permission: string | undefined;
  let apiMessage: string | undefined;
  try {
    const body = await response.json();
    if (typeof body.error?.status === "string") {
      apiStatus = body.error.status;
    }
    if (typeof body.error?.message === "string") {
      apiMessage = body.error.message;
      if (firebaseApiKey) {
        apiMessage = apiMessage.replaceAll(firebaseApiKey, "[redacted]");
      }
      if (privateKey) {
        apiMessage = apiMessage.replaceAll(privateKey, "[redacted]");
      }
      apiMessage = apiMessage.slice(0, 180);
    }
    const errorInfo = Array.isArray(body.error?.details)
      ? body.error.details.find((detail: Record<string, unknown>) =>
        typeof detail["@type"] === "string" &&
        detail["@type"].endsWith("google.rpc.ErrorInfo")
      )
      : undefined;
    if (typeof errorInfo?.reason === "string") {
      apiStatus = errorInfo.reason;
    }
    const metadata = errorInfo?.metadata;
    if (
      typeof metadata === "object" &&
      metadata !== null &&
      "permission" in metadata &&
      typeof metadata.permission === "string"
    ) {
      permission = metadata.permission;
    }
  } catch {
    // Keep diagnostics limited to the HTTP status when the response is not JSON.
  }
  return new FirebaseApiError(
    service,
    response.status,
    apiStatus,
    permission,
    undefined,
    apiMessage,
  );
}

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
  const assertion = await new SignJWT({
    scope: "https://www.googleapis.com/auth/datastore https://www.googleapis.com/auth/firebase",
  })
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
  if (!isSafeFirestoreId(orderId)) return null;
  const res = await fetch(`${DOCS}/orders/${encodeURIComponent(orderId)}`, {
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
  if (!isSafeFirestoreId(productId)) return null;
  const res = await fetch(`${DOCS}/products/${encodeURIComponent(productId)}`, {
    headers: { Authorization: `Bearer ${await accessToken()}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(await res.text());
  return num((await res.json()).fields?.price);
}

export async function getUserRole(uid: string): Promise<string | null> {
  if (!isSafeFirestoreId(uid)) return null;
  const res = await fetch(`${DOCS}/users/${encodeURIComponent(uid)}`, {
    headers: { Authorization: `Bearer ${await accessToken()}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error(await res.text());
  const fields = (await res.json()).fields ?? {};
  if (fields.isDisabled?.booleanValue === true) return null;
  return fields.role?.stringValue ?? "customer";
}

export async function listUserProfiles(): Promise<{
  users: Record<string, unknown>[];
  authAccountsAvailable: boolean;
}> {
  const usersById = new Map<string, Record<string, unknown>>();
  let authPageToken: string | undefined;
  let authListingError: FirebaseApiError | undefined;

  const mergeProfile = (id: string, fields: Record<string, any>) => {
    const existing = usersById.get(id);
    const stringField = (name: string) =>
      typeof fields[name]?.stringValue === "string"
        ? fields[name].stringValue
        : "";
    usersById.set(id, {
      ...existing,
      id,
      name: stringField("name") || existing?.name || "",
      email: stringField("email") || existing?.email || "",
      phone: stringField("phone") || existing?.phone || "",
      address: stringField("address"),
      photoUrl: stringField("photoUrl") || existing?.photoUrl || "",
      pendingEmail: stringField("pendingEmail") || null,
      role: stringField("role") || "customer",
      isDisabled: typeof fields.isDisabled?.booleanValue === "boolean"
        ? fields.isDisabled.booleanValue
        : existing?.isDisabled === true,
    });
  };

  let authAccountsAvailable = true;
  try {
    do {
      const url = new URL(
        `https://identitytoolkit.googleapis.com/v1/projects/${projectId}/accounts:batchGet`,
      );
      if (!firebaseApiKey) {
        throw new Error("Firebase API key is not configured.");
      }
      url.searchParams.set("key", firebaseApiKey);
      url.searchParams.set("maxResults", "1000");
      if (authPageToken) url.searchParams.set("nextPageToken", authPageToken);

      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${await accessToken()}` },
      });
      if (!res.ok) {
        throw await firebaseApiError("Firebase Authentication user listing", res);
      }
      const page = await res.json();

      for (const account of page.users ?? []) {
        if (typeof account.localId !== "string") continue;
        usersById.set(account.localId, {
          id: account.localId,
          name: account.displayName ?? "",
          email: account.email ?? "",
          phone: account.phoneNumber ?? "",
          address: "",
          photoUrl: account.photoUrl ?? "",
          pendingEmail: null,
          role: "customer",
          isDisabled: account.disabled === true,
        });
      }
      authPageToken = page.nextPageToken;
    } while (authPageToken);
  } catch (error) {
    authAccountsAvailable = false;
    if (error instanceof FirebaseApiError) authListingError = error;
    console.error(
      "Could not list Firebase Authentication accounts; using Firestore profiles:",
      error,
    );
  }

  if (authAccountsAvailable) {
    const ids = [...usersById.keys()];
    for (let offset = 0; offset < ids.length; offset += 20) {
      const batch = await Promise.all(
        ids.slice(offset, offset + 20).map(async (id) => {
          if (!isSafeFirestoreId(id)) return null;
          const res = await fetch(
            `${DOCS}/users/${encodeURIComponent(id)}`,
            {
              headers: { Authorization: `Bearer ${await accessToken()}` },
            },
          );
          if (res.status === 404) return null;
          if (!res.ok) {
            throw await firebaseApiError("Firestore user profile read", res);
          }
          return { id, fields: (await res.json()).fields ?? {} };
        }),
      );
      for (const profile of batch) {
        if (profile) mergeProfile(profile.id, profile.fields);
      }
    }
  } else {
    let firestorePageToken: string | undefined;
    do {
      const url = new URL(`${DOCS}/users`);
      url.searchParams.set("pageSize", "300");
      if (firestorePageToken) {
        url.searchParams.set("pageToken", firestorePageToken);
      }

      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${await accessToken()}` },
      });
      if (!res.ok) {
        const firestoreError = await firebaseApiError(
          "Firestore user profile listing",
          res,
        );
        throw new FirebaseApiError(
          firestoreError.service,
          firestoreError.status,
          firestoreError.apiStatus,
          firestoreError.permission,
          authListingError,
          firestoreError.apiMessage,
        );
      }
      const page = await res.json();

      for (const document of page.documents ?? []) {
        const id = document.name.split("/").pop();
        if (!id) continue;
        mergeProfile(id, document.fields ?? {});
      }
      firestorePageToken = page.nextPageToken;
    } while (firestorePageToken);
  }

  return {
    users: [...usersById.values()],
    authAccountsAvailable,
  };
}

export async function updateUserRole(
  uid: string,
  role: "admin" | "customer" | "seller",
) {
  if (!isSafeFirestoreId(uid)) throw new Error("Invalid user ID.");
  const res = await fetch(
    `${DOCS}/users/${encodeURIComponent(uid)}?updateMask.fieldPaths=role&updateMask.fieldPaths=updatedAt`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${await accessToken()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        fields: {
          role: { stringValue: role },
          updatedAt: { timestampValue: new Date().toISOString() },
        },
      }),
    },
  );
  if (!res.ok) throw new Error(await res.text());
}

export async function updateUserProfile(
  uid: string,
  profile: { name: string; phone: string; address: string },
) {
  if (!isSafeFirestoreId(uid)) throw new Error("Invalid user ID.");
  const res = await fetch(
    `${DOCS}/users/${encodeURIComponent(uid)}?updateMask.fieldPaths=name&updateMask.fieldPaths=phone&updateMask.fieldPaths=address&updateMask.fieldPaths=updatedAt`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${await accessToken()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        fields: {
          name: { stringValue: profile.name },
          phone: { stringValue: profile.phone },
          address: { stringValue: profile.address },
          updatedAt: { timestampValue: new Date().toISOString() },
        },
      }),
    },
  );
  if (!res.ok) throw new Error(await res.text());
}

export async function setUserDisabled(uid: string, disabled: boolean) {
  if (!isSafeFirestoreId(uid)) throw new Error("Invalid user ID.");
  // The app enforces this flag on sign-in and signs out disabled users.
  const update = await fetch(
    `${DOCS}/users/${encodeURIComponent(uid)}?updateMask.fieldPaths=isDisabled&updateMask.fieldPaths=updatedAt`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${await accessToken()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        fields: {
          isDisabled: { booleanValue: disabled },
          updatedAt: { timestampValue: new Date().toISOString() },
        },
      }),
    },
  );
  if (!update.ok) {
    throw await firebaseApiError("Firestore user profile update", update);
  }
}
/** Sets the order status. When "paid", also lowers each product's stock. */
export async function markOrder(order: Order, status: "paid" | "failed") {
  if (!isSafeFirestoreId(order.id)) throw new Error("Invalid order ID.");
  const writes: unknown[] = [{
    update: { name: `${DB}/orders/${encodeURIComponent(order.id)}`, fields: { status: { stringValue: status } } },
    updateMask: { fieldPaths: ["status"] },
  }];

  if (status === "paid") {
    for (const item of order.items) {
      if (!isSafeFirestoreId(item.productId)) {
        throw new Error(`Invalid product ID: ${String(item.productId)}`);
      }
      if (!Number.isInteger(item.quantity) || item.quantity <= 0) {
        throw new Error(`Invalid quantity for product ${item.productId}`);
      }

      const productRes = await fetch(`${DOCS}/products/${encodeURIComponent(item.productId)}`, {
        headers: { Authorization: `Bearer ${await accessToken()}` },
      });
      if (productRes.status === 404) {
        throw new Error(`Product ${item.productId} not found.`);
      }
      if (!productRes.ok) {
        throw new Error(await productRes.text());
      }

      const stock = num((await productRes.json()).fields?.stock);
      if (stock < item.quantity) {
        throw new Error(`Product ${item.productId} has insufficient stock.`);
      }

      writes.push({
        transform: {
          document: `${DB}/products/${encodeURIComponent(item.productId)}`,
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
