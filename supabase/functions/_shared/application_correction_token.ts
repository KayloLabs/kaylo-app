import { jwtVerify, SignJWT } from "npm:jose@5";

const issuer = "kaylo-partner-applications";
const audience = "kaylo-application-correction";
export const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function key(secret: string): Uint8Array {
  if (secret.length < 32) throw new Error("CORRECTION_LINK_NOT_CONFIGURED");
  return new TextEncoder().encode(secret);
}
export interface CorrectionCapability {
  applicationId: string;
  version: number;
}
export async function signCorrectionToken(
  capability: CorrectionCapability,
  expiresAt: string,
  secret = Deno.env.get("APPLICATION_CORRECTION_SECRET") ?? "",
): Promise<string> {
  if (
    !uuidPattern.test(capability.applicationId) ||
    !Number.isInteger(capability.version) || capability.version < 1
  ) {
    throw new Error("INVALID_CORRECTION_CAPABILITY");
  }
  const now = Math.floor(Date.now() / 1000);
  const expires = Math.floor(new Date(expiresAt).getTime() / 1000);
  if (
    !Number.isFinite(expires) || expires <= now ||
    expires > now + 7 * 86400 + 60
  ) {
    throw new Error("CORRECTION_LINK_EXPIRED");
  }
  return await new SignJWT({ version: capability.version })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" }).setIssuer(issuer)
    .setAudience(audience).setSubject(capability.applicationId)
    .setIssuedAt(now).setExpirationTime(expires).sign(key(secret));
}
export async function verifyCorrectionToken(
  token: string,
  secret = Deno.env.get("APPLICATION_CORRECTION_SECRET") ?? "",
): Promise<CorrectionCapability> {
  if (!token || token.length > 4096) throw new Error("INVALID_CORRECTION_LINK");
  const { payload } = await jwtVerify(token, key(secret), {
    algorithms: ["HS256"],
    issuer,
    audience,
    requiredClaims: ["sub", "iat", "exp", "version"],
    maxTokenAge: "7d",
  });
  if (
    !uuidPattern.test(payload.sub ?? "") ||
    !Number.isInteger(payload.version) ||
    Number(payload.version) < 1 || typeof payload.iat !== "number" ||
    typeof payload.exp !== "number" ||
    payload.exp - payload.iat > 7 * 86400 + 60
  ) {
    throw new Error("INVALID_CORRECTION_LINK");
  }
  return { applicationId: payload.sub!, version: Number(payload.version) };
}
export function correctionLink(
  token: string,
  portal = Deno.env.get("KAYLO_PORTAL_URL") ?? "",
): string {
  const base = new URL(portal);
  if (
    base.protocol !== "https:" || base.username || base.password ||
    base.search || base.hash
  ) {
    throw new Error("PORTAL_URL_NOT_CONFIGURED");
  }
  const link = new URL("/application/update/", base.origin);
  link.hash = new URLSearchParams({ token }).toString();
  return link.toString();
}
