// One-off bootstrap template only. Never include in routine edge deployments.
export const targetEmail = "kayloapp@gmail.com";
export interface FirebaseUser {
  localId: string;
  email?: string;
  disabled?: boolean;
}
export interface BootstrapDependencies {
  secret: string;
  findUser: () => Promise<FirebaseUser | null>;
  createUser: () => Promise<FirebaseUser>;
  checkRegistry: (uid: string) => Promise<void>;
  ensureAdmin: (uid: string) => Promise<void>;
  setupLink: () => Promise<string>;
}
function response(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
// Same constant-time digest comparison used by partner_security.secretMatches.
export async function secretMatches(
  supplied: string,
  expected: string,
): Promise<boolean> {
  if (!/^[a-f0-9]{64}$/i.test(expected)) return false;
  const hash = async (value: string) =>
    new Uint8Array(
      await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)),
    );
  const a = await hash(supplied), b = await hash(expected);
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) mismatch |= a[i] ^ b[i];
  return mismatch === 0;
}
export async function handleBootstrap(
  request: Request,
  deps: BootstrapDependencies,
): Promise<Response> {
  if (request.method !== "POST") return response({ error: "POST_ONLY" }, 405);
  if (request.headers.has("origin")) {
    return response({ error: "BROWSER_NOT_ALLOWED" }, 403);
  }
  if (
    !await secretMatches(
      request.headers.get("x-kaylo-admin-bootstrap-secret") ?? "",
      deps.secret,
    )
  ) return response({ error: "BOOTSTRAP_FORBIDDEN" }, 403);
  try {
    if (Number(request.headers.get("content-length") ?? 0) > 1024) {
      return response({ error: "INVALID_REQUEST" }, 400);
    }
    const reader = request.body?.getReader();
    if (!reader) return response({ error: "INVALID_REQUEST" }, 400);
    const chunks: Uint8Array[] = [];
    let length = 0;
    while (true) {
      const part = await reader.read();
      if (part.done) break;
      length += part.value.length;
      if (length > 1024) {
        await reader.cancel();
        return response({ error: "INVALID_REQUEST" }, 400);
      }
      chunks.push(part.value);
    }
    const bytes = new Uint8Array(length);
    let offset = 0;
    for (const chunk of chunks) {
      bytes.set(chunk, offset);
      offset += chunk.length;
    }
    let body: unknown;
    try {
      body = JSON.parse(new TextDecoder().decode(bytes));
    } catch {
      return response({ error: "INVALID_REQUEST" }, 400);
    }
    if (
      !body || typeof body !== "object" || Array.isArray(body) ||
      Object.keys(body).length !== 1 ||
      (body as { operation?: unknown }).operation !== "prepare_admin_setup"
    ) return response({ error: "INVALID_OPERATION" }, 400);
    let user = await deps.findUser();
    let created = false;
    if (!user) {
      user = await deps.createUser();
      created = true;
    }
    if (
      !user.localId || user.email?.toLowerCase() !== targetEmail ||
      user.disabled
    ) return response({ error: "ACCOUNT_UNAVAILABLE" }, 409);
    await deps.checkRegistry(user.localId);
    const setupUrl = await deps.setupLink();
    if (new URL(setupUrl).protocol !== "https:") {
      throw new Error("INVALID_SETUP_LINK");
    }
    await deps.ensureAdmin(user.localId);
    return response({
      email: targetEmail,
      uid: user.localId,
      setup_url: setupUrl,
      created,
    });
  } catch {
    return response({ error: "BOOTSTRAP_FAILED_NO_PASSWORD_CHANGED" }, 503);
  }
}
