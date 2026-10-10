import { notifyApplicationForReview } from "./worker_application_notification.ts";

const reference = "KA-0123456789ABCDEF01234567";
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}

Deno.test("incomplete and previously notified applications do not send mail", async () => {
  for (const state of ["not_required", "sent"] as const) {
    await notifyApplicationForReview({
      claim: () => Promise.resolve({ state }),
      send: () => Promise.reject(new Error("must not send")),
      finish: () => Promise.reject(new Error("must not acknowledge")),
    });
  }
});

Deno.test("a completed application is acknowledged only after mail delivery", async () => {
  const events: string[] = [];
  await notifyApplicationForReview({
    claim: () =>
      Promise.resolve({ state: "claimed", claim_id: "lease", reference }),
    send: (value) => {
      assert(value === reference);
      events.push("sent");
      return Promise.resolve();
    },
    finish: (id, sent) => {
      assert(id === "lease" && sent);
      assert(events.join() === "sent");
      events.push("acknowledged");
      return Promise.resolve(true);
    },
  });
  assert(events.join() === "sent,acknowledged");
});

Deno.test("SMTP failure releases the lease and remains a retryable failure", async () => {
  const acknowledgements: boolean[] = [];
  let failed = false;
  try {
    await notifyApplicationForReview({
      claim: () =>
        Promise.resolve({ state: "claimed", claim_id: "lease", reference }),
      send: () => Promise.reject(new Error("SMTP unavailable")),
      finish: (_, sent) => {
        acknowledgements.push(sent);
        return Promise.resolve(true);
      },
    });
  } catch {
    failed = true;
  }
  assert(failed && acknowledgements.length === 1 && !acknowledgements[0]);
});

Deno.test("an active sender prevents a concurrent email and requests retry", async () => {
  let failed = false;
  let sends = 0;
  let acknowledgements = 0;
  try {
    await notifyApplicationForReview({
      claim: () => Promise.resolve({ state: "busy" }),
      send: () => {
        sends++;
        return Promise.resolve();
      },
      finish: () => {
        acknowledgements++;
        return Promise.resolve(true);
      },
    });
  } catch {
    failed = true;
  }
  assert(failed && sends === 0 && acknowledgements === 0);
});

Deno.test("a lost delivery acknowledgement is not reported as successful", async () => {
  let failed = false;
  let sent = 0;
  try {
    await notifyApplicationForReview({
      claim: () =>
        Promise.resolve({ state: "claimed", claim_id: "lease", reference }),
      send: () => {
        sent++;
        return Promise.resolve();
      },
      finish: () => Promise.resolve(false),
    });
  } catch {
    failed = true;
  }
  assert(failed && sent === 1);
});

Deno.test("invalid reference content never reaches the mail sender", async () => {
  let sent = false;
  try {
    await notifyApplicationForReview({
      claim: () =>
        Promise.resolve({
          state: "claimed",
          claim_id: "lease",
          reference: "<script>",
        }),
      send: () => {
        sent = true;
        return Promise.resolve();
      },
      finish: () => Promise.resolve(true),
    });
  } catch { /* The retryable failure is expected. */ }
  assert(!sent);
});
