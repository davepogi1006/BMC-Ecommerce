// Called by XENDIT (not the app) when an invoice is paid or expires.
import { getOrder, markOrder } from "../_shared/firebase.ts";

const CALLBACK_TOKEN = Deno.env.get("XENDIT_CALLBACK_TOKEN")!;

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("Use POST", { status: 405 });

  // Only Xendit knows this token. Anyone else is rejected.
  if (req.headers.get("x-callback-token") !== CALLBACK_TOKEN) {
    return new Response("Forbidden", { status: 403 });
  }

  try {
    const body = await req.json();
    const status = String(body.status ?? "").toUpperCase();
    const orderId = String(body.external_id ?? "").split("_")[0];

    const order = await getOrder(orderId);
    if (!order) return new Response("ok"); // unknown id (e.g. Xendit's test ping)
    if (order.status === "paid") return new Response("ok"); // already handled

    if (status === "PAID" || status === "SETTLED") {
      // Safety check: the amount paid must match the order.
      if (Math.abs(Number(body.amount ?? 0) - order.total) > 0.01) {
        console.error("Amount mismatch for order", order.id);
        return new Response("ok");
      }
      await markOrder(order, "paid");
    } else if (status === "EXPIRED" && order.status === "pending") {
      await markOrder(order, "failed");
    }

    return new Response("ok");
  } catch (e) {
    console.error(e);
    return new Response("error", { status: 500 }); // Xendit will retry
  }
});
