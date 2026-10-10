// The small part of the Firebase Admin SDK we need, done with plain
// JWTs and REST: mint a custom sign-in token, and find or create the
// Firebase user for an email address. Needs the project's service
// account key, stored base64-encoded as FIREBASE_SERVICE_ACCOUNT_B64.
import { importPKCS8, SignJWT } from "npm:jose@5";

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  private_key_id?: string;
}

let account: ServiceAccount | null = null;
function serviceAccount(): ServiceAccount {
  if (account) return account;
  const b64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64") ?? "";
  if (!b64) throw new Error("FIREBASE_SERVICE_ACCOUNT_B64 is not set");
  account = JSON.parse(new TextDecoder().decode(
    Uint8Array.from(atob(b64.replace(/\s/g, "")), (c) => c.charCodeAt(0)),
  ));
  return account!;
}

export const firebaseAdminConfigured =
  (Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64") ?? "") !== "";

async function signingKey() {
  return await importPKCS8(serviceAccount().private_key, "RS256");
}

/// A token the app exchanges with signInWithCustomToken. Valid for an
/// hour; Firebase issues its own session from it.
export async function mintCustomToken(uid: string): Promise<string> {
  const sa = serviceAccount();
  return await new SignJWT({ uid })
    .setProtectedHeader({ alg: "RS256", typ: "JWT", kid: sa.private_key_id })
    .setIssuer(sa.client_email)
    .setSubject(sa.client_email)
    .setAudience(
      "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
    )
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(await signingKey());
}

/// An OAuth access token for the Identity Toolkit admin API.
async function adminAccessToken(): Promise<string> {
  const sa = serviceAccount();
  const assertion = await new SignJWT({
    scope:
      "https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/firebase https://www.googleapis.com/auth/firebase.messaging",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt()
    .setExpirationTime("10m")
    .sign(await signingKey());
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`Google token exchange failed (${res.status})`);
  return (await res.json()).access_token as string;
}

async function adminHeaders() {
  const token = await adminAccessToken();
  return {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  };
}

function accountsBase(): string {
  return `https://identitytoolkit.googleapis.com/v1/projects/${serviceAccount().project_id}`;
}

/// The Firebase uid for an email, or null when no account has it.
export async function findUserByEmail(email: string): Promise<string | null> {
  const res = await fetch(`${accountsBase()}/accounts:lookup`, {
    method: "POST",
    headers: await adminHeaders(),
    body: JSON.stringify({ email: [email] }),
  });
  if (!res.ok) throw new Error(`Firebase user lookup failed (${res.status})`);
  const users = (await res.json()).users as { localId: string }[] | undefined;
  return users && users.length > 0 ? users[0].localId : null;
}

/// A new account with the email marked verified, since the code proved it.
export async function createUserWithEmail(
  email: string,
  displayName?: string,
): Promise<string> {
  const res = await fetch(`${accountsBase()}/accounts`, {
    method: "POST",
    headers: await adminHeaders(),
    body: JSON.stringify({
      email,
      emailVerified: true,
      ...(displayName ? { displayName } : {}),
    }),
  });
  if (!res.ok) {
    throw new Error(
      `Firebase user creation failed (${res.status}): ${await res.text()}`,
    );
  }
  return (await res.json()).localId as string;
}

export async function deleteFirebaseUser(uid: string): Promise<void> {
  const res = await fetch(`${accountsBase()}/accounts:delete`, {
    method: "POST", headers: await adminHeaders(),
    body: JSON.stringify({ localId: uid }),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    if (body?.error?.message === "USER_NOT_FOUND") return;
    throw new Error(`Firebase account deletion failed (${res.status})`);
  }
}

export async function sendCareCallPush(token: string, callId: string, name: string): Promise<boolean> {
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${serviceAccount().project_id}/messages:send`, {
    method: "POST", headers: await adminHeaders(),
    body: JSON.stringify({ message: {
      token, notification: { title: "Kaylo SOS", body: `${name} needs help. Open Kaylo to join the call.` },
      data: { type: "care_call", call_id: callId },
      android: { priority: "high", ttl: "120s", notification: { channel_id: "kaylo_sos", sound: "default", tag: `care_call_${callId}` } },
      apns: { payload: { aps: { sound: "default" } } },
    } }),
  });
  return res.ok;
}

export function firebaseProjectId(): string { return serviceAccount().project_id; }

// Partner identities use deterministic admin-owned UIDs, never an existing
// customer account found only by an email address.
export interface FirebaseAccountRecord {
  localId: string; email?: string; disabled?: boolean;
  passwordUpdatedAt?: number; validSince?: string; customAttributes?: string;
}
export async function lookupFirebaseAccount(uid: string): Promise<FirebaseAccountRecord | null> {
  const res = await fetch(`${accountsBase()}/accounts:lookup`, {
    method: "POST", headers: await adminHeaders(), body: JSON.stringify({ localId: [uid] }),
  });
  if (!res.ok) throw new Error(`Firebase account lookup failed (${res.status})`);
  return ((await res.json()).users ?? [])[0] ?? null;
}
export async function issueFirebasePartnerPassword(uid: string, partnerId: string, password: string, name: string, issuanceId: string): Promise<number> {
  const email = `${partnerId.toLowerCase()}@partners.kaylo.app`;
  const existing = await lookupFirebaseAccount(uid);
  const emailOwner = await findUserByEmail(email);
  if (emailOwner && emailOwner !== uid) throw new Error("PARTNER_EMAIL_ALREADY_CLAIMED");
  if (existing && existing.email !== email) throw new Error("PARTNER_IDENTITY_MISMATCH");
  const res = await fetch(`${accountsBase()}/${existing ? "accounts:update" : "accounts"}`, {
    method: "POST", headers: await adminHeaders(),
    body: JSON.stringify({localId: uid, email, password, displayName: name,
      emailVerified: true, disableUser: false,
      customAttributes: JSON.stringify({kaylo_role: "worker", kaylo_partner_id: partnerId, kaylo_issuance_id: issuanceId}),
      ...(existing ? {validSince: String(Math.floor(Date.now()/1000))} : {}),
    }),
  });
  // Never echo Firebase's response: it can contain authentication material.
  if (!res.ok) throw new Error(`Firebase partner update failed (${res.status})`);
  const account = await lookupFirebaseAccount(uid);
  const changed = Number(account?.passwordUpdatedAt);
  if (!Number.isFinite(changed) || changed <= 0) throw new Error("PASSWORD_TIMESTAMP_UNAVAILABLE");
  return changed;
}
