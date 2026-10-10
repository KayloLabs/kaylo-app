export type ApplicationNotificationClaim =
  | { state: "not_required" | "sent" | "busy" }
  | { state: "claimed"; claim_id: string; reference: string };

/** The database lease coordinates upload retries and concurrent completions.
 * A failed send stays retryable; only SMTP success may be acknowledged as sent.
 */
export async function notifyApplicationForReview(deps: {
  claim: () => Promise<ApplicationNotificationClaim>;
  send: (reference: string) => Promise<void>;
  finish: (claimId: string, sent: boolean) => Promise<boolean>;
}): Promise<void> {
  const claim = await deps.claim();
  if (claim.state === "not_required" || claim.state === "sent") return;
  if (claim.state !== "claimed") throw new Error("NOTIFICATION_PENDING");
  try {
    if (!/^KA-[A-F0-9]{24}$/.test(claim.reference)) {
      throw new Error("INVALID_APPLICATION_REFERENCE");
    }
    await deps.send(claim.reference);
    if (!await deps.finish(claim.claim_id, true)) {
      throw new Error("NOTIFICATION_ACKNOWLEDGEMENT_FAILED");
    }
  } catch (error) {
    // A lost acknowledgement can cause another email on retry. The unique
    // reference identifies the same application; SMTP is not transactional.
    await deps.finish(claim.claim_id, false).catch(() => false);
    throw error;
  }
}
