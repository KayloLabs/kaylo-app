import {
  correctionLink,
  portalPageUrl,
  signCorrectionToken,
  verifyCorrectionToken,
} from "./application_correction_token.ts";
const secret = "test-only-correction-key-at-least-32-characters";
const capability = {
  applicationId: "11111111-1111-4111-8111-111111111111",
  version: 4,
};
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}
Deno.test("correction link signs application and batch version without exposing PII", async () => {
  const token = await signCorrectionToken(
    capability,
    new Date(Date.now() + 86400000).toISOString(),
    secret,
  );
  const verified = await verifyCorrectionToken(token, secret);
  assert(
    verified.applicationId === capability.applicationId &&
      verified.version === 4,
  );
  const link = new URL(correctionLink(token, "https://kaylo.example.test"));
  assert(
    link.pathname === "/application/update/" && link.search === "" &&
      link.hash.startsWith("#token="),
  );
});
Deno.test("forged or expired correction capabilities are rejected", async () => {
  const token = await signCorrectionToken(
    capability,
    new Date(Date.now() + 86400000).toISOString(),
    secret,
  );
  for (const value of [token.slice(0, -8) + "forged", ""]) {
    let denied = false;
    try {
      await verifyCorrectionToken(value, secret);
    } catch {
      denied = true;
    }
    assert(denied);
  }
  let denied = false;
  try {
    await signCorrectionToken(
      capability,
      new Date(Date.now() - 1000).toISOString(),
      secret,
    );
  } catch {
    denied = true;
  }
  assert(denied);
});
Deno.test("correction URL cannot use insecure, credentialed or query configured origins", () => {
  for (
    const url of [
      "http://example.test",
      "https://user:pass@example.test",
      "https://example.test?next=elsewhere",
      "https://example.test/kaylo-website/#fragment",
      "",
    ]
  ) {
    let denied = false;
    try {
      correctionLink("token", url);
    } catch {
      denied = true;
    }
    assert(denied);
  }
});

Deno.test("portal email links preserve GitHub Pages subpaths with or without trailing slash", () => {
  for (
    const base of [
      "https://nimaldanyathk.github.io/kaylo-website",
      "https://nimaldanyathk.github.io/kaylo-website/",
    ]
  ) {
    assert(
      portalPageUrl("admin/", base).toString() ===
        "https://nimaldanyathk.github.io/kaylo-website/admin/",
    );
    const link = new URL(correctionLink("test+capability/value", base));
    assert(
      link.pathname === "/kaylo-website/application/update/" &&
        link.search === "" &&
        new URLSearchParams(link.hash.slice(1)).get("token") ===
          "test+capability/value",
    );
  }
});
Deno.test("root-hosted email links keep their existing routes", () => {
  for (
    const base of ["https://kaylo.example.test", "https://kaylo.example.test/"]
  ) {
    assert(
      portalPageUrl("admin/", base).toString() ===
        "https://kaylo.example.test/admin/",
    );
    assert(
      new URL(correctionLink("token", base)).pathname ===
        "/application/update/",
    );
  }
});
