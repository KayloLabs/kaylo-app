// The PDF copy of an invoice: A4, Kaylo's colours, logo top left, a
// faint mark as the watermark, and a PAID stamp. Built with pdf-lib,
// which runs anywhere JavaScript does. Standard PDF fonts have no
// rupee sign, so amounts are written as INR.
import {
  degrees,
  PDFDocument,
  PDFFont,
  PDFPage,
  rgb,
  StandardFonts,
} from "npm:pdf-lib@1.17.1";
import type { InvoiceDetails } from "./invoice.ts";
import { logoDarkUrl, watermarkUrl } from "./mail.ts";

const green = rgb(0x2f / 255, 0x7a / 255, 0x4f / 255);
const ink = rgb(0x16 / 255, 0x21 / 255, 0x1b / 255);
const muted = rgb(0x5c / 255, 0x6b / 255, 0x62 / 255);
const border = rgb(0xe2 / 255, 0xe8 / 255, 0xe1 / 255);
const tint = rgb(0xef / 255, 0xf3 / 255, 0xee / 255);

const A4 = { width: 595.28, height: 841.89 };
const margin = 48;

let cachedImages: { logo: Uint8Array; watermark: Uint8Array } | null = null;
async function images() {
  if (cachedImages) return cachedImages;
  const [logo, watermark] = await Promise.all([
    fetch(logoDarkUrl).then((r) => r.arrayBuffer()),
    fetch(watermarkUrl).then((r) => r.arrayBuffer()),
  ]);
  cachedImages = {
    logo: new Uint8Array(logo),
    watermark: new Uint8Array(watermark),
  };
  return cachedImages;
}

export function inr(amount: number): string {
  const [whole, frac] = amount.toFixed(2).split(".");
  const last3 = whole.slice(-3);
  const rest = whole.slice(0, -3);
  const grouped = rest
    ? rest.replace(/\B(?=(\d{2})+(?!\d))/g, ",") + "," + last3
    : last3;
  return `INR ${grouped}.${frac}`;
}

export async function buildInvoicePdf(d: InvoiceDetails): Promise<Uint8Array> {
  const pdf = await PDFDocument.create();
  pdf.setTitle(`Kaylo invoice ${d.invoiceNumber}`);
  pdf.setAuthor("Kaylo");
  pdf.setSubject(`Invoice for ${d.serviceName}`);
  const page = pdf.addPage([A4.width, A4.height]);
  const regular = await pdf.embedFont(StandardFonts.Helvetica);
  const bold = await pdf.embedFont(StandardFonts.HelveticaBold);

  // Watermark behind everything.
  try {
    const { logo, watermark } = await images();
    const wm = await pdf.embedPng(watermark);
    const wmSize = 360;
    page.drawImage(wm, {
      x: (A4.width - wmSize) / 2,
      y: (A4.height - wmSize) / 2 - 30,
      width: wmSize,
      height: wmSize,
    });
    const lg = await pdf.embedPng(logo);
    const logoW = 96;
    page.drawImage(lg, {
      x: margin,
      y: A4.height - margin - logoW * (lg.height / lg.width),
      width: logoW,
      height: logoW * (lg.height / lg.width),
    });
  } catch (_) {
    // Images are decoration; the invoice is still valid without them.
    text(page, "kaylo", margin, A4.height - margin - 24, bold, 26, green);
  }

  // Title block, right aligned.
  const right = A4.width - margin;
  textRight(page, "INVOICE", right, A4.height - margin - 22, bold, 26, ink);
  textRight(
    page,
    d.invoiceNumber,
    right,
    A4.height - margin - 44,
    regular,
    12,
    muted,
  );
  textRight(
    page,
    `Issued ${dateOnly(d.issuedAt)}`,
    right,
    A4.height - margin - 60,
    regular,
    11,
    muted,
  );

  let y = A4.height - margin - 110;
  rule(page, y);
  y -= 26;

  // Parties.
  text(page, "BILLED TO", margin, y, bold, 9, muted);
  text(page, "FROM", A4.width / 2 + 10, y, bold, 9, muted);
  y -= 16;
  text(page, d.customerName, margin, y, bold, 12, ink);
  text(page, "Kaylo", A4.width / 2 + 10, y, bold, 12, ink);
  y -= 15;
  text(page, d.customerEmail, margin, y, regular, 10.5, muted);
  text(
    page,
    "Home, farm and care services",
    A4.width / 2 + 10,
    y,
    regular,
    10.5,
    muted,
  );
  y -= 14;
  if (d.customerPhone) {
    text(page, d.customerPhone, margin, y, regular, 10.5, muted);
  }
  text(page, "kayloapp@gmail.com", A4.width / 2 + 10, y, regular, 10.5, muted);
  y -= 34;

  // Line items.
  const cols = { desc: margin, when: margin + 250, amount: right };
  page.drawRectangle({
    x: margin,
    y: y - 8,
    width: right - margin,
    height: 26,
    color: green,
  });
  text(page, "DESCRIPTION", cols.desc + 10, y, bold, 9, rgb(1, 1, 1));
  text(page, "SCHEDULED", cols.when, y, bold, 9, rgb(1, 1, 1));
  textRight(page, "AMOUNT", cols.amount - 10, y, bold, 9, rgb(1, 1, 1));
  y -= 30;
  text(page, d.serviceName, cols.desc + 10, y, bold, 11.5, ink);
  text(page, d.scheduledOn, cols.when, y, regular, 10.5, ink);
  textRight(page, inr(d.amountRupees), cols.amount - 10, y, regular, 11.5, ink);
  if (d.address) {
    y -= 15;
    text(
      page,
      wrap(d.address, regular, 10, 230),
      cols.desc + 10,
      y,
      regular,
      10,
      muted,
    );
  }
  y -= 22;
  rule(page, y);
  y -= 26;

  // Totals.
  const boxW = 230;
  page.drawRectangle({
    x: right - boxW,
    y: y - 40,
    width: boxW,
    height: 62,
    color: tint,
    borderColor: border,
    borderWidth: 0.5,
  });
  text(page, "Subtotal", right - boxW + 14, y, regular, 10.5, muted);
  textRight(page, inr(d.amountRupees), right - 14, y, regular, 10.5, ink);
  y -= 26;
  text(page, "Total paid", right - boxW + 14, y, bold, 12.5, ink);
  textRight(page, inr(d.amountRupees), right - 14, y, bold, 14, green);
  y -= 60;

  // Payment details.
  text(page, "PAYMENT", margin, y, bold, 9, muted);
  y -= 18;
  const method = d.paymentMethod
    ? d.paymentMethod.replace(/^razorpay:/, "").toUpperCase()
    : "ONLINE";
  const rows: [string, string][] = [
    ["Status", "Paid"],
    ["Method", `${method} via Razorpay`],
    ["Payment ID", d.paymentId],
    ["Paid on", dateTime(d.issuedAt)],
    ["Booking reference", d.bookingId],
  ];
  for (const [k, v] of rows) {
    text(page, k, margin, y, regular, 10.5, muted);
    text(page, v, margin + 130, y, regular, 10.5, ink);
    y -= 16;
  }

  // PAID stamp.
  const stampX = right - 120, stampY = y + 60;
  page.drawRectangle({
    x: stampX,
    y: stampY,
    width: 104,
    height: 38,
    borderColor: green,
    borderWidth: 2.5,
    rotate: degrees(-10),
    opacity: 0.9,
    borderOpacity: 0.9,
  });
  page.drawText("PAID", {
    x: stampX + 20,
    y: stampY + 8,
    size: 24,
    font: bold,
    color: green,
    rotate: degrees(-10),
    opacity: 0.9,
  });

  // Footer.
  rule(page, margin + 40);
  text(
    page,
    "This is a computer-generated invoice for a payment made in the Kaylo app and does not require a signature.",
    margin,
    margin + 24,
    regular,
    8.5,
    muted,
  );
  text(
    page,
    "Kaylo  ·  kayloapp@gmail.com",
    margin,
    margin + 10,
    regular,
    8.5,
    muted,
  );
  textRight(page, "Page 1 of 1", right, margin + 10, regular, 8.5, muted);

  return await pdf.save();
}

function text(
  page: PDFPage,
  s: string,
  x: number,
  y: number,
  font: PDFFont,
  size: number,
  color = ink,
) {
  page.drawText(sanitize(s), { x, y, size, font, color });
}

function textRight(
  page: PDFPage,
  s: string,
  rightX: number,
  y: number,
  font: PDFFont,
  size: number,
  color = ink,
) {
  const clean = sanitize(s);
  page.drawText(clean, {
    x: rightX - font.widthOfTextAtSize(clean, size),
    y,
    size,
    font,
    color,
  });
}

function rule(page: PDFPage, y: number) {
  page.drawLine({
    start: { x: margin, y },
    end: { x: A4.width - margin, y },
    thickness: 0.6,
    color: border,
  });
}

/// Standard fonts cover Latin-1 only; anything else becomes a dash so a
/// Malayalam address never breaks the PDF.
function sanitize(s: string): string {
  return s.replace(/[^\x20-\x7E -ÿ]/g, "-").replace(/\s+/g, " ").trim();
}

function wrap(
  s: string,
  font: PDFFont,
  size: number,
  maxWidth: number,
): string {
  const words = sanitize(s).split(" ");
  let line = "";
  for (const w of words) {
    const candidate = line ? `${line} ${w}` : w;
    if (font.widthOfTextAtSize(candidate, size) > maxWidth) {
      return line + " ...";
    }
    line = candidate;
  }
  return line;
}

function dateOnly(d: Date): string {
  return d.toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "Asia/Kolkata",
  });
}

function dateTime(d: Date): string {
  return d.toLocaleString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: "Asia/Kolkata",
  });
}
