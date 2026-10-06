import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from "npm:jose@5";
import { verifyFirebaseToken } from "./firebase_verify.ts";
const pair = await generateKeyPair("RS256");
const jwk = await exportJWK(pair.publicKey);
const keys = createLocalJWKSet({ keys: [{ ...jwk, kid: "test-key", alg: "RS256" }] });
async function token({ project = "test-project", expired = false, authTime = true } = {}) {
  const now = Math.floor(Date.now() / 1000);
  return await new SignJWT(authTime ? { auth_time: now } : {})
    .setProtectedHeader({ alg: "RS256", kid: "test-key" })
    .setSubject("test-user").setIssuer(`https://securetoken.google.com/${project}`)
    .setAudience(project).setIssuedAt().setExpirationTime(expired ? now - 30 : now + 3600).sign(pair.privateKey);
}
async function rejects(value: string) {
  try { await verifyFirebaseToken(value, "test-project", keys); }
  catch { return; }
  throw new Error("Invalid token was accepted");
}
Deno.test("accepts a signed token only for the expected Firebase project", async () => {
  if (await verifyFirebaseToken(await token(), "test-project", keys) !== "test-user") throw new Error("Wrong identity");
});
Deno.test("rejects another project's token", async () => rejects(await token({ project: "other-project" })));
Deno.test("rejects expired tokens", async () => rejects(await token({ expired: true })));
Deno.test("rejects missing authentication time", async () => rejects(await token({ authTime: false })));
Deno.test("rejects forged signatures", async () => {
  const parts = (await token()).split("."); parts[2] = "a".repeat(parts[2].length); await rejects(parts.join("."));
});
Deno.test("rejects malformed tokens", async () => rejects("not-a-token"));
