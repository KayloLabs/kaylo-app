// Razorpay REST calls. The key secret lives only here, as a function
// secret; the app never sees it.

const keyId = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
const keySecret = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";

export const razorpayKeyId = keyId;
export const razorpayConfigured = keyId !== "" && keySecret !== "";

async function call(path: string, init: RequestInit = {}): Promise<Response> {
  const auth = btoa(`${keyId}:${keySecret}`);
  return await fetch(`https://api.razorpay.com/v1${path}`, {
    ...init,
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/json",
      ...(init.headers ?? {}),
    },
  });
}

export interface RazorpayOrder {
  id: string;
  amount: number;
  currency: string;
  receipt: string;
  status: string;
}

/// amountPaise is an integer number of paise (₹1 = 100).
export async function createOrder(args: {
  amountPaise: number;
  receipt: string;
  notes: Record<string, string>;
}): Promise<RazorpayOrder> {
  const res = await call("/orders", {
    method: "POST",
    body: JSON.stringify({
      amount: args.amountPaise,
      currency: "INR",
      receipt: args.receipt,
      notes: args.notes,
    }),
  });
  if (!res.ok) {
    throw new Error(
      `Razorpay order failed (${res.status}): ${await res.text()}`,
    );
  }
  return await res.json();
}

export interface RazorpayPayment {
  id: string;
  order_id: string;
  amount: number;
  status: "created" | "authorized" | "captured" | "refunded" | "failed";
  method?: string;
  email?: string;
  contact?: string;
}

export async function fetchPayment(
  paymentId: string,
): Promise<RazorpayPayment> {
  const res = await call(`/payments/${paymentId}`);
  if (!res.ok) {
    throw new Error(`Razorpay payment lookup failed (${res.status})`);
  }
  return await res.json();
}

/// Accounts without auto-capture leave payments "authorized"; capturing
/// settles them.
export async function capturePayment(
  paymentId: string,
  amountPaise: number,
): Promise<RazorpayPayment> {
  const res = await call(`/payments/${paymentId}/capture`, {
    method: "POST",
    body: JSON.stringify({ amount: amountPaise, currency: "INR" }),
  });
  if (!res.ok) {
    throw new Error(
      `Razorpay capture failed (${res.status}): ${await res.text()}`,
    );
  }
  return await res.json();
}

/// Checkout returns HMAC-SHA256(order_id + "|" + payment_id, key secret)
/// as a hex string; only a holder of the secret can produce it.
export async function signatureMatches(
  orderId: string,
  paymentId: string,
  signature: string,
): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(keySecret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${orderId}|${paymentId}`),
  );
  const expected = Array.from(new Uint8Array(mac))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return timingSafeEqual(expected, signature.trim().toLowerCase());
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}
