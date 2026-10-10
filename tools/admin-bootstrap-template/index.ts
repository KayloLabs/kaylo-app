// LOCAL TEMPLATE. Remove the temporary deployment and secret immediately after use.
import { createClient } from "npm:@supabase/supabase-js@2";
import { importPKCS8, SignJWT } from "npm:jose@5";
import {
  type FirebaseUser,
  handleBootstrap,
  targetEmail,
} from "./bootstrap.ts";
interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}
async function dependencies() {
  const encoded = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_B64") ?? "";
  const account = JSON.parse(
    new TextDecoder().decode(
      Uint8Array.from(
        atob(encoded.replace(/\s/g, "")),
        (c) => c.charCodeAt(0),
      ),
    ),
  ) as ServiceAccount;
  const jwt = await new SignJWT({
    scope:
      "https://www.googleapis.com/auth/identitytoolkit https://www.googleapis.com/auth/firebase",
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" }).setIssuer(
      account.client_email,
    ).setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt().setExpirationTime("5m").sign(
      await importPKCS8(account.private_key, "RS256"),
    );
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!tokenResponse.ok) throw new Error("GOOGLE_AUTH_FAILED");
  const accessToken = (await tokenResponse.json()).access_token;
  const base = "https://identitytoolkit.googleapis.com/v1/projects/" +
    encodeURIComponent(account.project_id);
  const google = async (path: string, body: unknown) => {
    const response = await fetch(base + path, {
      method: "POST",
      headers: {
        Authorization: "Bearer " + accessToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(body),
    });
    if (!response.ok) throw new Error("FIREBASE_REQUEST_FAILED");
    return await response.json();
  };
  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false } },
  );
  const registry = async (uid: string) => {
    const columns = "firebase_uid,email,role,is_active";
    const [byUid, byEmail] = await Promise.all([
      db.from("admin_users").select(columns).eq("firebase_uid",uid),
      db.from("admin_users").select(columns).ilike("email",targetEmail),
    ]);
    if (byUid.error || byEmail.error) throw new Error("ADMIN_REGISTRY_UNAVAILABLE");
    const data = [...(byUid.data??[]),...(byEmail.data??[])];
    if (
      (data ?? []).some((row) =>
        row.firebase_uid !== uid || row.email.toLowerCase() !== targetEmail ||
        row.role !== "admin" || row.is_active !== true
      )
    ) throw new Error("ADMIN_REGISTRY_CONFLICT");
    return data ?? [];
  };
  const findUser = async (): Promise<FirebaseUser | null> => {
    const body = await google("/accounts:lookup", { email: [targetEmail] });
    return (body.users ?? [])[0] ?? null;
  };
  return {
    secret: Deno.env.get("KAYLO_ADMIN_BOOTSTRAP_SECRET") ?? "",
    findUser,
    createUser: async (): Promise<FirebaseUser> => {
      try {
        const created = await google("/accounts", {
          email: targetEmail,
          emailVerified: false,
        });
        return { localId: created.localId, email: targetEmail };
      } catch (error) {
        const existing = await findUser();
        if (existing) return existing;
        throw error;
      }
    },
    checkRegistry: async (uid: string) => {
      await registry(uid);
    },
    ensureAdmin: async (uid: string) => {
      if ((await registry(uid)).length) return;
      const { error } = await db.from("admin_users").insert({
        firebase_uid: uid,
        email: targetEmail,
        role: "admin",
        is_active: true,
      });
      if (error && (await registry(uid)).length === 0) {
        throw new Error("ADMIN_REGISTRATION_FAILED");
      }
    },
    setupLink: async () => {
      // returnOobLink produces a link only. Firebase sends NO email.
      const body = await google("/accounts:sendOobCode", {
        requestType: "PASSWORD_RESET",
        email: targetEmail,
        returnOobLink: true,
        targetProjectId: account.project_id,
      });
      if (typeof body.oobLink !== "string") {
        throw new Error("SETUP_LINK_UNAVAILABLE");
      }
      return body.oobLink;
    },
  };
}
Deno.serve(async (request) => {
  const secret = Deno.env.get("KAYLO_ADMIN_BOOTSTRAP_SECRET") ?? "";
  let loaded: Awaited<ReturnType<typeof dependencies>> | undefined;
  const load = async () => loaded ??= await dependencies();
  return await handleBootstrap(request, {
    secret,
    findUser: async () => await (await load()).findUser(),
    createUser: async () => await (await load()).createUser(),
    checkRegistry: async (uid) => await (await load()).checkRegistry(uid),
    ensureAdmin: async (uid) => await (await load()).ensureAdmin(uid),
    setupLink: async () => await (await load()).setupLink(),
  });
});
