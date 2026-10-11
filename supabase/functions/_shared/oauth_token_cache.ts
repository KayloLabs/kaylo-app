/** Keeps only a service OAuth credential, never user roles or session validity. */
export function createOAuthTokenCache(
  load: () => Promise<{ accessToken: string; expiresIn: number }>,
  now: () => number = Date.now,
): () => Promise<string> {
  let cached: { token: string; expiresAt: number } | null = null;
  let pending: Promise<string> | null = null;
  return () => {
    if (cached && cached.expiresAt > now()) return Promise.resolve(cached.token);
    if (pending) return pending;
    // Start expiry at request time, not response time. Refresh one minute early,
    // and cap lifetime even if an upstream response reports a longer duration.
    const startedAt = now();
    pending = load().then(({ accessToken, expiresIn }) => {
      if (!accessToken) throw new Error("Google token exchange returned no token");
      const lifetime = Number.isFinite(expiresIn)
        ? Math.max(0, Math.min(expiresIn, 3600) - 60) * 1000
        : 0;
      cached = { token: accessToken, expiresAt: startedAt + lifetime };
      return accessToken;
    }).finally(() => { pending = null; });
    return pending;
  };
}
