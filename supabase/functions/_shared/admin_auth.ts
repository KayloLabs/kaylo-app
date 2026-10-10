import { verifyFirebaseToken } from "./firebase_verify.ts";

export interface AdminActor {
  firebase_uid: string;
  email: string;
  role: "admin" | "reviewer";
  is_active: boolean;
}
export class AdminAuthError extends Error {
  constructor(public status: number, public code: string) {
    super(code);
  }
}

/** Every request verifies Google's signature, then the current database allowlist. */
export async function authenticateAdmin(
  request: Request,
  deps: {
    projectId: string;
    lookup: (uid: string) => Promise<AdminActor | null>;
    verify?: typeof verifyFirebaseToken;
    checkSession: (uid: string, token: string) => Promise<boolean>;
  },
): Promise<AdminActor> {
  const authorization = request.headers.get("authorization") ?? "";
  const match = /^Bearer ([^\s]+)$/i.exec(authorization);
  if (!match) throw new AdminAuthError(401, "SIGN_IN_REQUIRED");
  let uid: string;
  try {
    uid = await (deps.verify ?? verifyFirebaseToken)(match[1], deps.projectId);
  } catch {
    throw new AdminAuthError(401, "SIGN_IN_REQUIRED");
  }
  try {
    if (!await deps.checkSession(uid, match[1])) {
      throw new Error("SESSION_REVOKED");
    }
  } catch {
    throw new AdminAuthError(401, "SIGN_IN_REQUIRED");
  }
  let actor: AdminActor | null;
  try {
    actor = await deps.lookup(uid);
  } catch {
    throw new AdminAuthError(503, "ADMIN_ACCESS_UNAVAILABLE");
  }
  if (
    !actor || actor.firebase_uid !== uid || !actor.is_active ||
    !["admin", "reviewer"].includes(actor.role)
  ) {
    throw new AdminAuthError(403, "ADMIN_ACCESS_REQUIRED");
  }
  return actor;
}

export function assertAdminDecision(actor: AdminActor, decision: string): void {
  if (!["approve", "reject", "request_changes"].includes(decision)) {
    throw new AdminAuthError(400, "INVALID_DECISION");
  }
  if (decision !== "request_changes" && actor.role !== "admin") {
    throw new AdminAuthError(403, "ADMIN_ROLE_REQUIRED");
  }
}

/** Call only after signature/project verification. Refreshing an old session
 * changes iat, but never its original authentication/revocation boundary. */
export function adminFirebaseSessionIsCurrent(
  claims: Record<string, unknown>,
  account: { disabled?: boolean; validSince?: string } | null,
): boolean {
  if (!account || account.disabled) return false;
  const provider = (claims.firebase as Record<string, unknown> | undefined)
    ?.sign_in_provider;
  const authTime = claims.auth_time;
  const validSince = Number(account.validSince ?? 0);
  return provider === "password" && typeof authTime === "number" &&
    Number.isFinite(authTime) &&
    Number.isFinite(validSince) && authTime >= validSince;
}
