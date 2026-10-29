// Called by the app. Creates a Xendit invoice for one order and returns its URL.
import { getOrder, getProductPrice, verifyFirebaseToken } from "../_shared/firebase.ts";

const XENDIT_SECRET = Deno.env.get("XENDIT_SECRET_KEY")!;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  // Handle CORS preflight requests from browsers
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  // 1) Who is calling? (Firebase login token)
  let uid: string;
  try {
    const token = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
    uid = await verifyFirebaseToken(token);
  } catch {
    return json({ error: "Please log in again." }, 401);
  }

  try {
    // 2) Load the order and check it belongs to this user and is unpaid.
    const { orderId } = await req.json();
    const order = await getOrder(String(orderId ?? ""));
    if (!order || order.userId !== uid) return json({ error: "Order not found." }, 404);
    if (order.status !== "pending") {
      return json({ error: `This order is already ${order.status}.` }, 400);
    }

    // 3) Re-calculate the total from REAL product prices (never trust the phone).
    let expected = 0;
    for (const item of order.items) {
      const price = await getProductPrice(item.productId);
      if (price === null || !Number.isInteger(item.quantity) || item.quantity < 1) {
        return json({ error: "Order has an invalid item." }, 400);
      }
      expected += price * item.quantity;
    }
    if (Math.abs(expected - order.total) > 0.01) {
      return json({ error: "Order total does not match current prices." }, 400);
    }

    // 4) Create the Xendit invoice (secret key goes in Basic auth as the username).
    const res = await fetch("https://api.xendit.co/v2/invoices", {
      method: "POST",
      headers: {
        Authorization: "Basic " + btoa(XENDIT_SECRET + ":"),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        external_id: `${order.id}_${Date.now()}`,
        amount: expected,
        currency: "PHP",
        description: `Shop order ${order.id}`,
        invoice_duration: 86400, // 24 hours
      }),
    });
    const data = await res.json();
    if (!res.ok) return json({ error: data.message ?? "Xendit rejected the request." }, 502);

    return json({ invoiceUrl: data.invoice_url });
  } catch (e) {
    console.error(e);
    return json({ error: "Server error: " + String(e) }, 500);
  }
});