import {
  type BootstrapDependencies,
  handleBootstrap,
  targetEmail,
} from "./bootstrap.ts";
const secret = "a".repeat(64);
function request(
  body: unknown = { operation: "prepare_admin_setup" },
  headers: Record<string, string> = {},
) {
  return new Request("https://example.test", {
    method: "POST",
    headers: { "x-kaylo-admin-bootstrap-secret": secret, ...headers },
    body: JSON.stringify(body),
  });
}
function deps(): BootstrapDependencies {
  return {
    secret,
    findUser: () =>
      Promise.resolve({ localId: "existing-user", email: targetEmail }),
    createUser: () => Promise.reject(new Error("must not create")),
    checkRegistry: () => Promise.resolve(),
    ensureAdmin: () => Promise.resolve(),
    setupLink: () =>
      Promise.resolve("https://example.test/setup?oobCode=test-only"),
  };
}
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}
Deno.test("bootstrap rejects incorrect secrets, browser calls and arbitrary emails before touching Firebase", async () => {
  const d = {
    ...deps(),
    findUser: () => Promise.reject(new Error("must not call")),
  };
  for (
    const r of [
      request(undefined, { "x-kaylo-admin-bootstrap-secret": "wrong" }),
      request(undefined, { origin: "https://example.test" }),
      request({
        operation: "prepare_admin_setup",
        email: "different@example.test",
      }),
    ]
  ) {
    const result = await handleBootstrap(r, d);
    assert(result.status === 400 || result.status === 403);
  }
  assert(
    (await handleBootstrap(new Request("https://example.test"), d)).status ===
      405,
  );
  assert(
    (await handleBootstrap(request(), { ...d, secret: "weak" })).status === 403,
  );
});
Deno.test("existing account gets only a setup link and registry entry without changing its password", async () => {
  let entries = 0;
  const result = await handleBootstrap(request(), {
    ...deps(),
    ensureAdmin: () => {
      entries++;
      return Promise.resolve();
    },
  });
  const body = await result.json();
  assert(
    result.status === 200 && body.email === targetEmail &&
      body.uid === "existing-user" && !body.created && entries === 1,
  );
  assert(Object.keys(body).sort().join() === "created,email,setup_url,uid");
  assert(
    !result.headers.has("access-control-allow-origin") &&
      result.headers.get("cache-control") === "no-store",
  );
});
Deno.test("missing account is created for only the fixed address", async () => {
  let creations = 0;
  const result = await handleBootstrap(request(), {
    ...deps(),
    findUser: () => Promise.resolve(null),
    createUser: () => {
      creations++;
      return Promise.resolve({ localId: "new-user", email: targetEmail });
    },
  });
  assert(
    result.status === 200 && (await result.json()).created === true &&
      creations === 1,
  );
});
Deno.test("disabled account or existing conflicting registry cannot be activated", async () => {
  assert(
    (await handleBootstrap(request(), {
      ...deps(),
      findUser: () =>
        Promise.resolve({
          localId: "user",
          email: targetEmail,
          disabled: true,
        }),
    })).status === 409,
  );
  let links = 0;
  assert(
    (await handleBootstrap(request(), {
      ...deps(),
      checkRegistry: () => Promise.reject(new Error("conflicting role")),
      setupLink: () => {
        links++;
        return Promise.resolve("https://example.test");
      },
    })).status === 503,
  );
  assert(links === 0);
});
