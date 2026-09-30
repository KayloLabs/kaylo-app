// POST { booking_id, email? }  ->  the "Booking received" email for a
// booking paid after the service (paid bookings get the invoice from
// verify-payment instead). The booking is read with the caller's own
// token, so only its customer can trigger it. The email goes to the
// address given, else the one on the profile; a given address is saved
// to the profile when it had none.
import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { callerClient, serviceClient } from "../_shared/clients.ts";
import {
  brand,
  detailRow,
  emailShell,
  formatRupees,
  formatSchedule,
  mailConfigured,
  sendMail,
} from "../_shared/mail.ts";

interface BookingRow {
  booking_id: string;
  booking_date: string;
  booking_time: string;
  notes: string | null;
  estimated_cost: number | null;
  status: string;
  services: { service_name?: string } | null;
  customers: {
    persons: { person_id?: string; full_name?: string; email?: string } | null;
  } | null;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST only");
  if (!mailConfigured) {
    return fail(503, "not-configured", "Email sending is not set up");
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

  const { data, error } = await caller
    .from("bookings")
    .select(
      "booking_id, booking_date, booking_time, notes, estimated_cost, status, " +
        "services(service_name), customers(persons(person_id, full_name, email))",
    )
    .eq("booking_id", bookingId)
    .maybeSingle();
  if (error) return fail(401, "unauthenticated", error.message);
  const booking = data as BookingRow | null;
  if (!booking) return fail(404, "not-found", "Booking not found");

  const person = booking.customers?.persons;
  const given = (body.email ?? "").trim().toLowerCase();
  const email = given || person?.email || "";
  if (!email) return fail(400, "no-email", "No email address to send to");
  if (given && person?.person_id && !person.email) {
    await serviceClient().from("persons").update({ email: given }).eq(
      "person_id",
      person.person_id,
    );
  }

  const serviceName = booking.services?.service_name ?? "Kaylo service";
  const when = formatSchedule(booking.booking_date, booking.booking_time);
  const amount = Number(booking.estimated_cost ?? 0);
  const name = person?.full_name ?? "there";
  const bodyHtml = `
      <tr><td style="padding:14px 32px 0;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
          ${detailRow("Service", serviceName, { strong: true })}
          ${detailRow("Scheduled for", when)}
          ${booking.notes ? detailRow("Address", booking.notes) : ""}
          ${detailRow("Estimated cost", formatRupees(amount))}
          ${detailRow("Payment", "After the service, to the professional")}
          ${
    detailRow("Booking reference", booking.booking_id.slice(0, 8).toUpperCase())
  }
        </table>
      </td></tr>
      <tr><td style="padding:22px 32px 30px;font-size:14px;color:${brand.muted};line-height:1.7;">
        We will confirm the professional shortly and keep you posted in the app.
        Need to change the date? Open the booking in the Kaylo app and choose Reschedule.
      </td></tr>`;

  await sendMail({
    to: email,
    subject: `Booking received: ${serviceName} on ${when}`,
    text:
      `Hi ${name}, your booking for ${serviceName} on ${when} is received. ` +
      `Estimated cost ${formatRupees(amount)}, payable after the service.`,
    html: emailShell("Booking received", bodyHtml, {
      subtitle: `Thank you, ${name}. Your booking is in and we are on it.`,
      watermark: true,
    }),
  });
  return json({ ok: true, sent_to: email });
});
