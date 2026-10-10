import {
  type AdminActor,
  AdminAuthError,
  adminFirebaseSessionIsCurrent,
  assertAdminDecision,
  authenticateAdmin,
} from "./admin_auth.ts";
const actor: AdminActor = {
  firebase_uid: "admin-uid",
  email: "admin@example.test",
  role: "admin",
  is_active: true,
};
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}
async function rejects(action: () => Promise<unknown>, status: number) {
  try {
    await action();
  } catch (error) {
    assert(error instanceof AdminAuthError && error.status === status);
    return;
  }
  throw new Error("expected rejection");
}
Deno.test("admin requires a signed Firebase token, never a static browser secret", async () => {
  await rejects(
    () =>
      authenticateAdmin(
        new Request("https://example.test", {
          headers: { "x-kaylo-admin-secret": "secret" },
        }),
        {
          projectId: "project",
          checkSession: () => Promise.resolve(true),
          verify: () => Promise.resolve("admin-uid"),
          lookup: () => Promise.resolve(actor),
        },
      ),
    401,
  );
  await rejects(
    () =>
      authenticateAdmin(
        new Request("https://example.test", {
          headers: { authorization: "Bearer forged" },
        }),
        {
          projectId: "project",
          checkSession: () => Promise.resolve(true),
          verify: () => Promise.reject(new Error("bad signature")),
          lookup: () => Promise.resolve(actor),
        },
      ),
    401,
  );
});
Deno.test("valid Firebase users still require active admin allowlist membership", async () => {
  for (
    const record of [null, { ...actor, is_active: false }, {
      ...actor,
      firebase_uid: "someone-else",
    }]
  ) {
    await rejects(
      () =>
        authenticateAdmin(
          new Request("https://example.test", {
            headers: { authorization: "Bearer valid" },
          }),
          {
            projectId: "project",
            checkSession: () => Promise.resolve(true),
            verify: () => Promise.resolve("admin-uid"),
            lookup: () => Promise.resolve(record),
          },
        ),
      403,
    );
  }
});
Deno.test("admin role controls final decisions and reviewer can request corrections", () => {
  assertAdminDecision(actor, "approve");
  assertAdminDecision({ ...actor, role: "reviewer" }, "request_changes");
  try {
    assertAdminDecision({ ...actor, role: "reviewer" }, "approve");
  } catch (error) {
    assert(error instanceof AdminAuthError && error.status === 403);
    return;
  }
  throw new Error("reviewer approved application");
});

Deno.test("disabled or revoked Firebase sessions cannot use an active admin row", async () => {
  await rejects(
    () =>
      authenticateAdmin(
        new Request("https://example.test", {
          headers: { authorization: "Bearer valid" },
        }),
        {
          projectId: "project",
          verify: () => Promise.resolve("admin-uid"),
          checkSession: () => Promise.resolve(false),
          lookup: () => Promise.resolve(actor),
        },
      ),
    401,
  );
});
Deno.test("admin lookup outage fails closed rather than trusting a signed ordinary user", async () => {
  await rejects(
    () =>
      authenticateAdmin(
        new Request("https://example.test", {
          headers: { authorization: "Bearer valid" },
        }),
        {
          projectId: "project",
          verify: () => Promise.resolve("admin-uid"),
          checkSession: () => Promise.resolve(true),
          lookup: () => Promise.reject(new Error("offline")),
        },
      ),
    503,
  );
});

Deno.test("refreshing a revoked admin session cannot bypass validSince", () => {
  const claims = {
    auth_time: 100,
    iat: 300,
    firebase: { sign_in_provider: "password" },
  };
  assert(!adminFirebaseSessionIsCurrent(claims, { validSince: "200" }));
  assert(
    adminFirebaseSessionIsCurrent({ ...claims, auth_time: 201 }, {
      validSince: "200",
    }),
  );
  assert(
    !adminFirebaseSessionIsCurrent({ ...claims, auth_time: 201 }, {
      validSince: "200",
      disabled: true,
    }),
  );
  assert(
    !adminFirebaseSessionIsCurrent({ ...claims, auth_time: undefined }, {
      validSince: "200",
    }),
  );
  assert(
    !adminFirebaseSessionIsCurrent({
      ...claims,
      firebase: { sign_in_provider: "google.com" },
    }, { validSince: "50" }),
  );
});
