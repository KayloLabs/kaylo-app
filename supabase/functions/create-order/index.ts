// POST { booking_id, email? }  ->  what Razorpay Checkout needs.
//
// The amount comes from the booking row, never from the app, and the
// booking is read with the caller's own token, so a customer can only
// start payment for a booking that is theirs.
import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { callerClient, serviceClient } from "../_shared/clients.ts";
import {
  createOrder,
  razorpayConfigured,
  razorpayKeyId,
} from "../_shared/razorpay.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST only");
  if (!razorpayConfigured) {
    return fail(503, "not-configured", "Razorpay keys are not set");
  }

  const caller = callerClient(request);
  if (!caller) return fail(401, "unauthenticated", "Sign in first");

  let body: { booking_id?: string; email?: string };
  try {
    body = await request.json();
  } catch {
    return fail(400, "bad-request", "Send JSON with booking_id");
  }
  const bookingId = body.booking_id?.trim();
  if (!bookingId) return fail(400, "bad-request", "booking_id is required");

  // Ownership and amount in one read: row-level security returns the
  // booking only to its customer (or worker).
  const { data: booking, error: bookingError } = await caller
    .from("bookings")
    .select("booking_id, estimated_cost, status, services(service_name)")
    .eq("booking_id", bookingId)
    .maybeSingle();
  if (bookingError) return fail(401, "unauthenticated", bookingError.message);
  if (!booking) return fail(404, "not-found", "Booking not found");
  if (booking.status === "cancelled") {
    return fail(409, "cancelled", "This booking is cancelled");
  }

  const rupees = Number(booking.estimated_cost ?? 0);
  const amountPaise = Math.round(rupees * 100);
  if (amountPaise < 100) {
    return fail(400, "amount", "Nothing to pay for this booking");
  }

  const service = serviceClient();
  const { data: paid } = await service
    .from("payments")
    .select("payment_id")
    .eq("booking_id", bookingId)
    .eq("payment_status", "success")
    .limit(1);
  if (paid && paid.length > 0) {
    return fail(409, "already-paid", "This booking is already paid");
  }

  // Who is paying, for Checkout's prefill and for the invoice.
  const { data: person } = await caller
    .from("persons")
    .select("person_id, full_name, phone_number, email")
    .eq("person_id", await personIdOf(caller))
    .maybeSingle();
  const email = (body.email ?? person?.email ?? "").trim().toLowerCase();
  if (email && person && !person.email) {
    // Phone sign-ups have no address on file; keep the one typed here.
    await service.from("persons").update({ email }).eq(
      "person_id",
      person.person_id,
    );
  }

  const serviceName =
    (booking.services as { service_name?: string } | null)?.service_name ??
      "Kaylo service";
  const order = await createOrder({
    amountPaise,
    receipt: bookingId,
    notes: { booking_id: bookingId, service: serviceName },
  });

  const { error: insertError } = await service.from("payments").insert({
    booking_id: bookingId,
    amount: rupees,
    payment_method: "razorpay",
    payment_status: "pending",
    order_id: order.id,
    customer_email: email || null,
  });
  if (insertError) return fail(500, "db", insertError.message);

  return json({
    key_id: razorpayKeyId,
    order_id: order.id,
    amount: amountPaise,
    currency: "INR",
    name: "Kaylo",
    description: serviceName,
    prefill: {
      name: person?.full_name ?? "",
      contact: person?.phone_number ?? "",
      email,
    },
    booking_id: bookingId,
  });
});

/// The caller's person id, resolved by the database from their token.
async function personIdOf(
  caller: ReturnType<typeof callerClient>,
): Promise<string> {
  const { data } = await caller!.rpc("current_person_id");
  return (data as string | null) ?? "";
}
