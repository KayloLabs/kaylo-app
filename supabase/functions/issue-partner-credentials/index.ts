import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import { secretMatches } from "../_shared/partner_security.ts";
import { deliverPartnerCredentials } from "../_shared/partner_credentials_delivery.ts";
import { uuidPattern } from "../_shared/application_correction_token.ts";
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
  // Legacy support tooling only. The browser admin endpoint uses signed Firebase sessions.
  if (
    !await secretMatches(
      request.headers.get("x-kaylo-admin-secret") ?? "",
      Deno.env.get("KAYLO_PARTNER_ADMIN_SECRET") ?? "",
    )
  ) return fail(403, "forbidden", "ADMIN_ONLY");
  try {
    const body = await request.json();
    if (
      !uuidPattern.test(String(body.worker_id ?? "")) ||
      !["issue", "reset"].includes(body.action)
    ) return fail(400, "bad-request", "INVALID_REQUEST");
    return json({
      ok: true,
      ...await deliverPartnerCredentials(serviceClient(), body.worker_id, {
        reset: body.action === "reset",
      }),
    });
  } catch {
    return fail(503, "issuance-failed", "ISSUANCE_FAILED_RETRY_ADMIN");
  }
});
