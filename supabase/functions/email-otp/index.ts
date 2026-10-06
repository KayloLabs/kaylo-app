// Sign-in codes by email, with the session still issued by Firebase.
//
// POST { action: "send", email, purpose: "signin" | "signup", name?, phone? }
//   Signing in needs an existing account; signing up needs a new email.
//   Then a six-digit code that lasts ten minutes is emailed. One code per
//   address at a time; a new one may be requested after 30 seconds.
// POST { action: "verify", email, code, purpose, name? }
//   Checks the code (five attempts, then a new code is needed), finds the
//   Firebase user for that email (creating it for a sign-up), and returns
//   a custom token the app signs in with. The user then looks to the
//   rest of the app, and to Supabase, exactly like a Google sign-in.
import { corsHeaders, fail, json } from "../_shared/cors.ts";
import { serviceClient } from "../_shared/clients.ts";
import {
  brand,
  emailShell,
  escapeHtml,
  mailConfigured,
  sendMail,
} from "../_shared/mail.ts";
import {
  createUserWithEmail,
  findUserByEmail,
  firebaseAdminConfigured,
  mintCustomToken,
} from "../_shared/firebase_admin.ts";

const CODE_TTL_MINUTES = 10;
const RESEND_AFTER_SECONDS = 30;
const MAX_ATTEMPTS = 5;

type Purpose = "signin" | "signup";

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return fail(405, "method", "POST only");

  let body: {
    action?: string;
    email?: string;
    code?: string;
    name?: string;
    phone?: string;
    purpose?: string;
  };
  try {
    body = await request.json();
  } catch {
    return fail(400, "bad-request", "Send JSON");
  }
  const email = (body.email ?? "").trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return fail(400, "bad-email", "Enter a valid email address");
  }
  const purpose: Purpose = body.purpose === "signup" ? "signup" : "signin";
  const name = body.name?.trim() || undefined;

  const db = serviceClient();
  switch (body.action) {
    case "send":
      return await send(db, email, purpose, name);
    case "verify":
      return await verify(db, email, (body.code ?? "").trim(), purpose, name);
    default:
      return fail(400, "bad-request", "action must be send or verify");
  }
});

async function send(
  db: ReturnType<typeof serviceClient>,
  email: string,
  purpose: Purpose,
  name?: string,
) {
  if (!mailConfigured) {
    return fail(503, "not-configured", "Email sending is not set up");
  }
  if (!firebaseAdminConfigured) {
    return fail(503, "not-configured", "Firebase sign-in is not set up");
  }

  // Sign in only for accounts that exist; sign up only for new emails.
  const existing = await findUserByEmail(email);
  if (purpose === "signin" && !existing) {
    return fail(
      404,
      "no-account",
      "No account uses this email yet. Please sign up first.",
    );
  }
  if (purpose === "signup" && existing) {
    return fail(
      409,
      "already-registered",
      "This email already has an account. Please sign in.",
    );
  }

  const { data: row } = await db
    .from("email_otps")
    .select("sent_at")
    .eq("email", email)
    .maybeSingle();
  if (row) {
    const since = (Date.now() - new Date(row.sent_at as string).getTime()) /
      1000;
    if (since < RESEND_AFTER_SECONDS) {
      return fail(
        429,
        "too-soon",
        `Wait ${
          Math.ceil(RESEND_AFTER_SECONDS - since)
        } seconds before asking again`,
      );
    }
  }

  const code = String(crypto.getRandomValues(new Uint32Array(1))[0] % 1_000_000)
    .padStart(6, "0");
  const expiresAt = Date.now() + CODE_TTL_MINUTES * 60_000;
  const { error } = await db.from("email_otps").upsert({
    email,
    code_hash: await hash(email, code),
    expires_at: new Date(expiresAt).toISOString(),
    attempts: 0,
    sent_at: new Date().toISOString(),
  });
  if (error) return fail(500, "db", error.message);

  const copyPageUrl = Deno.env.get("OTP_COPY_PAGE_URL");
  let copyLink = "";
  if (copyPageUrl) {
    const url = new URL(copyPageUrl);
    if (url.protocol !== "https:") {
      throw new Error("OTP_COPY_PAGE_URL must use HTTPS");
    }
    url.hash = new URLSearchParams({
      code,
      expires: String(expiresAt),
    }).toString();
    copyLink = url.toString();
  }
  const greeting = name ? `Hi ${escapeHtml(name)}, ` : "";
  const what = purpose === "signup"
    ? "finish creating your Kaylo account"
    : "sign in to Kaylo";
  await sendMail({
    to: email,
    subject: `${code} is your Kaylo ${
      purpose === "signup" ? "sign-up" : "sign-in"
    } code`,
    text:
      `Your Kaylo code is ${code}. It expires in ${CODE_TTL_MINUTES} minutes. ` +
      (copyLink ? `Copy code in your browser: ${copyLink}\n` : "") +
      "If you did not ask for it, ignore this email.",
    html: emailShell(
      purpose === "signup" ? "Welcome to Kaylo" : "Your sign-in code",
      `<tr><td style="padding:10px 32px 0;font-size:15px;color:${brand.muted};line-height:1.6;">${greeting}enter this code in the app to ${what}.</td></tr>
       <tr><td align="center" style="padding:22px 32px;">
         <div style="display:inline-block;font-size:36px;letter-spacing:4px;font-weight:700;color:${brand.ink};background:${brand.tint};border-radius:16px;padding:16px 24px;user-select:all;-webkit-user-select:all;">${code}</div>
       </td></tr>
       <tr><td align="center" style="padding:0 32px 20px;font-size:13px;color:${brand.muted};line-height:1.6;">${
        copyLink
          ? `<div style="margin-top:16px;"><a href="${
            escapeHtml(copyLink)
          }" style="display:inline-block;background:${brand.green};color:#FFFFFF;text-decoration:none;padding:12px 24px;border-radius:12px;font-size:15px;font-weight:700;">Copy OTP in browser</a></div>`
          : ""
      }</td></tr>
       <tr><td style="padding:0 32px 30px;font-size:13px;color:${brand.muted};line-height:1.6;">
         The code expires in ${CODE_TTL_MINUTES} minutes. If you did not ask for it, you can ignore this email; nothing happens without the code.
       </td></tr>`,
    ),
  });
  return json({ ok: true, expires_in_minutes: CODE_TTL_MINUTES });
}

async function verify(
  db: ReturnType<typeof serviceClient>,
  email: string,
  code: string,
  purpose: Purpose,
  name?: string,
) {
  if (!firebaseAdminConfigured) {
    return fail(503, "not-configured", "Firebase sign-in is not set up");
  }
  if (!/^\d{6}$/.test(code)) {
    return fail(400, "bad-code", "Enter the 6-digit code");
  }

  const { data: row } = await db
    .from("email_otps")
    .select("code_hash, expires_at, attempts")
    .eq("email", email)
    .maybeSingle();
  if (!row) return fail(400, "no-code", "Ask for a new code first");
  if (new Date(row.expires_at as string).getTime() < Date.now()) {
    await db.from("email_otps").delete().eq("email", email);
    return fail(400, "expired", "That code has expired. Ask for a new one");
  }
  if ((row.attempts as number) >= MAX_ATTEMPTS) {
    await db.from("email_otps").delete().eq("email", email);
    return fail(429, "too-many-attempts", "Too many tries. Ask for a new code");
  }
  if (row.code_hash !== await hash(email, code)) {
    await db.from("email_otps").update({
      attempts: (row.attempts as number) + 1,
    }).eq("email", email);
    return fail(400, "wrong-code", "That code is not right");
  }

  await db.from("email_otps").delete().eq("email", email);
  let uid = await findUserByEmail(email);
  if (!uid) {
    if (purpose === "signin") {
      return fail(
        404,
        "no-account",
        "No account uses this email yet. Please sign up first.",
      );
    }
    uid = await createUserWithEmail(email, name);
  }
  const token = await mintCustomToken(uid);
  return json({ ok: true, token });
}

async function hash(email: string, code: string): Promise<string> {
  const bytes = new TextEncoder().encode(`${email}:${code}`);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((b) =>
    b.toString(16).padStart(2, "0")
  ).join("");
}
