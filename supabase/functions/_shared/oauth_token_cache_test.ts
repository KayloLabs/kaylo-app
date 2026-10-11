import { createOAuthTokenCache } from "./oauth_token_cache.ts";

function assert(value: unknown, message: string) {
  if (!value) throw new Error(message);
}

Deno.test("concurrent admin requests share one exchange and reuse the service token", async () => {
  let calls = 0;
  let release!: (value: { accessToken: string; expiresIn: number }) => void;
  const token = createOAuthTokenCache(() => {
    calls++;
    return new Promise((resolve) => { release = resolve; });
  });
  const requests = [token(), token(), token()];
  assert(calls === 1, "Only one exchange should start");
  release({ accessToken: "service-token", expiresIn: 3600 });
  assert((await Promise.all(requests)).every((v) => v === "service-token"), "Shared result");
  assert(await token() === "service-token" && calls === 1, "Reuse before expiry");
});

Deno.test("OAuth token refreshes before expiry and caps upstream lifetime", async () => {
  let now = 0, calls = 0;
  const token = createOAuthTokenCache(async () => ({
    accessToken: `token-${++calls}`, expiresIn: 99999,
  }), () => now);
  assert(await token() === "token-1", "First token");
  now = 3539_000;
  assert(await token() === "token-1", "Still valid");
  now = 3540_000;
  assert(await token() === "token-2" && calls === 2, "Refresh one minute early");
});

Deno.test("failed token refresh clears the pending request and never serves expired credentials", async () => {
  let now = 0, calls = 0;
  const token = createOAuthTokenCache(async () => {
    calls++;
    if (calls === 2) throw new Error("exchange unavailable");
    return { accessToken: `token-${calls}`, expiresIn: 120 };
  }, () => now);
  await token();
  now = 60_000;
  const results = await Promise.allSettled([token(), token()]);
  assert(results.every((r) => r.status === "rejected") && calls === 2, "No stale fallback");
  assert(await token() === "token-3", "Later requests can retry");
});

Deno.test("missing or invalid expiry does not make a permanent cache entry", async () => {
  for (const expiresIn of [NaN, 0, -1, 60]) {
    let calls = 0;
    const token = createOAuthTokenCache(async () => ({accessToken: `token-${++calls}`, expiresIn}));
    await token();
    assert(await token() === "token-2", "Unknown or short expiry must refresh");
  }
});
