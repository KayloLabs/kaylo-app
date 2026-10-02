import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { callerClient, serviceClient } from "../_shared/clients.ts";
import { deleteFirebaseUser, firebaseAdminConfigured } from "../_shared/firebase_admin.ts";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return fail(405, "method", "POST only");
  if (!firebaseAdminConfigured) return fail(503, "configuration", "Account deletion is not configured. Contact kayloapp@gmail.com.");
  const caller = callerClient(request);
  if (!caller) return fail(401, "auth", "Sign in first");
  const body = await request.json().catch(() => null);
  if (body?.confirmation !== "DELETE") return fail(400, "confirmation", "Confirm deletion first");
  // The database verifies the JWT and derives the identity. No client-supplied uid.
  const { data: uid, error } = await caller.rpc("delete_current_kaylo_account");
  if (error || !uid) return fail(409, "delete", error?.message ?? "Could not verify your account");
  try {
    await deleteFirebaseUser(uid);
    await serviceClient().from("account_deletion_requests").delete().eq("auth_subject", uid);
    return json({ deleted: true });
  } catch (_) {
    return fail(503, "retry", "Your Kaylo records were removed, but sign-in removal needs another attempt. Keep this screen open and retry deletion.");
  }
});
