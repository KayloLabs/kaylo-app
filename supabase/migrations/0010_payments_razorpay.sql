-- ============================================================
-- Kaylo: online payments through Razorpay, verified server-side by
-- the create-order and verify-payment Edge Functions
-- (supabase/functions). Safe to run more than once.
--
-- payments (from the ERD) gains the gateway's order id, the invoice
-- number, the address the invoice went to and when. Rows are written
-- by the functions with the service role, so no new policies: customers
-- keep reading their own payments through "participants read payments".
-- ============================================================

alter table payments add column if not exists order_id text;
alter table payments add column if not exists invoice_number text;
alter table payments add column if not exists customer_email text;
alter table payments add column if not exists invoice_sent_at timestamptz;
alter table payments add column if not exists created_at timestamptz not null default now();

create unique index if not exists payments_order_id_idx
  on payments (order_id) where order_id is not null;
create unique index if not exists payments_invoice_number_idx
  on payments (invoice_number) where invoice_number is not null;
create index if not exists payments_booking_idx
  on payments (booking_id, created_at desc);

-- Invoice numbers: KAY-2026-00001, one sequence, never reused. Only the
-- server hands them out.
create sequence if not exists invoice_number_seq;

create or replace function next_invoice_number()
returns text
language sql volatile security definer set search_path = public as $$
  select 'KAY-' || to_char(now(), 'YYYY') || '-'
    || lpad(nextval('invoice_number_seq')::text, 5, '0');
$$;

revoke execute on function next_invoice_number() from public, anon, authenticated;
grant execute on function next_invoice_number() to service_role;
