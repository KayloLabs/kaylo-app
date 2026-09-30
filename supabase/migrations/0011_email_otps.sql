-- ============================================================
-- Kaylo: sign-in codes sent by email (the email-otp Edge Function).
-- One live code per address; only the server touches this table.
-- Safe to run more than once.
-- ============================================================

create table if not exists email_otps (
  email text primary key,
  code_hash text not null,
  expires_at timestamptz not null,
  attempts int not null default 0,
  sent_at timestamptz not null default now()
);

alter table email_otps enable row level security;
-- No policies on purpose: the app never reads or writes codes. The
-- functions use the service role, which bypasses row-level security.
revoke all on email_otps from public, anon, authenticated;
