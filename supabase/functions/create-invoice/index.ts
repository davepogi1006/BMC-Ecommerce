import { getOrder, verifyFirebaseToken } from "../_shared/firebase.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  let userId: string;
  try {
    const token = (req.headers.get("Authorization") ?? "").replace(
      /^Bearer\s+/i,
      "",
    );
    userId = await verifyFirebaseToken(token);
  } catch {
    return json({ error: "Please sign in again before paying." }, 401);
  }

  let body: { orderId?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid request body." }, 400);
  }

  const orderId = typeof body.orderId === "string" ? body.orderId.trim() : "";
  if (!orderId) return json({ error: "An order ID is required." }, 400);

  try {
    const order = await getOrder(orderId);
    if (!order) return json({ error: "Order not found." }, 404);
    if (order.userId !== userId) {
      return json({ error: "You cannot pay for this order." }, 403);
    }
    if (order.status !== "pending") {
      return json({ error: "This order is no longer awaiting payment." }, 409);
    }
    if (!Number.isFinite(order.total) || order.total <= 0) {
      return json({ error: "Order amount is invalid." }, 400);
    }

    const secretKey = Deno.env.get("XENDIT_SECRET_KEY")?.trim();
    if (!secretKey) {
      console.error("Missing XENDIT_SECRET_KEY Supabase secret.");
      return json({ error: "Payment service is not configured." }, 500);
    }

    const xenditResponse = await fetch("https://api.xendit.co/v2/invoices", {
      method: "POST",
      headers: {
        Authorization: `Basic ${btoa(`${secretKey}:`)}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        external_id: `${order.id}_${crypto.randomUUID()}`,
        amount: order.total,
        currency: "PHP",
        description: `Shop order ${order.id}`,
        invoice_duration: 86400,
      }),
    });

    const invoice = await xenditResponse.json().catch(() => null);
    if (!xenditResponse.ok) {
      console.error("Xendit invoice creation failed:", xenditResponse.status);
      if (xenditResponse.status === 401 || xenditResponse.status === 403) {
        return json({
          error:
            "Xendit rejected the API key. Check XENDIT_SECRET_KEY and ensure its Test or Live mode matches the Xendit account.",
        }, 502);
      }
      return json({
        error: `Xendit could not create the invoice (HTTP ${xenditResponse.status}).`,
      }, 502);
    }

    if (typeof invoice?.invoice_url !== "string") {
      console.error("Xendit response did not contain an invoice URL.");
      return json({ error: "Xendit returned an invalid invoice response." }, 502);
    }

    return json({ invoiceUrl: invoice.invoice_url });
  } catch (error) {
    console.error("Could not create Xendit invoice:", error);
    return json({ error: "Could not create the payment invoice." }, 500);
  }
});