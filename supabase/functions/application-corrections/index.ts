import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import { verifyCorrectionToken } from "../_shared/application_correction_token.ts";
import {
  documentMime,
  partnerDocumentTypes,
} from "../_shared/partner_security.ts";
import { deliverApplicationNotifications } from "../_shared/partner_delivery.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST_ONLY");
  try {
    const multipart = (request.headers.get("content-type") ?? "").toLowerCase()
      .startsWith("multipart/form-data");
    const limit = multipart ? 11 * 1024 * 1024 : 8192;
    if (Number(request.headers.get("content-length") ?? 0) > limit) {
      return fail(413, "too-large", "FILE_TOO_LARGE");
    }
    const reader = request.body?.getReader();
    if (!reader) return fail(400, "invalid", "INVALID_REQUEST");
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const part = await reader.read();
      if (part.done) break;
      length += part.value.length;
      if (length > limit) {
        await reader.cancel();
        return fail(413, "too-large", "FILE_TOO_LARGE");
      }
      chunks.push(part.value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.length;
    }
    let token = "", docType = "", file: FormDataEntryValue | null = null;
    if (multipart) {
      const form = await new Response(bytes, {
        headers: { "content-type": request.headers.get("content-type")! },
      }).formData();
      token = String(form.get("token") ?? "");
      docType = String(form.get("doc_type") ?? "");
      file = form.get("file");
    } else {
      const body = JSON.parse(new TextDecoder().decode(bytes));
      if (body?.action !== "info") {
        return fail(400, "invalid", "INVALID_ACTION");
      }
      token = String(body.token ?? "");
    }
    let capability;
    try {
      capability = await verifyCorrectionToken(token);
    } catch {
      return fail(403, "invalid-link", "CORRECTION_LINK_INVALID_OR_EXPIRED");
    }
    const db = serviceClient();
    const { data: application, error } = await db.rpc(
      "get_application_for_correction",
      {
        p_application_id: capability.applicationId,
        p_version: capability.version,
      },
    );
    if (error || !application) {
      return fail(403, "invalid-link", "CORRECTION_LINK_INVALID_OR_EXPIRED");
    }
    if (!multipart) return json({ ok: true, application });
    const requested = (application.requested_documents ?? []).some((
      doc: { doc_type: string },
    ) => doc.doc_type === docType);
    if (
      !requested || !partnerDocumentTypes.has(docType) ||
      !(file instanceof File)
    ) return fail(400, "invalid-document", "DOCUMENT_NOT_REQUESTED");
    if (file.size === 0 || file.size > 10 * 1024 * 1024) {
      return fail(413, "too-large", "FILE_TOO_LARGE");
    }
    const content = new Uint8Array(await file.arrayBuffer()),
      mime = documentMime(content);
    if (
      !mime || mime !== file.type ||
      (["photo", "selfie"].includes(docType) && mime === "application/pdf")
    ) return fail(400, "invalid-document", "INVALID_FILE_TYPE");
    const ext = mime === "image/jpeg"
      ? "jpg"
      : mime === "image/png"
      ? "png"
      : "pdf";
    const path =
      `applications/${capability.applicationId}/corrections/${capability.version}/${docType}/${crypto.randomUUID()}.${ext}`;
    const { error: uploadError } = await db.storage.from("worker-documents")
      .upload(path, content, { contentType: mime, upsert: false });
    if (uploadError) return fail(503, "upload-failed", "UPLOAD_FAILED_RETRY");
    const { data: updated, error: recordError } = await db.rpc(
      "record_application_correction",
      {
        p_application_id: capability.applicationId,
        p_version: capability.version,
        p_doc_type: docType,
        p_path: path,
        p_content_type: mime,
        p_byte_size: file.size,
      },
    );
    if (recordError) {
      await db.storage.from("worker-documents").remove([path]);
      return fail(409, "correction-changed", "CORRECTION_CHANGED_REFRESH");
    }
    // Upload and the new review state are durable even when email is unavailable.
    if (updated?.completed) {
      await deliverApplicationNotifications(db, capability.applicationId, "")
        .catch(() => undefined);
    }
    return json({ ok: true, application: updated });
  } catch {
    return fail(400, "invalid", "INVALID_REQUEST");
  }
});
