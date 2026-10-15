import { corsHeaders, fail, json } from "./cors.ts";
import { readBoundedJson, RequestBodyError } from "./http_body.ts";

export interface RecoveryIdentity {
  firebase_uid: string;
  issuance_id: string;
  partner_id: string;
  email: string;
}
export interface RecoveryDependencies {
  configured: boolean;
  claim: (
    id: string,
    email: string,
    clientHash: string,
  ) => Promise<Partial<RecoveryIdentity> & { limited?: boolean }>;
  generateLink: (identity: RecoveryIdentity) => Promise<string | null>;
  send: (identity: RecoveryIdentity, link: string) => Promise<void>;
}

/** Never return a reset link, destination address or account existence to callers. */
export function passwordRecoveryHandler(deps: RecoveryDependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }
    if (request.method !== "POST") return fail(405, "method", "POST_ONLY");
    try {
      const body = await readBoundedJson(request, 2048) as
        | Record<string, unknown>
        | null;
      const id = typeof body?.partner_id === "string"
        ? body.partner_id.trim().toUpperCase()
        : "";
      const email = typeof body?.email === "string"
        ? body.email.trim().toLowerCase()
        : "";
      if (
        !/^KP-[0-9]{6}$/.test(id) || email.length > 254 ||
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) ||
        email.endsWith("@partners.kaylo.app")
      ) {
        return fail(400, "invalid-request", "INVALID_REQUEST");
      }
      if (!deps.configured) {
        return fail(503, "unavailable", "RESET_UNAVAILABLE");
      }
      // Account and global budgets remain effective even if a proxy header is absent/spoofed.
      const client =
        request.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
        "unknown";
      const digest = await crypto.subtle.digest(
        "SHA-256",
        new TextEncoder().encode(client),
      );
      const hash = Array.from(
        new Uint8Array(digest),
        (b) => b.toString(16).padStart(2, "0"),
      ).join("");
      const identity = await deps.claim(id, email, hash);
      if (identity.limited) return fail(429, "rate-limit", "TRY_LATER");
      if (
        identity.firebase_uid && identity.issuance_id && identity.partner_id &&
        identity.email
      ) {
        const issued = identity as RecoveryIdentity;
        const link = await deps.generateLink(issued);
        if (link) await deps.send(issued, link);
      }
      return json({ ok: true });
    } catch (error) {
      if (error instanceof RequestBodyError) {
        return fail(error.status, "invalid-request", error.code);
      }
      // SDK/provider errors may contain credentials or reset codes. Never echo/log them.
      console.error("Partner password recovery could not complete");
      return fail(503, "unavailable", "RESET_UNAVAILABLE");
    }
  };
}
