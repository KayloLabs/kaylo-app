# Kaylo Partner administration

This guide covers native Kaylo Partner applications, document review, corrections,
approval certificates and email delivery. It supplements [BACKEND.md](../BACKEND.md).
All review actions use the server endpoints; the website never receives a Supabase
service key, Firebase service account, issuance secret or temporary worker password.

## Current portal and hosting

- Local admin preview: http://127.0.0.1:3100/admin/
- Existing website: https://kaylo-everyday.adinimal.chatgpt.site
- `KAYLO_PORTAL_URL` is intentionally unset while the portal remains local.
- Admin route: `/admin/`
- Applicant correction route: `/application/update/`

Backend activation is complete for this setup: migrations 0024 through 0027 and
the matching admin workflow endpoints are deployed. The first
`kayloapp@gmail.com` allowlist entry is active; its owner must finish the privately
provided Firebase password-setup link before signing in. The temporary bootstrap
function and secret have been removed. No setup link or password belongs in this
repository.

The hosted site currently has private owner access, and the new admin/correction
frontend is not yet published there. The local preview is for this computer.
The owner chose to keep this setup local. Correction email attempts therefore
remain retryable in the outbox instead of sending inaccessible links. Submission,
approval and rejection emails can still be delivered. Set `KAYLO_PORTAL_URL` only
after the correction page is hosted, then renew expired requests and retry delivery.
**Publish the correction page on an externally accessible HTTPS host before sending
real applicants correction requests.** A signed correction token cannot bypass the
host's private-site access screen. If the host changes, update `KAYLO_PORTAL_URL`
before sending new links. Public hosting of the page does not make applicant
records public: the correction endpoint still requires its signed capability and
the admin endpoint requires an allowlisted Firebase session.

## Install the backend

Existing projects must first have migrations through 0023. Apply these in order:

| Migration | Purpose |
| --- | --- |
| `0024_worker_applications.sql` | Public application intake, private uploads, review prerequisites |
| `0025_issued_partner_identities.sql` | Issued identities, role separation, password-change gate |
| `0026_worker_application_notifications.sql` | Legacy notification acknowledgement and lease compatibility |
| `0027_partner_admin_review.sql` | Admin roles, review versions, corrections, audit, certificates and durable outbox |

For a fresh database, `supabase/setup_all.sql` includes the migrations verbatim.
Deploy the matching functions after applying the SQL:

```sh
supabase functions deploy worker-application-documents --no-verify-jwt
supabase functions deploy issue-partner-credentials --no-verify-jwt
supabase functions deploy partner-password-changed --no-verify-jwt
supabase functions deploy admin-applications --no-verify-jwt
supabase functions deploy application-corrections --no-verify-jwt
supabase functions deploy email-otp --no-verify-jwt
```

The disabled Supabase gateway check accommodates Firebase authentication and
application capabilities. Each endpoint implements its own applicable verification:
Google-signed Firebase tokens and the live allowlist for admins, expiring application
upload tokens for intake, signed correction tokens for replacements, and the
server-only admin secret for support credential issuance.

Switch `worker-application-documents` to its current outbox implementation when
0027 is applied. Do not run the old 0026 notification sender alongside it.
Existing acknowledged registration messages are preserved by the compatibility
fields, so migration replay does not intentionally resend them.

### Server secrets

Configure secrets in Supabase, not frontend source or Git:

| Name | Use |
| --- | --- |
| `FIREBASE_SERVICE_ACCOUNT_B64` | Firebase user lookup, revocation checks and issued partner identities |
| `GMAIL_USER`, `GMAIL_APP_PASSWORD` | Shared Kaylo SMTP sender and app password |
| `KAYLO_PARTNER_ADMIN_SECRET` | At least 32 random characters; support issuance/reset endpoint only |
| `APPLICATION_CORRECTION_SECRET` | Independent secret of at least 32 random characters; signs correction links |
| `KAYLO_PORTAL_URL` | HTTPS origin hosting both portal routes; no credentials, query or fragment |
| `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` | Server database/storage access, normally supplied by Supabase |

Keep Firebase Email/Password sign-in enabled. Admin sessions must use its password
provider. Existing customer providers can remain enabled. Optional Twilio delivery
uses `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` and `TWILIO_FROM_NUMBER`; email is
the required credential channel.

The current submitted-application outbox addresses **kayloapp@gmail.com** directly.
`WORKER_APPLICATION_REVIEW_EMAIL`, used by the earlier sender, is not read by this
workflow. Changing the recipient requires a deliberate backend recipient change.
No second Gmail account is required.

### Public frontend configuration

The website reads `GET /api/kaylo-config`, backed by
`server/kaylo-public-config.json` in the website project. Its explicit fields are
`firebaseApiKey`, `supabaseUrl` and `supabaseAnonKey`. These are public client
configuration values, not service credentials. They must point to the same
Firebase/Supabase projects as the deployed functions. Follow the website project's
deployment process separately from the mobile repository.

## Give a person admin access

A Firebase account alone does not grant admin rights. Create or identify the
person's Firebase Email/Password account, then copy its exact **Firebase UID**
from Firebase Authentication. Add that UID through a trusted SQL editor:

```sql
insert into admin_users(firebase_uid, email, role, is_active)
values ('EXACT_FIREBASE_UID', 'kayloapp@gmail.com', 'admin', true);
```

Use the intended person's UID, never a guessed email match or a partner's synthetic
login. The email column is the operator label; authorization is bound to the
verified UID. There is no public admin sign-up or browser role editor.

The one-time first-admin helper is documented in
[tools/admin-bootstrap-template/README.md](../tools/admin-bootstrap-template/README.md).
It supports only `kayloapp@gmail.com`, refuses browser callers, and does not
overwrite existing passwords or reactivate disabled accounts. An authorized
operator may use it to prepare a private Firebase password-setup link, then must
remove the temporary function and bootstrap secret. Do not commit or share that
setup URL. The helper is outside routine function deployment.

| Permission | Reviewer | Admin |
| --- | --- | --- |
| List/search applications and read details | Yes | Yes |
| View current and previous documents and audit | Yes | Yes |
| Request or renew document corrections | Yes | Yes |
| Read an issued certificate | Yes | Yes |
| Approve or reject | No | Yes |
| Retry current application email delivery | No | Yes |

To suspend portal access, set `admin_users.is_active = false` for that UID.
The next request checks the allowlist again. Disabled or revoked Firebase sessions
are also refused. Managing allowlist entries remains a trusted operator operation.

## Review an application

1. Open the portal and sign in with the allowlisted email/password account.
   Filter by status or search the reference, applicant name or email.
2. Open an application and review its details, services, payout details and all
   five documents: photo, Aadhaar front, Aadhaar back, police certificate and selfie.
3. Open previews using the portal. Current and historical objects stay in the
   private `worker-documents` bucket. Preview links last 60 seconds, and each
   successful preview request records the actor in the audit timeline.
4. Choose **Approve**, **Reject** or **Request changes**. Approval requires all
   five document checks. Rejection and corrections require a meaningful reason;
   corrections also require selected document types.

Each page holds an application version. New evidence or another decision advances
that version. A decision using a stale version is refused; refresh, review the
latest evidence, and submit again. Do not bypass the conflict with a direct table
update or the old approval function.

Approval means the team actually reviewed the five supplied documents. It does
not claim automatic Aadhaar validation, police database checks, qualification
verification or a skills examination. The transaction creates the separate worker
identity and partner ID, marks the reviewed document records, snapshots the review
certificate and queues the approval email. It cannot approve the same application
twice. Rejection records its reason and queues an applicant notice without creating
a partner identity.

Use `admin_review_application` through the portal for routine decisions. Calling
the older `approve_worker_application` or `reject_worker_application` directly
bypasses the actor audit, certificate and outbox orchestration.

## Request and receive corrections

A change request sets `changes_requested`, records the reason and requested
document types, and expires the initial upload capability. Its applicant email
contains a signed seven-day link bound to that application and correction batch.
The token is placed in the URL fragment and is not stored as plaintext in the
database or outbox.

The applicant does not need an issued partner account. They can inspect the
requested document names/reasons and upload replacements for those types only.
The correction API does not disclose the full application or prior private files.
JPEG, PNG and PDF are accepted up to 10 MiB per file; photo and selfie must be
images. File signatures, capability expiry and database state are checked.

Each accepted replacement creates a new private object and retains the earlier
document path in history. When all requested replacements are received and all
five required documents exist, the application returns to `under_review` and
queues another admin review notice. Reviewers must assess the replacements before
approval.

If the link expires, use **Update change request** on the application. Select the
documents still needed and provide the updated reason. This creates a new batch,
expiry, email and audit event; the old link cannot read or upload for the new batch.
An incomplete application can also enter this flow, but every missing document
must be included in the request.

## Certificate and worker credentials

Approval stores an immutable `partner_certificates` snapshot with a unique
`KC-` reference, partner ID, name, profession, district, service details, approval
date and the document types checked. The PDF describes the actual application
review scope. It does not include Aadhaar scans/numbers, bank information,
the applicant's email or private admin notes.

The PDF is generated once under
`worker-documents/certificates/<certificate_id>.pdf`. The portal offers an
authenticated 60-second download link, and the approval email attaches the PDF.
A PDF-generation or SMTP failure leaves the approved decision intact and its
delivery retryable.

First approval delivery issues the partner's temporary password and sends it with
the certificate. The portal/outbox never stores or returns that password.
The worker must choose a new password in Kaylo Partner before accessing work.
A successfully delivered existing identity is reused on an approval-email retry;
that retry sends the certificate without rotating the worker's password.

Support-only forgotten-password reset remains at `issue-partner-credentials`
with the separate admin secret. It requires an actual support identity check and
forces a new password again. See [BACKEND.md](../BACKEND.md#support-password-reset-and-recovery).

## Email delivery and manual retry

The database records application messages transactionally in
`application_mail_outbox`. Upload completion and admin review immediately attempt
their queued delivery. The portal exposes message kind, recipient, state, attempt
count, error and sent time.

- `pending`: queued and available to send.
- `sending`: held by a sender with a five-minute lease.
- `failed`: attempted but needs retry.
- `sent`: SMTP acceptance and database acknowledgement recorded.

Open the affected application and use **Retry delivery** as an admin. An active
lease must finish or expire before a new sender can take it. There is **no scheduled
retry worker**; unresolved failures need this manual action. A failed email never
requires repeating approval or making the applicant reupload saved files.

For a trusted API client, POST to `/functions/v1/admin-applications` with the
admin's current Firebase ID token in `Authorization: Bearer ...`:

```json
{"action":"retry_delivery","application_id":"APPLICATION_UUID"}
```

Only messages still relevant to the current application state/batch are retried.
Older messages remain in delivery history with `is_current: false`.
SMTP and PostgreSQL are not one transaction: an accepted message whose acknowledgement
was lost can be duplicated on retry. A sent state is not a guarantee of inbox
placement. Check the delivery recipient and spam folder when appropriate.

## Data and audit

- `worker_applications`: current status, details, version and correction batch.
- `worker_application_documents`: current private document paths.
- `worker_application_document_history`: retained previous/current evidence versions.
- `worker_application_corrections`: requested types, reasons and receipt tracking.
- `worker_application_audit`: upload, review, preview and delivery events with actor
  metadata where applicable.
- `partner_certificates`: immutable approval snapshot.
- `application_mail_outbox`: durable message and delivery attempts.

Client roles cannot read these private tables or invoke service-only review RPCs.
The database prevents ordinary service clients from updating, deleting or truncating
immutable audit, document history and certificate records. Database owners still
administer the database; this is an application audit trail, not external tamper-proof
storage. Do not delete historical storage objects as routine cleanup.

## Website leads are a separate flow

The landing website's **Join as a Professional** form saves leads in that website's
D1 database. It is not the native partner application's Supabase registration.
A website lead does not automatically include the five documents, appear in this
review queue, create an issued partner ID or trigger this approval workflow.
Ask those prospects to complete the native Kaylo Partner application unless an
explicit future integration is built. Do not treat a marketing lead as an approved
worker.

## Verification and remaining operational checks

The local SQL suite covers role boundaries, stale reviews, scoped corrections,
expiry/renewal, immutable evidence, certificate creation and delivery leases/retries.
The complete setup bundle and 0027 replay were tested on isolated local PostgreSQL.
Deno tests use fakes for authentication and delivery; they do not send real mail.

Before inviting external applicants, confirm the public correction host works in
an unauthenticated browser, then exercise one consented application through upload,
request/correct, approval and first password change. Verify the delivered attachment
and an intentional delivery retry. Deployment, account activation and a live email
smoke test are separate from these local checks.
