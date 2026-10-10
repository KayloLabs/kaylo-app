import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import {
  firebaseProjectId,
  lookupFirebaseAccount,
} from "../_shared/firebase_admin.ts";
import { verifyFirebaseToken } from "../_shared/firebase_verify.ts";
import { verifiedPasswordChange } from "../_shared/partner_security.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST_ONLY");
  const token =
    request.headers.get("authorization")?.replace(/^Bearer /i, "") ?? "";
  try {
    const uid = await verifyFirebaseToken(token, firebaseProjectId());
    // Decoding only after Google's signature has been verified above.
    const claims = JSON.parse(
      atob(token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/")),
    );
    if (
      claims.firebase?.sign_in_provider !== "password" ||
      claims.kaylo_role !== "worker"
    ) return fail(403, "partner-only", "PARTNER_ONLY");
    const db = serviceClient();
    const { data: c, error } = await db.from("partner_credentials").select(
      "worker_id,issuance_id,state,password_updated_at_ms",
    ).eq("firebase_uid", uid).maybeSingle();
    if (error || !c || !["ready", "delivered"].includes(c.state)) {
      return fail(403, "partner-only", "PARTNER_ONLY");
    }
    // A refreshed session from an older reset cannot clear a new issuance gate.
    if (claims.kaylo_issuance_id !== c.issuance_id) {
      return fail(401, "session-expired", "SIGN_IN_AGAIN");
    }
    const account = await lookupFirebaseAccount(uid);
    if (
      !account || account.disabled ||
      Number(claims.iat) < Number(account.validSince ?? 0)
    ) return fail(401, "session-expired", "SIGN_IN_AGAIN");
    const changed = Number(account.passwordUpdatedAt);
    if (!verifiedPasswordChange(Number(c.password_updated_at_ms), changed)) {
      return fail(
        409,
        "password-change-required",
        "PASSWORD_CHANGE_NOT_VERIFIED",
      );
    }
    const { error: clearError } = await db.rpc("mark_password_changed", {
      p_worker_id: c.worker_id,
      p_issuance_id: c.issuance_id,
      p_password_updated_at_ms: changed,
    });
    if (clearError) {
      return fail(
        409,
        "password-change-required",
        "PASSWORD_CHANGE_NOT_VERIFIED",
      );
    }
    return json({ ok: true });
  } catch {
    return fail(401, "unauthenticated", "SIGN_IN_AGAIN");
  }
});
