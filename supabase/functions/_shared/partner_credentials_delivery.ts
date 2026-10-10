import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  firebaseAdminConfigured,
  issueFirebasePartnerPassword,
} from "./firebase_admin.ts";
import {
  emailShell,
  escapeHtml,
  type MailAttachment,
  mailConfigured,
  sendMail,
} from "./mail.ts";
import { temporaryPassword } from "./partner_security.ts";

/** Service-only issuance, shared by the support endpoint and reviewed approval.
 * No password is returned to the browser or persisted in an outbox payload.
 */
export async function deliverPartnerCredentials(
  db: SupabaseClient,
  workerId: string,
  options: { reset?: boolean; certificate?: MailAttachment } = {},
): Promise<
  {
    already_issued: boolean;
    partner_id: string;
    delivery?: { email: boolean; sms: boolean };
  }
> {
  if (!firebaseAdminConfigured || !mailConfigured) {
    throw new Error("CREDENTIAL_DELIVERY_NOT_CONFIGURED");
  }
  let issuanceId = "";
  let mailAccepted = false;
  try {
    const { data: issue, error } = await db.rpc(
      "begin_partner_credential_issue",
      {
        p_worker_id: workerId,
        p_reset: options.reset ?? false,
      },
    );
    if (error || !issue) throw new Error("ISSUANCE_BLOCKED");
    if (issue.already_issued) {
      return { already_issued: true, partner_id: issue.partner_id };
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
        `Your Kaylo Partner ID: ${issue.partner_id}\nTemporary password: ${password}\nSign in to Kaylo Partner and choose a new password before using your account. Never share these credentials. ${
          options.certificate
            ? "Your Kaylo review certificate is attached. "
            : ""
        }For help: kayloapp@gmail.com`,
      html: emailShell(
        "Your Kaylo Partner account",
        `<tr><td style="padding:24px 32px">Partner ID: <strong>${
          escapeHtml(issue.partner_id)
        }</strong><br>Temporary password: <strong>${
          escapeHtml(password)
        }</strong><p>Sign in to Kaylo Partner and choose a new password before using your account. Never share these credentials.</p>${
          options.certificate
            ? "<p>Your Kaylo review certificate is attached.</p>"
            : ""
        }<p>Help: kayloapp@gmail.com</p></td></tr>`,
      ),
      attachments: options.certificate ? [options.certificate] : [],
    });
    mailAccepted = true;
    // Record delivery before optional SMS. A slow optional channel must not
    // leave a delivered password looking retryable.
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
    if (deliveredError || !delivered) throw new Error("DELIVERY_RECORD_FAILED");
    let smsSent = false;
    const sid = Deno.env.get("TWILIO_ACCOUNT_SID"),
      auth = Deno.env.get("TWILIO_AUTH_TOKEN"),
      from = Deno.env.get("TWILIO_FROM_NUMBER");
    if (sid && auth && from) {
      try {
        const response = await fetch(
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
            signal: AbortSignal.timeout(8000),
          },
        );
        smsSent = response.ok;
      } catch { /* Email is the required delivery channel. */ }
    }
    return {
      already_issued: false,
      partner_id: issue.partner_id,
      delivery: { email: true, sms: smsSent },
    };
  } catch (error) {
    // Never mark an accepted email failed: this could rotate a password the
    // worker has already received. An uncertain delivery acknowledgement is
    // left leased for explicit administrative recovery.
    if (issuanceId && !mailAccepted) {
      await db.from("partner_credentials").update({
        state: "failed",
        lock_expires_at: null,
      })
        .eq("worker_id", workerId).eq("issuance_id", issuanceId);
    }
    throw error;
  }
}
