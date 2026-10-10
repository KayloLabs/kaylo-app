import {
  decodePDFRawStream,
  PDFDocument,
  PDFHexString,
  PDFRawStream,
} from "npm:pdf-lib@1.17.1";
import {
  Buffer,
  releaseBuffer,
} from "./partner_certificate_fonts/harfbuzz.mjs";
import {
  generatePartnerCertificate,
  type PartnerCertificateSnapshot,
} from "./partner_certificate.ts";

function assert(value: unknown, message = "Assertion failed"): asserts value {
  if (!value) throw new Error(message);
}
const fixture: PartnerCertificateSnapshot = {
  certificateId: "KC-20261010-000123",
  partnerId: "KP-000123",
  fullName: "Arjun Narayanan",
  profession: "Electrical services",
  district: "Kannur",
  issuedAt: "2026-10-10T10:30:00Z",
  verificationReference: "KA-24399BB3D24538CAA677879F",
  approvedDocumentTypes: [
    "photo",
    "aadhaar_front",
    "aadhaar_back",
    "police_certificate",
    "selfie",
  ],
};
function content(pdf: PDFDocument): string {
  let result = "";
  for (const [, object] of pdf.context.enumerateIndirectObjects()) {
    if (object instanceof PDFRawStream) {
      result += new TextDecoder().decode(decodePDFRawStream(object).decode());
    }
  }
  return result;
}
Deno.test("partner certificate is a dated single-page A4 approval record", async () => {
  const bytes = await generatePartnerCertificate(fixture);
  assert(new TextDecoder().decode(bytes.slice(0, 5)) === "%PDF-");
  const pdf = await PDFDocument.load(bytes);
  assert(pdf.getPageCount() === 1);
  const size = pdf.getPage(0).getSize();
  assert(size.width === 595.28 && size.height === 841.89);
  assert(pdf.getTitle() === "Kaylo Approved Partner - KP-000123");
  assert(pdf.getSubject()?.includes(fixture.fullName));
  assert(
    pdf.getCreationDate()?.toISOString() ===
      fixture.issuedAt.replace("Z", ".000Z"),
  );
  assert(
    bytes.length < 150_000,
    "Certificate should remain small enough for email",
  );
});

for (
  const [label, fullName, profession, district, firstRun] of [
    ["Malayalam", "നിമൽ ദന്യത്", "വൈദ്യുതി അറ്റകുറ്റപ്പണി", "കണ്ണൂർ", "നിമൽ"],
    ["Tamil", "அருண் குமார்", "மின் பழுதுபார்ப்பு", "கண்ணூர்", "அருண்"],
    ["Hindi", "अर्जुन कुमार", "बिजली मरम्मत", "कन्नूर", "अर्जुन"],
    [
      "mixed scripts",
      "Nimal നിമൽ அருண் कुमार",
      "Electrical services",
      "Kannur",
      "നിമൽ",
    ],
  ]
) {
  Deno.test(`partner certificate preserves ${label} names and Unicode copy text`, async () => {
    const pdf = await PDFDocument.load(
      await generatePartnerCertificate({
        ...fixture,
        fullName,
        profession,
        district,
      }),
    );
    assert(pdf.getPageCount() === 1);
    assert(pdf.getSubject()?.includes(fullName.normalize("NFC")));
    const drawing = content(pdf);
    assert(drawing.includes("/ActualText"));
    assert(
      drawing.includes(
        PDFHexString.fromText(firstRun.normalize("NFC")).toString(),
      ),
    );
    assert(drawing.includes("BDC") && drawing.includes("EMC"));
  });
}
Deno.test("partner certificate fits long names and fields without dropping text", async () => {
  const fullName =
    "Narayanan Krishnamurthy Parameswaran Sivasubramanian Ramanathan Sankaranarayanan";
  const pdf = await PDFDocument.load(
    await generatePartnerCertificate({
      ...fixture,
      fullName,
      profession:
        "Electrical installation, household repairs and appliance service support",
      district: "Thiruvananthapuram",
      verificationReference: "KA-" + "ABCDEF0123456789".repeat(4),
    }),
  );
  assert(pdf.getPageCount() === 1);
  assert(pdf.getSubject()?.includes(fullName));
});
function asciiHex(text: string): string {
  return [...text].map((c) => c.charCodeAt(0).toString(16).padStart(2, "0"))
    .join("").toUpperCase();
}
Deno.test("partner certificate lists only evidence actually marked reviewed", async () => {
  const pdf = await PDFDocument.load(
    await generatePartnerCertificate({
      ...fixture,
      approvedDocumentTypes: ["photo"],
    }),
  );
  const drawing = content(pdf);
  assert(drawing.includes(asciiHex("Profile photograph")));
  assert(!drawing.includes(asciiHex("Police clearance document")));
  const printedText = [...drawing.matchAll(/<([0-9A-F]+)> Tj/g)].map((match) =>
    new TextDecoder().decode(
      Uint8Array.from(match[1].match(/../g)!, (byte) => parseInt(byte, 16)),
    )
  ).join(" ");
  assert(
    printedText.includes(
      "It is not a government identity document, trade qualification or professional licence.",
    ),
  );
});
for (
  const [label, changes] of [
    ["empty name", { fullName: "  " }],
    ["oversized name", { fullName: "a".repeat(161) }],
    ["no reviewed evidence", { approvedDocumentTypes: [] }],
    ["invented qualification", {
      approvedDocumentTypes: ["professional_licence"],
    }],
    ["invalid issue date", { issuedAt: "not-a-date" }],
    ["unsupported characters", { fullName: "漢字" }],
  ] as [string, Partial<PartnerCertificateSnapshot>][]
) {
  Deno.test(`partner certificate rejects ${label} explicitly`, async () => {
    let error: unknown;
    try {
      await generatePartnerCertificate({ ...fixture, ...changes });
    } catch (caught) {
      error = caught;
    }
    assert(
      error instanceof Error && error.message.startsWith("CERTIFICATE_"),
      String(error),
    );
  });
}

Deno.test("certificate shaping buffer releases native storage exactly once", () => {
  const buffer = new Buffer(undefined);
  buffer.addText("നിമൽ", 0, "നിമൽ".length);
  assert(buffer.ptr !== 0);
  releaseBuffer(buffer);
  assert(buffer.ptr === 0);
  releaseBuffer(buffer);
  const next = new Buffer(undefined);
  next.addText("അരുൺ", 0, "അരുൺ".length);
  assert(next.ptr !== 0);
  releaseBuffer(next);
});
