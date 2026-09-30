// Outgoing email through a Gmail account with an app password. Gmail
// needs no domain of our own, and Supabase functions reach its secure
// port (465); the usual mail ports are blocked there.
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const gmailUser = Deno.env.get("GMAIL_USER") ?? "";
const gmailAppPassword = Deno.env.get("GMAIL_APP_PASSWORD") ?? "";
const fromName = Deno.env.get("INVOICE_FROM_NAME") ?? "Kaylo";

export const mailConfigured = gmailUser !== "" && gmailAppPassword !== "";

/// Brand images, served from the project's public "assets" bucket so
/// every mail client can load them (Gmail drops embedded images).
const assets = `${
  Deno.env.get("SUPABASE_URL")
}/storage/v1/object/public/assets/email`;
export const logoWhiteUrl = `${assets}/logo_white.png`;
export const logoDarkUrl = `${assets}/logo_dark.png`;
export const watermarkUrl = `${assets}/watermark.png`;

export const brand = {
  green: "#2F7A4F",
  greenDark: "#1F5638",
  ink: "#16211B",
  muted: "#5C6B62",
  border: "#E2E8E1",
  ground: "#F7F9F6",
  tint: "#EFF3EE",
  sage: "#8E9E8A",
};

export interface MailAttachment {
  filename: string;
  contentType: string;
  bytes: Uint8Array;
}

/// Base64 in 76-column lines, the form MIME wants.
function mimeBase64(bytes: Uint8Array): string {
  let binary = "";
  for (let i = 0; i < bytes.length; i += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
  }
  return btoa(binary).replace(/(.{76})/g, "$1\r\n");
}

export async function sendMail(args: {
  to: string;
  subject: string;
  text: string;
  html: string;
  attachments?: MailAttachment[];
}): Promise<void> {
  const client = new SMTPClient({
    connection: {
      hostname: "smtp.gmail.com",
      port: 465,
      tls: true,
      auth: { username: gmailUser, password: gmailAppPassword },
    },
  });
  const encoder = new TextEncoder();
  try {
    await client.send({
      from: `"${fromName}" <${gmailUser}>`,
      to: args.to,
      subject: args.subject,
      // Both parts base64: the library's quoted-printable encoder leaves
      // "=20" in the rendered mail wherever a line ends with a space.
      mimeContent: [
        {
          mimeType: 'text/plain; charset="utf-8"',
          content: mimeBase64(encoder.encode(args.text)),
          transferEncoding: "base64",
        },
        {
          mimeType: 'text/html; charset="utf-8"',
          content: mimeBase64(encoder.encode(args.html)),
          transferEncoding: "base64",
        },
      ],
      attachments: (args.attachments ?? []).map((a) => ({
        filename: a.filename,
        contentType: a.contentType,
        encoding: "base64" as const,
        content: mimeBase64(a.bytes),
      })),
    });
  } finally {
    await client.close();
  }
}

export function escapeHtml(text: string): string {
  return text.replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[
        c
      ]!,
  );
}

/// The shared frame of every Kaylo email: green header with the logo,
/// a white card, and (optionally) the faded mark behind the card's
/// content as a watermark.
export function emailShell(
  title: string,
  bodyHtml: string,
  options: { subtitle?: string; watermark?: boolean } = {},
): string {
  const bg = options.watermark
    ? `background="${watermarkUrl}" style="background:#FFFFFF url('${watermarkUrl}') no-repeat center 55%;background-size:420px;"`
    : `style="background:#FFFFFF;"`;
  return `<!doctype html>
<html><body style="margin:0;background:${brand.ground};font-family:-apple-system,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${brand.ground};padding:28px 0;">
<tr><td align="center">
<table role="presentation" width="560" cellpadding="0" cellspacing="0" style="max-width:560px;width:100%;border-radius:22px;overflow:hidden;box-shadow:0 8px 28px rgba(22,33,27,0.08);">
  <tr><td align="center" style="background:${brand.green};padding:30px 32px 26px;">
    <img src="${logoWhiteUrl}" width="132" alt="Kaylo" style="display:block;width:132px;height:auto;border:0;">
    <div style="font-size:13px;color:#DCE8DD;margin-top:12px;letter-spacing:0.2px;">Your home, farm and care companion</div>
  </td></tr>
  <tr><td ${bg}>
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
      <tr><td style="padding:30px 32px 6px;">
        <div style="font-size:22px;font-weight:700;color:${brand.ink};">${
    escapeHtml(title)
  }</div>
        ${
    options.subtitle
      ? `<div style="font-size:14px;color:${brand.muted};margin-top:6px;line-height:1.5;">${
        escapeHtml(options.subtitle)
      }</div>`
      : ""
  }
      </td></tr>
      ${bodyHtml}
    </table>
  </td></tr>
  <tr><td align="center" style="background:${brand.tint};padding:18px 32px;font-size:12px;color:${brand.muted};line-height:1.6;">
    Kaylo · Kannur, Kerala · <a href="mailto:${
    escapeHtml(gmailUser)
  }" style="color:${brand.green};text-decoration:none;">${
    escapeHtml(gmailUser)
  }</a>
  </td></tr>
</table>
</td></tr></table>
</body></html>`;
}

/// A label/value line for the detail tables.
export function detailRow(
  label: string,
  value: string,
  opts: { strong?: boolean } = {},
): string {
  const weight = opts.strong ? "700" : "400";
  return `<tr>
    <td style="padding:9px 0;font-size:14px;color:${brand.muted};border-bottom:1px solid ${brand.border};">${
    escapeHtml(label)
  }</td>
    <td align="right" style="padding:9px 0;font-size:14px;color:${brand.ink};font-weight:${weight};border-bottom:1px solid ${brand.border};">${
    escapeHtml(value)
  }</td>
  </tr>`;
}

/// Indian grouping: ₹1,23,456.00
export function formatRupees(amount: number): string {
  const [whole, frac] = amount.toFixed(2).split(".");
  const last3 = whole.slice(-3);
  const rest = whole.slice(0, -3);
  const grouped = rest
    ? rest.replace(/\B(?=(\d{2})+(?!\d))/g, ",") + "," + last3
    : last3;
  return `₹${grouped}.${frac}`;
}

/// "Sat, 4 Oct 2026, 10:00 AM" from a booking's date and time columns.
export function formatSchedule(date: string, time: string): string {
  const [h, m] = time.split(":").map(Number);
  const d = new Date(`${date}T00:00:00+05:30`);
  const day = d.toLocaleDateString("en-IN", {
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "Asia/Kolkata",
  });
  const hour12 = ((h + 11) % 12) + 1;
  return `${day}, ${hour12}:${String(m).padStart(2, "0")} ${
    h < 12 ? "AM" : "PM"
  }`;
}
