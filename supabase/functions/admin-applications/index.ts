import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import {
  firebaseProjectId,
  lookupFirebaseAccount,
} from "../_shared/firebase_admin.ts";
import {
  AdminAuthError,
  adminFirebaseSessionIsCurrent,
  assertAdminDecision,
  authenticateAdmin,
} from "../_shared/admin_auth.ts";
import { uuidPattern } from "../_shared/application_correction_token.ts";
import { partnerDocumentTypes } from "../_shared/partner_security.ts";
import {
  certificateAttachment,
  deliverApplicationNotifications,
} from "../_shared/partner_delivery.ts";
import { decodeJwt } from "npm:jose@5";
import { selectReviewedDocument } from "../_shared/admin_documents.ts";
import { readBoundedJson, RequestBodyError } from "../_shared/http_body.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST_ONLY");
  try {
    const db = serviceClient();
    const actor = await authenticateAdmin(request, {
      projectId: firebaseProjectId(),
      lookup: async (uid) => {
        const { data, error } = await db.from("admin_users").select(
          "firebase_uid,email,role,is_active",
        ).eq("firebase_uid", uid).maybeSingle();
        if (error) throw new Error("ADMIN_LOOKUP_UNAVAILABLE");
        return data;
      },
      checkSession: async (uid, token) => {
        const claims = decodeJwt(token);
        const account = await lookupFirebaseAccount(uid);
        return adminFirebaseSessionIsCurrent(claims, account);
      },
    });
    const body = await readBoundedJson(request, 16000) as Record<
      string,
      unknown
    >;
    if (!body || typeof body !== "object" || Array.isArray(body)) {
      return fail(400, "bad-request", "INVALID_REQUEST");
    }
    const action = body.action;
    if (action === "session") {
      return json({
        ok: true,
        admin: { email: actor.email, role: actor.role },
      });
    }
    if (action === "list") {
      const statuses = [
        "submitted",
        "under_review",
        "changes_requested",
        "approved",
        "rejected",
      ];
      const status =
        body.status == null || body.status === "" || body.status === "all"
          ? null
          : String(body.status);
      const page = Number(body.page ?? 1),
        pageSize = Number(body.page_size ?? 20),
        search = String(body.search ?? "").trim();
      if (
        (status && !statuses.includes(status)) || !Number.isInteger(page) ||
        page < 1 || page > 10000 || !Number.isInteger(pageSize) ||
        pageSize < 1 || pageSize > 100 || search.length > 100
      ) return fail(400, "bad-request", "INVALID_FILTER");
      const { data, error } = await db.rpc("admin_application_list", {
        p_actor_uid: actor.firebase_uid,
        p_status: status,
        p_page: page,
        p_page_size: pageSize,
        p_search: search || null,
      });
      if (error) throw error;
      return json({ ok: true, ...data });
    }
    const applicationId = String(body.application_id ?? "");
    if (!uuidPattern.test(applicationId)) {
      return fail(400, "bad-request", "INVALID_APPLICATION");
    }
    if (action === "detail" || action === "document") {
      const { data, error } = await db.rpc("admin_application_detail", {
        p_actor_uid: actor.firebase_uid,
        p_application_id: applicationId,
      });
      if (error) throw error;
      if (!data) return fail(404, "not-found", "APPLICATION_NOT_FOUND");
      if (action === "detail") return json({ ok: true, ...data });
      const docType = String(body.doc_type ?? "");
      if (!partnerDocumentTypes.has(docType)) {
        return fail(400, "bad-request", "INVALID_DOCUMENT_TYPE");
      }
      const historyId = body.history_id == null
        ? undefined
        : String(body.history_id);
      if (historyId !== undefined && !uuidPattern.test(historyId)) {
        return fail(400, "bad-request", "INVALID_DOCUMENT_HISTORY");
      }
      const document = selectReviewedDocument(
        data.documents ?? [],
        docType,
        historyId,
      );
      if (!document) return fail(404, "not-found", "DOCUMENT_NOT_FOUND");
      const { data: signed, error: signError } = await db.storage.from(
        "worker-documents",
      ).createSignedUrl(document.storage_path, 60);
      if (signError || !signed) throw new Error("DOCUMENT_UNAVAILABLE");
      const { error: auditError } = await db.from("worker_application_audit")
        .insert({
          application_id: applicationId,
          application_version: data.application.version,
          action: "document_viewed",
          actor_uid: actor.firebase_uid,
          actor_email: actor.email,
          actor_role: actor.role,
          data: { doc_type: docType, history_id: document.history_id },
        });
      if (auditError) throw new Error("DOCUMENT_AUDIT_UNAVAILABLE");
      return json({
        ok: true,
        url: signed.signedUrl,
        expires_in: 60,
        content_type: document.content_type,
        history_id: document.history_id,
      });
    }
    if (action === "review") {
      const decision = String(body.decision ?? "");
      assertAdminDecision(actor, decision);
      const version = Number(body.expected_version),
        note = String(body.note ?? "").trim();
      const types = decision === "approve"
        ? body.checked_documents
        : body.requested_documents;
      const documentTypes = Array.isArray(types) ? types : [];
      if (
        !Number.isInteger(version) || version < 1 || note.length > 2000 ||
        (decision !== "approve" && note.length < 5) ||
        documentTypes.some((type) =>
          typeof type !== "string" || !partnerDocumentTypes.has(type)
        ) || new Set(documentTypes).size !== documentTypes.length ||
        (decision === "approve" && documentTypes.length !== 5) ||
        (decision === "request_changes" && documentTypes.length === 0)
      ) return fail(400, "bad-request", "INVALID_REVIEW");
      const { data, error } = await db.rpc("admin_review_application", {
        p_actor_uid: actor.firebase_uid,
        p_application_id: applicationId,
        p_expected_version: version,
        p_action: decision,
        p_note: note,
        p_document_types: documentTypes,
      });
      if (error) throw error;
      // The review transaction is committed. Email failures must not imply the
      // decision was rolled back or encourage a duplicate approval.
      const delivery = await deliverApplicationNotifications(
        db,
        applicationId,
        actor.firebase_uid,
      ).catch(() => ({ state: "pending", sent: 0, pending: 1 }));
      return json({ ok: true, application: data, delivery });
    }
    if (action === "retry_delivery") {
      if (actor.role !== "admin") {
        return fail(403, "forbidden", "ADMIN_ROLE_REQUIRED");
      }
      const { data, error } = await db.rpc("admin_application_detail", {
        p_actor_uid: actor.firebase_uid,
        p_application_id: applicationId,
      });
      if (error) throw error;
      if (!data) return fail(404, "not-found", "APPLICATION_NOT_FOUND");
      const delivery = await deliverApplicationNotifications(
        db,
        applicationId,
        actor.firebase_uid,
      ).catch(() => ({ state: "pending", sent: 0, pending: 1 }));
      return json({ ok: true, delivery });
    }
    if (action === "certificate") {
      const { data: certificate, error } = await db.rpc(
        "admin_application_certificate",
        { p_actor_uid: actor.firebase_uid, p_application_id: applicationId },
      );
      if (error) throw error;
      if (!certificate) return fail(404, "not-found", "CERTIFICATE_NOT_FOUND");
      await certificateAttachment(db, certificate);
      const { data, error: signError } = await db.storage.from(
        "worker-documents",
      ).createSignedUrl(`certificates/${certificate.certificate_id}.pdf`, 60);
      if (signError || !data) throw new Error("CERTIFICATE_UNAVAILABLE");
      return json({ ok: true, url: data.signedUrl, expires_in: 60 });
    }
    return fail(400, "bad-request", "INVALID_ACTION");
  } catch (error) {
    if (error instanceof RequestBodyError) {
      return fail(error.status, "invalid-request", error.code);
    }
    if (error instanceof AdminAuthError) {
      return fail(error.status, "admin-access", error.code);
    }
    const code = String((error as { message?: string })?.message ?? "");
    if (/STALE|VERSION|CONCURRENT/.test(code)) {
      return fail(409, "stale-review", "APPLICATION_CHANGED_REFRESH");
    }
    if (/ADMIN|FORBIDDEN|PERMISSION/.test(code)) {
      return fail(403, "forbidden", "ADMIN_ACCESS_REQUIRED");
    }
    if (/NOT_FOUND/.test(code)) {
      return fail(404, "not-found", "APPLICATION_NOT_FOUND");
    }
    if (/INVALID|REQUIRED|NOT_REVIEWABLE|ALREADY/.test(code)) {
      return fail(409, "review-blocked", "REVIEW_NOT_ALLOWED");
    }
    return fail(503, "unavailable", "ADMIN_REQUEST_UNAVAILABLE");
  }
});
