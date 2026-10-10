import {
  documentMime,
  secretMatches,
  temporaryPassword,
  verifiedPasswordChange,
} from "./partner_security.ts";
function assert(condition: boolean) {
  if (!condition) throw new Error("assertion failed");
}
Deno.test("admin secret fails closed and compares exact values", async () => {
  assert(!await secretMatches("", ""));
  assert(!await secretMatches("short", "short"));
  assert(await secretMatches("a".repeat(32), "a".repeat(32)));
  assert(!await secretMatches("a".repeat(31) + "b", "a".repeat(32)));
});
Deno.test("document types require actual file signatures", () => {
  assert(
    documentMime(new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10])) ===
      "image/png",
  );
  assert(documentMime(new Uint8Array([255, 216, 255, 0])) === "image/jpeg");
  assert(
    documentMime(new TextEncoder().encode("%PDF-1.4")) === "application/pdf",
  );
  assert(documentMime(new TextEncoder().encode("<script>")) === null);
  assert(documentMime(new Uint8Array()) === null);
});
Deno.test("temporary passwords are unique high entropy mixed-class strings", () => {
  const passwords = Array.from({ length: 100 }, temporaryPassword);
  assert(new Set(passwords).size === 100);
  assert(passwords.every((p) => /^Kp9![0-9a-f]{48}$/.test(p)));
});
Deno.test("only a newer Firebase password timestamp clears the gate", () => {
  assert(!verifiedPasswordChange(100, 100));
  assert(!verifiedPasswordChange(100, 99));
  assert(!verifiedPasswordChange(0, 100));
  assert(!verifiedPasswordChange(100, NaN));
  assert(verifiedPasswordChange(100, 101));
});
