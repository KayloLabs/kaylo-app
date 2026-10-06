import { createRemoteJWKSet, jwtVerify, type JWTVerifyGetKey } from "npm:jose@5";

const googleKeys = createRemoteJWKSet(new URL(
  "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
));

const CLOCK_SKEW_SECONDS = 30;

/** Verify Google's signature and project claims before any privileged operation. */
export async function verifyFirebaseToken(token: string, projectId: string, keys: JWTVerifyGetKey = googleKeys): Promise<string> {
  const { payload } = await jwtVerify(token, keys, {
    algorithms: ["RS256"], issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId, requiredClaims: ["sub", "exp", "iat", "auth_time"],
    clockTolerance: CLOCK_SKEW_SECONDS,
  });
  // Google's clock and this server's can differ by a moment, so a token
  // issued this very second must not look like one from the future.
  const now = Math.floor(Date.now() / 1000) + CLOCK_SKEW_SECONDS;
  if (!payload.sub || payload.sub.length > 128 || (payload.iat ?? now + 1) > now ||
      typeof payload.auth_time !== "number" || payload.auth_time > now) {
    throw new Error("Invalid Firebase token claims");
  }
  return payload.sub;
}
