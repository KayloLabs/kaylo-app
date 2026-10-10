export const partnerDocumentTypes = new Set([
  "photo",
  "aadhaar_front",
  "aadhaar_back",
  "police_certificate",
  "selfie",
]);
export async function sha256(value: string): Promise<string> {
  return Array.from(
    new Uint8Array(
      await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)),
    ),
    (b) => b.toString(16).padStart(2, "0"),
  ).join("");
}
export async function secretMatches(
  supplied: string,
  expected: string,
): Promise<boolean> {
  if (!expected || expected.length < 32) return false;
  const a = await sha256(supplied), b = await sha256(expected);
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}
export function temporaryPassword(): string {
  // A fixed mixed-class prefix plus 192 random bits, no modulo-biased alphabet.
  return "Kp9!" +
    Array.from(
      crypto.getRandomValues(new Uint8Array(24)),
      (b) => b.toString(16).padStart(2, "0"),
    ).join("");
}
export function documentMime(bytes: Uint8Array): string | null {
  if (
    bytes.length >= 8 &&
    [137, 80, 78, 71, 13, 10, 26, 10].every((v, i) => bytes[i] === v)
  ) return "image/png";
  if (
    bytes.length >= 3 && bytes[0] === 255 && bytes[1] === 216 &&
    bytes[2] === 255
  ) return "image/jpeg";
  if (
    bytes.length >= 5 && new TextDecoder().decode(bytes.slice(0, 5)) === "%PDF-"
  ) return "application/pdf";
  return null;
}
export function verifiedPasswordChange(
  baseline: number,
  changed: number,
): boolean {
  return Number.isFinite(baseline) && baseline > 0 &&
    Number.isFinite(changed) && changed > baseline;
}
