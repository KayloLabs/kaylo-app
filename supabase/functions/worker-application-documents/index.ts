import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import {
  documentMime,
  partnerDocumentTypes,
  sha256,
} from "../_shared/partner_security.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST_ONLY");
  if (Number(request.headers.get("content-length") ?? 0) > 11 * 1024 * 1024) {
    return fail(413, "file-too-large", "FILE_TOO_LARGE");
  }
  try {
    // Bound streamed requests too; Content-Length is optional and untrusted.
    const reader = request.body?.getReader();
    if (!reader) return fail(400, "invalid-document", "INVALID_DOCUMENT");
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const part = await reader.read();
      if (part.done) break;
      length += part.value.length;
      if (length > 11 * 1024 * 1024) {
        await reader.cancel();
        return fail(413, "file-too-large", "FILE_TOO_LARGE");
      }
      chunks.push(part.value);
    }
    const payload = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      payload.set(chunk, offset);
      offset += chunk.length;
    }
    const form = await new Response(payload, {
      headers: { "content-type": request.headers.get("content-type") ?? "" },
    }).formData();
    const appId = String(form.get("application_id") ?? ""),
      token = String(form.get("upload_token") ?? ""),
      type = String(form.get("doc_type") ?? "");
    const file = form.get("file");
    if (
      !/^[0-9a-f-]{36}$/i.test(appId) || !/^[0-9a-f]{64}$/.test(token) ||
      !partnerDocumentTypes.has(type) || !(file instanceof File)
    ) return fail(400, "invalid-document", "INVALID_DOCUMENT");
    if (file.size === 0 || file.size > 10 * 1024 * 1024) {
      return fail(413, "file-too-large", "FILE_TOO_LARGE");
    }
    const db = serviceClient();
    const { data: a, error } = await db.from("worker_applications").select(
      "status,upload_token_hash,upload_expires_at",
    ).eq("application_id", appId).maybeSingle();
    if (
      error || !a || !["submitted", "under_review"].includes(a.status) ||
      new Date(a.upload_expires_at).getTime() < Date.now() ||
      await sha256(token) !== a.upload_token_hash
    ) return fail(403, "upload-not-allowed", "UPLOAD_NOT_ALLOWED");
    const bytes = new Uint8Array(await file.arrayBuffer()),
      mime = documentMime(bytes);
    if (
      !mime || mime !== file.type ||
      ((type === "photo" || type === "selfie") && mime === "application/pdf")
    ) return fail(400, "invalid-file-type", "INVALID_FILE_TYPE");
    const ext = mime === "image/jpeg"
      ? "jpg"
      : mime === "image/png"
      ? "png"
      : "pdf";
    const path = `applications/${appId}/${type}/${crypto.randomUUID()}.${ext}`;
    const { error: uploadError } = await db.storage.from("worker-documents")
      .upload(path, bytes, { contentType: mime, upsert: false });
    if (uploadError) return fail(503, "upload-failed", "UPLOAD_FAILED");
    const { error: recordError } = await db.rpc(
      "record_worker_application_document",
      {
        p_application_id: appId,
        p_token: token,
        p_doc_type: type,
        p_path: path,
        p_content_type: mime,
        p_byte_size: file.size,
      },
    );
    if (recordError) {
      await db.storage.from("worker-documents").remove([path]);
      return fail(409, "upload-not-allowed", "UPLOAD_NOT_ALLOWED");
    }
    return json({ ok: true, doc_type: type });
  } catch {
    return fail(400, "invalid-document", "INVALID_DOCUMENT");
  }
});
