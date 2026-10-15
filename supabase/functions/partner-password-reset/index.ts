import { serviceClient } from "../_shared/clients.ts";
import {
  firebaseAdminConfigured,
  generatePartnerPasswordResetLink,
} from "../_shared/firebase_admin.ts";
import {
  brand,
  emailShell,
  escapeHtml,
  mailConfigured,
  sendMail,
} from "../_shared/mail.ts";
import { passwordRecoveryHandler } from "../_shared/partner_password_recovery.ts";

Deno.serve(passwordRecoveryHandler({
  configured: firebaseAdminConfigured && mailConfigured,
  claim: async (id, email, clientHash) => {
    const { data, error } = await serviceClient().rpc(
      "claim_partner_password_reset",
      {
        p_partner_id: id,
        p_email: email,
        p_client_hash: clientHash,
      },
    );
    if (error || !data) throw new Error("RESET_LOOKUP_FAILED");
    return data;
  },
  generateLink: generatePartnerPasswordResetLink,
  send: async (identity, link) => {
    await sendMail({
      to: identity.email,
      subject: "Reset your Kaylo Partner password",
      text:
        `Reset the password for your Kaylo Partner ID ${identity.partner_id}:\n\n${link}\n\nThis link can be used once. If it expires, request a new link in Kaylo Partner. After resetting, return to the app and sign in with your Partner ID and new password. If you did not request this, ignore this email. Your password stays unchanged until you reset it. Never share this link.`,
      html: emailShell(
        "Reset your password",
        `<tr><td style="padding:24px 32px;color:${brand.ink};line-height:1.6">
        <p>We received a password reset request for <strong>${
          escapeHtml(identity.partner_id)
        }</strong>.</p>
        <p style="margin:28px 0"><a href="${
          escapeHtml(link)
        }" style="background:${brand.green};color:#fff;text-decoration:none;padding:14px 24px;border-radius:10px;display:inline-block">Reset password</a></p>
        <p>Choose a new password, then return to Kaylo Partner and sign in with your Partner ID.</p>
        <p>This link can be used once. If it expires, request a new link in the app. Never share it.</p>
        <p style="color:${brand.muted}">If you did not request this, ignore this email. Your password stays unchanged until you reset it.</p>
      </td></tr>`,
      ),
    });
  },
}));
