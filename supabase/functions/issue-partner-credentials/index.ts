import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import {
  firebaseAdminConfigured,
  issueFirebasePartnerPassword,
} from "../_shared/firebase_admin.ts";
import {
  emailShell,
  escapeHtml,
  mailConfigured,
  sendMail,
} from "../_shared/mail.ts";
import {
  secretMatches,
  temporaryPassword,
} from "../_shared/partner_security.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        ...corsHeaders,
        "Access-Control-Allow-Headers": `${
          corsHeaders["Access-Control-Allow-Headers"]
        }, x-kaylo-admin-secret`,
      },
    });
  }
  if (request.method !== "POST") return fail(405, "method", "POST_ONLY");
  // An admin secret, never shipped in either app or accepted as a Firebase token.
  if (
    !await secretMatches(
      request.headers.get("x-kaylo-admin-secret") ?? "",
      Deno.env.get("KAYLO_PARTNER_ADMIN_SECRET") ?? "",
    )
  ) return fail(403, "forbidden", "ADMIN_ONLY");
  if (!firebaseAdminConfigured || !mailConfigured) {
    return fail(503, "not-configured", "CREDENTIAL_DELIVERY_NOT_CONFIGURED");
  }
  const db = serviceClient();
  let workerId = "", issuanceId = "";
  try {
    const body = await request.json();
    workerId = String(body.worker_id ?? "");
    if (
      !/^[0-9a-f-]{36}$/i.test(workerId) ||
      !["issue", "reset"].includes(body.action)
    ) return fail(400, "bad-request", "INVALID_REQUEST");
    const { data: issue, error } = await db.rpc(
      "begin_partner_credential_issue",
      { p_worker_id: workerId, p_reset: body.action === "reset" },
    );
    if (error) return fail(409, "issuance-blocked", "ISSUANCE_BLOCKED");
    if (issue.already_issued) {
      return json({
        ok: true,
        already_issued: true,
        partner_id: issue.partner_id,
      });
    }
    issuanceId = issue.issuance_id;
    const password = temporaryPassword();
    const baseline = await issueFirebasePartnerPassword(
      issue.firebase_uid,
      issue.partner_id,
      password,
      issue.name,
      issuanceId,
    );
    const { error: linkError } = await db.rpc(
      "finish_partner_credential_issue",
      {
        p_worker_id: workerId,
        p_issuance_id: issuanceId,
        p_password_updated_at_ms: baseline,
      },
    );
    if (linkError) throw new Error("LINK_FAILED");
    await sendMail({
      to: issue.email,
      subject: "Your Kaylo Partner sign-in",
      text:
        `Your Kaylo Partner ID: ${issue.partner_id}\nTemporary password: ${password}\nSign in to Kaylo Partner and choose a new password before using your account. Never share these credentials. For help: kayloapp@gmail.com`,
      html: emailShell(
        "Your Kaylo Partner account",
        `<tr><td style="padding:24px 32px">Partner ID: <strong>${
          escapeHtml(issue.partner_id)
        }</strong><br>Temporary password: <strong>${
          escapeHtml(password)
        }</strong><p>Sign in to Kaylo Partner and choose a new password before using your account. Never share these credentials.</p><p>Help: kayloapp@gmail.com</p></td></tr>`,
      ),
    });
    let smsSent = false;
    // Optional Twilio adapter; email delivery is the required default route.
    const sid = Deno.env.get("TWILIO_ACCOUNT_SID"),
      auth = Deno.env.get("TWILIO_AUTH_TOKEN"),
      from = Deno.env.get("TWILIO_FROM_NUMBER");
    if (sid && auth && from) {
      try {
        const res = await fetch(
          `https://api.twilio.com/2010-04-01/Accounts/${
            encodeURIComponent(sid)
          }/Messages.json`,
          {
            method: "POST",
            headers: {
              Authorization: `Basic ${btoa(`${sid}:${auth}`)}`,
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: new URLSearchParams({
              To: issue.phone,
              From: from,
              Body:
                `Kaylo Partner: ${issue.partner_id}. Temporary password: ${password}. Change it on first sign-in. Never share it.`,
            }),
          },
        );
        smsSent = res.ok;
      } catch { /* Email remains the successful delivery channel. */ }
    }
    const { data: delivered, error: deliveredError } = await db.from(
      "partner_credentials",
    ).update({
      state: "delivered",
      delivered_at: new Date().toISOString(),
      lock_expires_at: null,
    }).eq("worker_id", workerId).eq("issuance_id", issuanceId).eq(
      "state",
      "ready",
    ).select("worker_id").maybeSingle();
    if (deliveredError || !delivered) {
      return fail(503, "delivery-record-failed", "DELIVERY_RECORD_FAILED");
    }
    return json({
      ok: true,
      partner_id: issue.partner_id,
      delivery: { email: true, sms: smsSent },
    });
  } catch {
    if (workerId && issuanceId) {
      await db.from("partner_credentials").update({
        state: "failed",
        lock_expires_at: null,
      }).eq("worker_id", workerId).eq("issuance_id", issuanceId);
    }
    return fail(503, "issuance-failed", "ISSUANCE_FAILED_RETRY_ADMIN");
  }
});
