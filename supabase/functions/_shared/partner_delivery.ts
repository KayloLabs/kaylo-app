import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  emailShell,
  escapeHtml,
  type MailAttachment,
  mailConfigured,
  sendMail,
} from "./mail.ts";
import { generatePartnerCertificate } from "./partner_certificate.ts";
import { deliverPartnerCredentials } from "./partner_credentials_delivery.ts";
import {
  correctionLink,
  signCorrectionToken,
  uuidPattern,
} from "./application_correction_token.ts";

export interface ApplicationMail {
  mail_id: string;
  claim_id: string;
  application_id: string;
  application_version: number;
  kind: "submitted" | "approved" | "rejected" | "changes_requested";
  recipient_email: string;
  template_data: Record<string, unknown>;
}
export interface ReviewCertificate {
  certificate_id: string;
  certificate_number: string;
  issued_at: string;
  snapshot: {
    partner_id: string;
    full_name: string;
    profession: string;
    district: string;
    approved_at: string;
    checked_document_types: string[];
  };
  checked_document_types: string[];
}
export async function certificateAttachment(
  db: SupabaseClient,
  certificate: ReviewCertificate,
): Promise<MailAttachment> {
  if (!uuidPattern.test(certificate.certificate_id)) {
    throw new Error("CERTIFICATE_UNAVAILABLE");
  }
  const path = `certificates/${certificate.certificate_id}.pdf`;
  const bucket = db.storage.from("worker-documents");
  const { data: existing } = await bucket.download(path);
  if (existing) {
    return {
      filename: `Kaylo-${certificate.certificate_number}.pdf`,
      contentType: "application/pdf",
      bytes: new Uint8Array(await existing.arrayBuffer()),
    };
  }
  const snapshot = certificate.snapshot;
  const bytes = await generatePartnerCertificate({
    certificateId: certificate.certificate_id,
    partnerId: snapshot.partner_id,
    fullName: snapshot.full_name,
    profession: snapshot.profession,
    district: snapshot.district,
    issuedAt: certificate.issued_at,
    verificationReference: certificate.certificate_number,
    approvedDocumentTypes: certificate.checked_document_types ??
      snapshot.checked_document_types,
  });
  const { error } = await bucket.upload(path, bytes, {
    contentType: "application/pdf",
    upsert: false,
  });
  if (error) {
    // Another delivery may have stored this immutable certificate concurrently.
    const { data: stored, error: readError } = await bucket.download(path);
    if (readError || !stored) throw new Error("CERTIFICATE_STORAGE_FAILED");
    return {
      filename: `Kaylo-${certificate.certificate_number}.pdf`,
      contentType: "application/pdf",
      bytes: new Uint8Array(await stored.arrayBuffer()),
    };
  }
  return {
    filename: `Kaylo-${certificate.certificate_number}.pdf`,
    contentType: "application/pdf",
    bytes,
  };
}

/** Injectable delivery coordinator: failed SMTP/ack never reports success. */
export async function dispatchClaimedMail(mail: ApplicationMail, deps: {
  send: (mail: ApplicationMail) => Promise<void>;
  finish: (sent: boolean, error?: string) => Promise<boolean>;
}): Promise<boolean> {
  try {
    await deps.send(mail);
    if (!await deps.finish(true)) {
      throw new Error("DELIVERY_ACKNOWLEDGEMENT_FAILED");
    }
    return true;
  } catch {
    await deps.finish(false, "DELIVERY_FAILED").catch(() => false);
    return false;
  }
}

/** An outbox retry after credential issuance sends only a certificate. */
export async function deliverApproval(deps: {
  issue: () => Promise<{ already_issued: boolean; partner_id: string }>;
  sendCertificate: (partnerId: string) => Promise<void>;
}): Promise<void> {
  const result = await deps.issue();
  if (result.already_issued) await deps.sendCertificate(result.partner_id);
}

async function sendApplicationMail(
  db: SupabaseClient,
  mail: ApplicationMail,
  actorUid: string,
): Promise<void> {
  if (!mailConfigured) throw new Error("MAIL_NOT_CONFIGURED");
  const data = mail.template_data;
  const reference = String(data.reference ?? "");
  if (!/^KA-[A-F0-9]{24}$/.test(reference)) {
    throw new Error("INVALID_APPLICATION_REFERENCE");
  }
  if (mail.kind === "approved") {
    const { data: detail, error } = await db.rpc("admin_application_detail", {
      p_actor_uid: actorUid,
      p_application_id: mail.application_id,
    });
    if (error || !detail?.certificate || !detail?.application?.worker_id) {
      throw new Error("APPROVAL_DETAILS_UNAVAILABLE");
    }
    const certificate = await certificateAttachment(db, detail.certificate);
    await deliverApproval({
      issue: () =>
        deliverPartnerCredentials(db, detail.application.worker_id, {
          certificate,
          reset: false,
        }),
      sendCertificate: async (partnerId) => {
        // A certificate/outbox retry must never reset an existing worker password.
        await sendMail({
          to: mail.recipient_email,
          subject: "Your Kaylo Partner review certificate",
          text:
            `Your application ${reference} was approved. Your Kaylo Partner ID is ${partnerId}. Your review certificate is attached. Continue using your existing sign-in password. Help: kayloapp@gmail.com`,
          html: emailShell(
            "Your Kaylo Partner certificate",
            `<tr><td style="padding:24px 32px"><p>Your application <strong>${
              escapeHtml(reference)
            }</strong> was approved.</p><p>Partner ID: <strong>${
              escapeHtml(partnerId)
            }</strong>. Your review certificate is attached. Continue using your existing sign-in password.</p><p>Help: kayloapp@gmail.com</p></td></tr>`,
          ),
          attachments: [certificate],
        });
      },
    });
    return;
  }
  let subject: string, text: string, title: string;
  let link = "";
  const note = String(data.note ?? "");
  if (mail.kind === "changes_requested") {
    const version = Number(
      data.correction_version ?? data.version ?? mail.application_version,
    );
    link = correctionLink(
      await signCorrectionToken(
        { applicationId: mail.application_id, version },
        String(data.expires_at ?? ""),
      ),
    );
    subject = "Please update your Kaylo Partner application";
    title = "A few details need updating";
    const documents = Array.isArray(data.requested_documents)
      ? data.requested_documents.map((item) =>
        typeof item === "string"
          ? item
          : String((item as Record<string, unknown>).doc_type ?? "")
      ).join(", ")
      : "the requested documents";
    text =
      `Application: ${reference}\nKaylo has requested updates to: ${documents}.\n${note}\nOpen your secure link to replace only the requested documents. The link expires in seven days from the request.\n${link}\nFor help: kayloapp@gmail.com`;
  } else if (mail.kind === "rejected") {
    subject = "An update on your Kaylo Partner application";
    title = "Your application update";
    text =
      `Application: ${reference}\nAfter review, Kaylo could not approve this application.\n${note}\nFor questions, contact kayloapp@gmail.com with your reference.`;
  } else {
    subject = `Kaylo Partner application ready for review: ${reference}`;
    title = "New partner application";
    text =
      `A completed Kaylo Partner application is ready for review.\nReference: ${reference}\nOpen the Kaylo admin portal to review the details and private documents.`;
    const portal = Deno.env.get("KAYLO_PORTAL_URL");
    if (portal) {
      const url = new URL(portal);
      if (url.protocol === "https:" && !url.username && !url.password) {
        link = new URL("/admin/", url.origin).toString();
      }
    }
  }
  const html = emailShell(
    title,
    `<tr><td style="padding:24px 32px;line-height:1.6"><p>${
      escapeHtml(text.split("\n").filter((line) => line !== link).join("\n"))
        .replace(/\n/g, "<br>")
    }</p>${
      link
        ? `<p><a href="${escapeHtml(link)}" style="color:#2F7A4F">${
          mail.kind === "changes_requested"
            ? "Update requested documents"
            : "Review application"
        }</a></p>`
        : ""
    }</td></tr>`,
  );
  await sendMail({
    to: mail.recipient_email,
    subject,
    text: link && mail.kind === "submitted" ? `${text}\n${link}` : text,
    html,
  });
}

export async function deliverApplicationNotifications(
  db: SupabaseClient,
  applicationId: string,
  actorUid: string,
): Promise<{ state: "sent" | "pending"; sent: number; pending: number }> {
  let query = db.from("application_mail_outbox").select(
    "mail_id,status,last_error",
  ).eq("application_id", applicationId).in("status", [
    "pending",
    "failed",
    "sending",
  ]);
  // A public document upload can nudge the admin notice only. It cannot claim
  // an approval delivery racing with a review, which requires the admin actor.
  if (!actorUid) query = query.eq("kind", "submitted");
  const { data: rows, error } = await query.order("created_at", {
    ascending: false,
  }).limit(5);
  if (error) return { state: "pending", sent: 0, pending: 1 };
  let sent = 0, pending = 0;
  for (const row of rows ?? []) {
    if (row.last_error === "SUPERSEDED") continue;
    const { data: current, error: currentError } = await db.rpc(
      "application_mail_is_current",
      { p_mail_id: row.mail_id },
    );
    if (currentError) {
      pending++;
      continue;
    }
    if (current !== true) continue;
    const { data: mail, error: claimError } = await db.rpc(
      "claim_application_mail",
      { p_mail_id: row.mail_id },
    );
    if (claimError) {
      pending++;
      continue;
    }
    if (!mail) {
      const { data: latest } = await db.from("application_mail_outbox")
        .select("status,last_error").eq("mail_id", row.mail_id).maybeSingle();
      if (latest?.status !== "sent" && latest?.last_error !== "SUPERSEDED") {
        pending++;
      }
      continue;
    }
    const ok = await dispatchClaimedMail(mail as ApplicationMail, {
      send: (message) => sendApplicationMail(db, message, actorUid),
      finish: async (wasSent, reason) => {
        const { data, error } = await db.rpc("finish_application_mail", {
          p_mail_id: mail.mail_id,
          p_claim_id: mail.claim_id,
          p_sent: wasSent,
          p_error: reason ?? null,
        });
        return !error && data === true;
      },
    });
    if (ok) sent++;
    else pending++;
  }
  return { state: pending ? "pending" : "sent", sent, pending };
}
