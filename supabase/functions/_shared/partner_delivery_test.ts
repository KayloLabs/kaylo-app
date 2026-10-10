import {
  type ApplicationMail,
  deliverApproval,
  dispatchClaimedMail,
} from "./partner_delivery.ts";
const mail: ApplicationMail = {
  mail_id: "mail",
  claim_id: "claim",
  application_id: "app",
  application_version: 4,
  kind: "approved",
  recipient_email: "recipient@example.test",
  template_data: {},
};
function assert(value: boolean) {
  if (!value) throw new Error("assertion failed");
}
Deno.test("SMTP failure remains pending and never acknowledges successful delivery", async () => {
  const acknowledgements: boolean[] = [];
  const sent = await dispatchClaimedMail(mail, {
    send: () => Promise.reject(new Error("SMTP")),
    finish: (value) => {
      acknowledgements.push(value);
      return Promise.resolve(true);
    },
  });
  assert(
    !sent && acknowledgements.length === 1 && acknowledgements[0] === false,
  );
});
Deno.test("lost outbox acknowledgement remains retryable without false success", async () => {
  let deliveries = 0;
  const sent = await dispatchClaimedMail(mail, {
    send: () => {
      deliveries++;
      return Promise.resolve();
    },
    finish: () => Promise.resolve(false),
  });
  assert(!sent && deliveries === 1);
});
Deno.test("already delivered credentials retry sends certificate with existing partner ID", async () => {
  let issues = 0;
  const certificates: string[] = [];
  await deliverApproval({
    issue: () => {
      issues++;
      return Promise.resolve({ already_issued: true, partner_id: "KP-000123" });
    },
    sendCertificate: (id) => {
      certificates.push(id);
      return Promise.resolve();
    },
  });
  assert(issues === 1 && certificates.join() === "KP-000123");
});
Deno.test("new approval sends credentials and attachment once, without duplicate certificate email", async () => {
  await deliverApproval({
    issue: () =>
      Promise.resolve({ already_issued: false, partner_id: "KP-000123" }),
    sendCertificate: () => Promise.reject(new Error("duplicate certificate")),
  });
});
