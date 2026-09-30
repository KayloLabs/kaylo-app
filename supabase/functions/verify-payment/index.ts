// POST { razorpay_order_id, razorpay_payment_id, razorpay_signature }
//
// Confirms the payment Checkout reported: the signature must match our
// key secret, and Razorpay must show the payment as captured (or
// authorized, which is then captured) for the right amount. Only then
// is the payment marked paid, the booking confirmed, and the invoice
// sent. The caller must own the booking.
import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { callerClient, serviceClient } from "../_shared/clients.ts";
import {
  capturePayment,
  fetchPayment,
  razorpayConfigured,
  signatureMatches,
} from "../_shared/razorpay.ts";
import {
  invoiceEmailConfigured,
  sendInvoiceEmail,
} from "../_shared/invoice.ts";
import { formatSchedule } from "../_shared/mail.ts";

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

  let body: {
    razorpay_order_id?: string;
    razorpay_payment_id?: string;
    razorpay_signature?: string;
  };
  try {
    body = await request.json();
  } catch {
    return fail(400, "bad-request", "Send JSON with the Checkout result");
  }
  const orderId = body.razorpay_order_id?.trim();
  const paymentId = body.razorpay_payment_id?.trim();
  const signature = body.razorpay_signature?.trim();
  if (!orderId || !paymentId || !signature) {
    return fail(
      400,
      "bad-request",
      "order id, payment id and signature are required",
    );
  }

  const service = serviceClient();
  const { data: payment } = await service
    .from("payments")
    .select(
      "payment_id, booking_id, amount, payment_status, invoice_number, customer_email",
    )
    .eq("order_id", orderId)
    .maybeSingle();
  if (!payment) {
    return fail(404, "not-found", "No payment was started for this order");
  }

  // Ownership: the booking must be readable with the caller's token.
  const { data: bookingRow, error: bookingError } = await caller
    .from("bookings")
    .select(
      "booking_id, booking_date, booking_time, notes, estimated_cost, status, " +
        "services(service_name), customers(persons(full_name, email, phone_number))",
    )
    .eq("booking_id", payment.booking_id)
    .maybeSingle();
  if (bookingError) return fail(401, "unauthenticated", bookingError.message);
  const booking = bookingRow as BookingRow | null;
  if (!booking) return fail(403, "forbidden", "This booking is not yours");

  if (payment.payment_status === "success") {
    // Checkout reported twice, or the app retried: nothing to redo.
    return json({
      ok: true,
      booking_id: booking.booking_id,
      invoice_number: payment.invoice_number,
      invoice_sent: false,
      already: true,
    });
  }

  if (!(await signatureMatches(orderId, paymentId, signature))) {
    await service.from("payments").update({ payment_status: "failed" }).eq(
      "payment_id",
      payment.payment_id,
    );
    return fail(400, "bad-signature", "The payment could not be verified");
  }

  const amountPaise = Math.round(Number(payment.amount) * 100);
  let rzp = await fetchPayment(paymentId);
  if (rzp.order_id !== orderId || rzp.amount !== amountPaise) {
    return fail(400, "mismatch", "The payment does not match this order");
  }
  if (rzp.status === "authorized") {
    rzp = await capturePayment(paymentId, amountPaise);
  }
  if (rzp.status !== "captured") {
    return fail(
      402,
      "not-captured",
      `Razorpay reports the payment as ${rzp.status}`,
    );
  }

  const { data: invoiceNumber } = await service.rpc("next_invoice_number");
  const paidAt = new Date();
  await service.from("payments").update({
    payment_status: "success",
    transaction_id: paymentId,
    paid_at: paidAt.toISOString(),
    invoice_number: invoiceNumber,
    payment_method: rzp.method ? `razorpay:${rzp.method}` : "razorpay",
  }).eq("payment_id", payment.payment_id);
  // The booking's status trigger sends the "Booking confirmed" notification.
  await service.from("bookings").update({ status: "confirmed" }).eq(
    "booking_id",
    booking.booking_id,
  );

  const person = booking.customers?.persons;
  const email = payment.customer_email ?? rzp.email ?? person?.email ?? "";
  let invoiceSent = false;
  let invoiceNote = invoiceEmailConfigured
    ? (email ? "" : "no-email")
    : "email-not-configured";
  if (invoiceEmailConfigured && email) {
    try {
      invoiceSent = await sendInvoiceEmail({
        invoiceNumber: invoiceNumber as string,
        issuedAt: paidAt,
        customerName: person?.full_name ?? "Customer",
        customerEmail: email,
        customerPhone: person?.phone_number ?? undefined,
        serviceName: booking.services?.service_name ?? "Kaylo service",
        scheduledOn: formatSchedule(booking.booking_date, booking.booking_time),
        address: booking.notes ?? undefined,
        amountRupees: Number(payment.amount),
        paymentId,
        paymentMethod: rzp.method,
        bookingId: booking.booking_id,
      });
      if (invoiceSent) {
        await service.from("payments").update({
          invoice_sent_at: new Date().toISOString(),
          customer_email: email,
        }).eq("payment_id", payment.payment_id);
      }
    } catch (e) {
      invoiceNote = `email-failed: ${(e as Error).message}`;
    }
  }

  return json({
    ok: true,
    booking_id: booking.booking_id,
    invoice_number: invoiceNumber,
    invoice_sent: invoiceSent,
    invoice_note: invoiceNote || undefined,
  });
});

interface BookingRow {
  booking_id: string;
  booking_date: string;
  booking_time: string;
  notes: string | null;
  estimated_cost: number | null;
  status: string;
  services: { service_name?: string } | null;
  customers: {
    persons:
      | { full_name?: string; email?: string; phone_number?: string }
      | null;
  } | null;
}
