// The invoice email after a verified payment: Kaylo's green header with
// the logo, the details, the total, and the faded mark as a watermark.
import {
  brand,
  detailRow,
  emailShell,
  formatRupees,
  mailConfigured,
  sendMail,
} from "./mail.ts";
import type { MailAttachment } from "./mail.ts";
import { buildInvoicePdf } from "./invoice_pdf.ts";

export const invoiceEmailConfigured = mailConfigured;

export interface InvoiceDetails {
  invoiceNumber: string;
  issuedAt: Date;
  customerName: string;
  customerEmail: string;
  customerPhone?: string;
  serviceName: string;
  scheduledOn: string;
  address?: string;
  amountRupees: number;
  paymentId: string;
  paymentMethod?: string;
  bookingId: string;
}

export function invoiceHtml(d: InvoiceDetails): string {
  const issued = d.issuedAt.toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "Asia/Kolkata",
  });
  const method = d.paymentMethod
    ? d.paymentMethod.replace(/^razorpay:/, "").toUpperCase()
    : "Online";
  const body = `
      <tr><td style="padding:14px 32px 0;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
          ${detailRow("Invoice number", d.invoiceNumber, { strong: true })}
          ${detailRow("Issued on", issued)}
          ${detailRow("Billed to", d.customerName)}
          ${d.customerPhone ? detailRow("Phone", d.customerPhone) : ""}
          ${detailRow("Service", d.serviceName)}
          ${detailRow("Scheduled for", d.scheduledOn)}
          ${d.address ? detailRow("Address", d.address) : ""}
          ${detailRow("Paid by", method)}
          ${detailRow("Payment ID", d.paymentId)}
        </table>
      </td></tr>
      <tr><td style="padding:22px 32px 6px;">
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:${brand.tint};border-radius:16px;">
          <tr>
            <td style="padding:16px 20px;font-size:15px;font-weight:700;color:${brand.ink};">Total paid</td>
            <td align="right" style="padding:16px 20px;font-size:24px;font-weight:700;color:${brand.green};">${
    formatRupees(d.amountRupees)
  }</td>
          </tr>
        </table>
      </td></tr>
      <tr><td style="padding:18px 32px 30px;font-size:12px;color:${brand.muted};line-height:1.7;">
        Booking reference ${d.bookingId}.<br>
        The PDF copy of this invoice is attached. This is a computer-generated invoice for a payment made in the Kaylo app; no signature is required.
      </td></tr>`;
  return emailShell("Payment received", body, {
    subtitle: `Thank you, ${d.customerName}. Here is your invoice.`,
    watermark: true,
  });
}

/// Returns true when the mail was handed to Gmail. The PDF copy is
/// attached when it can be built; the email goes out either way.
export async function sendInvoiceEmail(d: InvoiceDetails): Promise<boolean> {
  if (!invoiceEmailConfigured) return false;
  const attachments: MailAttachment[] = [];
  try {
    attachments.push({
      filename: `Kaylo-invoice-${d.invoiceNumber}.pdf`,
      contentType: "application/pdf",
      bytes: await buildInvoicePdf(d),
    });
  } catch (e) {
    console.error("invoice pdf failed:", (e as Error).message);
  }
  await sendMail({
    to: d.customerEmail,
    subject: `Kaylo invoice ${d.invoiceNumber}: ${d.serviceName}`,
    text:
      `Payment received. Invoice ${d.invoiceNumber} for ${d.serviceName}, ` +
      `${
        formatRupees(d.amountRupees)
      }, payment ${d.paymentId}. The PDF copy is attached.`,
    html: invoiceHtml(d),
    attachments,
  });
  return true;
}
