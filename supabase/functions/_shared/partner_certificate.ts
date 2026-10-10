// The immutable approval record attached to a Kaylo-issued partner account.
// Indic names are shaped into vector glyphs, with Unicode ActualText for copy
// and accessibility. No network fetches or platform fonts are needed at runtime.
import {
  PDFDocument,
  PDFFont,
  PDFHexString,
  PDFName,
  PDFOperator,
  PDFOperatorNames,
  PDFPage,
  rgb,
  StandardFonts,
} from "npm:pdf-lib@1.17.1";
import * as hb from "./partner_certificate_fonts/harfbuzz.mjs";
import {
  certificateFontData,
  kayloLogoPaths,
} from "./partner_certificate_assets.ts";

export interface PartnerCertificateSnapshot {
  certificateId: string;
  partnerId: string;
  fullName: string;
  profession: string;
  district: string;
  issuedAt: string;
  verificationReference: string;
  approvedDocumentTypes: string[];
}

const PAGE = { width: 595.28, height: 841.89 };
const INK = rgb(0.12, 0.18, 0.14);
const GREEN = rgb(0.17, 0.38, 0.26);
const MUTED = rgb(0.39, 0.43, 0.39);
const IVORY = rgb(0.985, 0.981, 0.957);
const BORDER = rgb(0.81, 0.85, 0.79);
const TINT = rgb(0.93, 0.95, 0.91);
const DOCUMENTS: Record<string, string> = {
  photo: "Profile photograph",
  aadhaar_front: "Aadhaar document - front",
  aadhaar_back: "Aadhaar document - back",
  police_certificate: "Police clearance document",
  selfie: "Selfie photograph",
};

type Glyph = { id: number; path: { toSVG(): string } };
type GlyphPosition = {
  xAdvance: number;
  yAdvance: number;
  xOffset: number;
  yOffset: number;
};
type ShapingFont = {
  unitsPerEm: number;
  layout(text: string): { glyphs: Glyph[]; positions: GlyphPosition[] };
};
type Script = keyof typeof certificateFontData;
type Run = { text: string; script: Script | null };
const fontCache = new Map<Script, ShapingFont>();
const graphemes = new Intl.Segmenter("en", { granularity: "grapheme" });

function fontFor(script: Script): ShapingFont {
  const cached = fontCache.get(script);
  if (cached) return cached;
  const bytes = Uint8Array.from(
    atob(certificateFontData[script]),
    (c) => c.charCodeAt(0),
  );
  const face = new hb.Face(new hb.Blob(bytes));
  const shaper = new hb.Font(face);
  const font: ShapingFont = {
    unitsPerEm: face.upem,
    layout(text: string) {
      const buffer = new hb.Buffer(undefined);
      try {
        buffer.addText(text, 0, text.length);
        buffer.guessSegmentProperties();
        hb.shape(shaper, buffer, undefined);
        return {
          glyphs: buffer.getGlyphInfos().map((info: { codepoint: number }) => ({
            id: info.codepoint,
            path: { toSVG: () => shaper.glyphToPath(info.codepoint) },
          })),
          positions: buffer.getGlyphPositions(),
        };
      } finally {
        hb.releaseBuffer(buffer);
      }
    },
  };
  fontCache.set(script, font);
  return font;
}

function clean(value: unknown, field: string, max: number): string {
  if (
    typeof value !== "string" ||
    /[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(value)
  ) {
    throw new Error(`CERTIFICATE_INVALID_${field}`);
  }
  const text = value.replace(/\s+/gu, " ").trim().normalize("NFC");
  if (!text || [...text].length > max) {
    throw new Error(`CERTIFICATE_INVALID_${field}`);
  }
  return text;
}

function runs(text: string): Run[] {
  const result: Run[] = [];
  for (const { segment } of graphemes.segment(text)) {
    const script: Script | null = /[\u0d00-\u0d7f]/u.test(segment)
      ? "malayalam"
      : /[\u0b80-\u0bff]/u.test(segment)
      ? "tamil"
      : /[\u0900-\u097f]/u.test(segment)
      ? "devanagari"
      : null;
    const last = result.at(-1);
    if (last?.script === script) last.text += segment;
    else result.push({ text: segment, script });
  }
  return result;
}

function shaped(run: Run) {
  const font = fontFor(run.script!);
  const layout = font.layout(run.text);
  if (layout.glyphs.some((glyph) => glyph.id === 0)) {
    throw new Error("CERTIFICATE_UNSUPPORTED_CHARACTER");
  }
  return { font, ...layout };
}

function width(text: string, font: PDFFont, size: number): number {
  return runs(text).reduce((total, run) => {
    if (!run.script) {
      try {
        return total + font.widthOfTextAtSize(run.text, size);
      } catch {
        throw new Error("CERTIFICATE_UNSUPPORTED_CHARACTER");
      }
    }
    const layout = shaped(run);
    return total +
      layout.positions.reduce((sum, position) => sum + position.xAdvance, 0) *
        size / layout.font.unitsPerEm;
  }, 0);
}

function lineWrap(
  text: string,
  font: PDFFont,
  size: number,
  maxWidth: number,
): string[] {
  const lines: string[] = [];
  let line = "";
  for (const word of text.split(" ")) {
    const candidate = line ? `${line} ${word}` : word;
    if (width(candidate, font, size) <= maxWidth) {
      line = candidate;
      continue;
    }
    if (line) {
      lines.push(line);
      line = "";
    }
    for (const { segment } of graphemes.segment(word)) {
      if (line && width(line + segment, font, size) > maxWidth) {
        lines.push(line);
        line = "";
      }
      line += segment;
    }
  }
  if (line) lines.push(line);
  return lines;
}

function fit(
  text: string,
  font: PDFFont,
  maxWidth: number,
  maxLines: number,
  initialSize: number,
  minSize: number,
): { lines: string[]; size: number } {
  for (let size = initialSize; size >= minSize; size -= 0.5) {
    const lines = lineWrap(text, font, size, maxWidth);
    if (lines.length <= maxLines) return { lines, size };
  }
  throw new Error("CERTIFICATE_TEXT_EXCEEDS_LAYOUT");
}

function drawText(
  pdf: PDFDocument,
  page: PDFPage,
  text: string,
  x: number,
  y: number,
  font: PDFFont,
  size: number,
  color = INK,
) {
  let cursor = x;
  for (const run of runs(text)) {
    if (!run.script) {
      page.drawText(run.text, { x: cursor, y, font, size, color });
      cursor += font.widthOfTextAtSize(run.text, size);
      continue;
    }
    const layout = shaped(run);
    const scale = size / layout.font.unitsPerEm;
    // Keep actual Unicode text even though glyph paths are outlined to preserve
    // Indic GSUB/GPOS positioning, which basic PDF text operators cannot do.
    page.pushOperators(
      PDFOperator.of(PDFOperatorNames.BeginMarkedContentSequence, [
        PDFName.of("Span"),
        pdf.context.obj({
          ActualText: PDFHexString.fromText(run.text),
        }).toString(),
      ]),
    );
    let advanceY = 0;
    for (let i = 0; i < layout.glyphs.length; i++) {
      const position = layout.positions[i];
      const path = layout.glyphs[i].path.toSVG();
      if (path) {
        // HarfBuzz outlines use y-up coordinates. SVG drawing uses y-down,
        // so negate the SVG y axis locally before pdf-lib's SVG transform.
        page.pushOperators(
          PDFOperator.of(PDFOperatorNames.PushGraphicsState),
          PDFOperator.of(PDFOperatorNames.ConcatTransformationMatrix, [
            pdf.context.obj(1),
            pdf.context.obj(0),
            pdf.context.obj(0),
            pdf.context.obj(-1),
            pdf.context.obj(0),
            pdf.context.obj(2 * (y + advanceY + position.yOffset * scale)),
          ]),
        );
        page.drawSvgPath(path, {
          x: cursor + position.xOffset * scale,
          y: y + advanceY + position.yOffset * scale,
          scale,
          color,
        });
        page.pushOperators(PDFOperator.of(PDFOperatorNames.PopGraphicsState));
      }
      cursor += position.xAdvance * scale;
      advanceY += position.yAdvance * scale;
    }
    page.pushOperators(PDFOperator.of(PDFOperatorNames.EndMarkedContent));
  }
}

export async function generatePartnerCertificate(
  snapshot: PartnerCertificateSnapshot,
): Promise<Uint8Array> {
  const certificateId = clean(snapshot.certificateId, "ID", 80);
  const partnerId = clean(snapshot.partnerId, "PARTNER_ID", 30);
  const name = clean(snapshot.fullName, "NAME", 160);
  const profession = clean(snapshot.profession, "PROFESSION", 120);
  const district = clean(snapshot.district, "DISTRICT", 100);
  const reference = clean(snapshot.verificationReference, "REFERENCE", 80);
  const issuedAt = new Date(clean(snapshot.issuedAt, "DATE", 80));
  if (!Number.isFinite(issuedAt.getTime())) {
    throw new Error("CERTIFICATE_INVALID_DATE");
  }
  if (
    !Array.isArray(snapshot.approvedDocumentTypes) ||
    !snapshot.approvedDocumentTypes.length ||
    snapshot.approvedDocumentTypes.some((type) =>
      !Object.hasOwn(DOCUMENTS, type)
    )
  ) {
    throw new Error("CERTIFICATE_INVALID_REVIEWED_DOCUMENTS");
  }
  const documents = [...new Set(snapshot.approvedDocumentTypes)];
  const issued = issuedAt.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    timeZone: "Asia/Kolkata",
  });
  const pdf = await PDFDocument.create();
  pdf.setTitle(`Kaylo Approved Partner - ${partnerId}`);
  pdf.setAuthor("Kaylo");
  pdf.setSubject(`Approval record for ${name}; certificate ${certificateId}`);
  pdf.setCreationDate(issuedAt);
  pdf.setModificationDate(issuedAt);
  const page = pdf.addPage([PAGE.width, PAGE.height]);
  const regular = await pdf.embedFont(StandardFonts.Helvetica);
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold);
  const draw = (
    text: string,
    x: number,
    y: number,
    size = 11,
    font = regular,
    color = INK,
  ) => drawText(pdf, page, text, x, y, font, size, color);
  const paragraph = (
    text: string,
    x: number,
    y: number,
    maxWidth: number,
    size: number,
    leading: number,
    color = MUTED,
  ) => {
    for (
      const [index, line] of lineWrap(text, regular, size, maxWidth).entries()
    ) draw(line, x, y - index * leading, size, regular, color);
  };
  page.drawRectangle({ x: 0, y: 0, ...PAGE, color: IVORY });
  page.drawRectangle({
    x: 32,
    y: 32,
    width: PAGE.width - 64,
    height: PAGE.height - 64,
    borderColor: BORDER,
    borderWidth: 0.75,
  });
  page.drawRectangle({
    x: 32,
    y: PAGE.height - 40,
    width: PAGE.width - 64,
    height: 8,
    color: GREEN,
  });
  const logoScale = 0.22;
  for (const path of kayloLogoPaths) {
    page.drawSvgPath(path, {
      x: 64 - 280 * logoScale,
      y: 776 + 330 * logoScale,
      scale: logoScale,
      color: GREEN,
    });
  }
  draw("PARTNER APPROVAL RECORD", 297, 760, 9, bold, GREEN);
  const idLayout = fit(certificateId, regular, 233, 2, 10, 8);
  idLayout.lines.forEach((line, i) =>
    draw(line, 297, 739 - i * 14, idLayout.size)
  );
  draw(issued, 297, 704, 10, regular, MUTED);
  page.drawLine({
    start: { x: 64, y: 684 },
    end: { x: PAGE.width - 64, y: 684 },
    color: BORDER,
    thickness: 0.8,
  });
  draw("Kaylo Approved Partner", 64, 648, 28, bold, GREEN);
  draw("HOME. FARM. CARE.", 64, 626, 9, regular, MUTED);
  draw("This records Kaylo's approval of", 64, 580, 12, regular, MUTED);
  const nameLayout = fit(name, regular, PAGE.width - 128, 3, 32, 12);
  nameLayout.lines.forEach((line, i) =>
    draw(line, 64, 545 - i * 37, nameLayout.size, regular, GREEN)
  );

  draw("PROFESSION", 64, 434, 8.5, bold, MUTED);
  draw("SERVICE DISTRICT", 309, 434, 8.5, bold, MUTED);
  for (
    const [text, x, maxWidth] of [[profession, 64, 220], [
      district,
      309,
      220,
    ]] as const
  ) {
    const layout = fit(text, regular, maxWidth, 3, 13, 9);
    layout.lines.forEach((line, i) => draw(line, x, 412 - i * 18, layout.size));
  }
  draw("PARTNER ID", 64, 348, 8.5, bold, MUTED);
  const partnerIdLayout = fit(partnerId, bold, 220, 1, 14, 8);
  draw(partnerIdLayout.lines[0], 64, 327, partnerIdLayout.size, bold, GREEN);
  draw("VERIFICATION REFERENCE", 309, 348, 8.5, bold, MUTED);
  const referenceLayout = fit(reference, regular, 220, 2, 10, 8);
  referenceLayout.lines.forEach((line, i) =>
    draw(line, 309, 329 - i * 14, referenceLayout.size)
  );

  page.drawRectangle({
    x: 64,
    y: 174,
    width: PAGE.width - 128,
    height: 116,
    color: TINT,
  });
  draw("APPLICATION EVIDENCE MARKED REVIEWED", 78, 271, 8.5, bold, GREEN);
  for (const [index, type] of documents.entries()) {
    const y = 249 - index * 15;
    page.drawCircle({ x: 82, y: y + 3, size: 2, color: GREEN });
    draw(DOCUMENTS[type], 93, y, 10);
  }
  draw("Issued by Kaylo", 64, 146, 11, bold, GREEN);
  draw("kayloapp@gmail.com", 64, 129, 9, regular, MUTED);
  paragraph(
    "This records platform approval on the issue date. It is not a government identity document, trade qualification or professional licence. Current eligibility is subject to Kaylo's records.",
    64,
    92,
    PAGE.width - 128,
    8.5,
    12,
  );
  return await pdf.save();
}
