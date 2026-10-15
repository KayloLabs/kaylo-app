import {
  passwordRecoveryHandler,
  type RecoveryDependencies,
} from "./partner_password_recovery.ts";

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const identity = {
  firebase_uid: "issued-test",
  issuance_id: "issuance-test",
  partner_id: "KP-000123",
  email: "registered@example.com",
};
const resetLink =
  "https://example.firebaseapp.com/__/auth/action?mode=resetPassword&oobCode=PRIVATE_RESET_CODE";
function setup(overrides: Partial<RecoveryDependencies> = {}) {
  const deliveries: { to: string; link: string }[] = [];
  let lookups = 0;
  const handler = passwordRecoveryHandler({
    configured: true,
    claim: async (id, email, hash) => {
      lookups++;
      assert(id === "KP-000123" && email === "registered@example.com");
      assert(/^[a-f0-9]{64}$/.test(hash));
      return identity;
    },
    generateLink: async () => resetLink,
    send: async (record, link) => {
      deliveries.push({ to: record.email, link });
    },
    ...overrides,
  });
  return { handler, deliveries, lookups: () => lookups };
}
function request(
  body: unknown = {
    partner_id: " kp-000123 ",
    email: " Registered@Example.com ",
  },
) {
  return new Request("https://example.test/reset", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}
Deno.test("reset delivers only to the database email and never exposes the link", async () => {
  const { handler, deliveries } = setup();
  const response = await handler(request());
  assert(response.status === 200);
  assert(await response.text() === '{"ok":true}');
  assert(
    deliveries.length === 1 && deliveries[0].to === identity.email &&
      deliveries[0].link === resetLink,
  );
});
Deno.test("unknown account and disabled or mismatched Firebase identity have neutral responses", async () => {
  for (
    const overrides of [{ claim: async () => ({}) }, {
      generateLink: async () => null,
    }]
  ) {
    const { handler, deliveries } = setup(overrides);
    const response = await handler(request());
    assert(response.status === 200 && await response.text() === '{"ok":true}');
    assert(deliveries.length === 0);
  }
});
Deno.test("rate limited requests cannot generate links or send email", async () => {
  const { handler, deliveries } = setup({
    claim: async () => ({ limited: true }),
    generateLink: () => {
      throw new Error("must not run");
    },
  });
  assert((await handler(request())).status === 429);
  assert(deliveries.length === 0);
});
Deno.test("invalid ID, alias, missing, oversized and malformed JSON fail before lookup", async () => {
  const { handler, lookups } = setup();
  for (
    const body of [
      null,
      {},
      { partner_id: "KP-12", email: "real@example.com" },
      { partner_id: "KP-000123", email: "kp-000123@partners.kaylo.app" },
      { partner_id: "KP-000123", email: "not-an-email" },
    ]
  ) {
    assert((await handler(request(body))).status === 400);
  }
  assert((await handler(request({ email: "a".repeat(2100) }))).status === 413);
  assert(
    (await handler(
      new Request("https://test/reset", { method: "POST", body: "{" }),
    )).status === 400,
  );
  assert(lookups() === 0);
});
Deno.test("delivery failure is not reported as success and does not expose provider secrets", async () => {
  const { handler } = setup({
    send: () => {
      throw new Error(resetLink);
    },
  });
  const response = await handler(request());
  assert(response.status === 503);
  assert(!(await response.text()).includes("PRIVATE_RESET_CODE"));
});
Deno.test("unconfigured service fails clearly; GET and preflight do not send mail", async () => {
  const { handler, lookups } = setup({ configured: false });
  assert((await handler(request())).status === 503);
  assert((await handler(new Request("https://test/reset"))).status === 405);
  assert(
    (await handler(new Request("https://test/reset", { method: "OPTIONS" })))
      .status === 200,
  );
  assert(lookups() === 0);
});
