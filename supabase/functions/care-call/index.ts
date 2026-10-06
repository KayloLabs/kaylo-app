import { verifyFirebaseToken } from "../_shared/firebase_verify.ts";
import { callerClient, serviceClient } from "../_shared/clients.ts";
import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { sendCareCallPush, firebaseProjectId } from "../_shared/firebase_admin.ts";
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return fail(405, "method", "POST only");
  const bearer = request.headers.get("Authorization")?.match(/^Bearer (.+)$/)?.[1];
  if (!bearer) return fail(401, "auth", "Sign in first");
  try { await verifyFirebaseToken(bearer, firebaseProjectId()); }
  catch { return fail(401, "auth", "Your sign-in token is invalid or expired"); }
  const caller = callerClient(request);
  if (!caller) return fail(401, "auth", "Sign in first");
  const body = await request.json().catch(() => ({}));
  const { data: pid, error: authError } = await caller.rpc("current_person_id");
  if (authError || !pid) return fail(401, "auth", "Sign in first");
  let iceServers: unknown[] = [{ urls: ["stun:stun.l.google.com:19302"] }];
  const configured = Deno.env.get("CARE_ICE_SERVERS_JSON");
  if (configured) { try { iceServers = JSON.parse(configured); } catch { return fail(503, "config", "Call configuration is invalid"); } }
  if (body.action === "config") return json({ ice_servers: iceServers, relay_configured: Boolean(configured) });
  const { data: callId, error } = await caller.rpc("start_care_call");
  if (error) return fail(400, "call", error.message);
  const service = serviceClient();
  const { data: members } = await service.from("care_call_members").select("person_id,name").eq("call_id", callId);
  const contactIds = (members ?? []).filter((m) => m.person_id !== pid).map((m) => m.person_id);
  const name = members?.find((m) => m.person_id === pid)?.name ?? "Your trusted contact";
  const { data: tokens } = await service.from("device_tokens").select("token").in("person_id", contactIds).eq("app", "customer");
  const sent = await Promise.allSettled((tokens ?? []).map((t) => sendCareCallPush(t.token, callId, name)));
  return json({ call_id: callId, invited: contactIds.length, push_accepted: sent.filter((s) => s.status === "fulfilled" && s.value).length, ice_servers: iceServers, relay_configured: Boolean(configured) });
});
