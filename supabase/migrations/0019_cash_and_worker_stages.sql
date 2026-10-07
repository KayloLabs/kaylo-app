-- Cash payments and the worker's side of a job.
--
-- A booking now records how the customer pays (online through Razorpay, or
-- cash handed to the worker) and where the worker is in the job
-- (requested, accepted, on the way, arrived, in progress, completed,
-- cancelled). Cash bookings get a pending payment row at creation; the
-- worker's confirmation marks it paid and books Kaylo's commission as due
-- against the worker's payout account, which is settled from the next online
-- payout or by a direct payment. Customers rate a finished job through
-- submit_review. Workers get notifications for new requests, cancellations
-- and completions, and customers hear when the worker is on the way or has
-- arrived.
-- Run after 0018. Safe to run more than once.
begin;

-- 1. bookings: payment mode and worker stage ----------------------------
alter table bookings add column if not exists payment_mode text not null default 'online';
alter table bookings drop constraint if exists bookings_payment_mode_check;
alter table bookings add constraint bookings_payment_mode_check
  check (payment_mode in ('online', 'cash'));

alter table bookings add column if not exists worker_stage text not null default 'requested';
alter table bookings drop constraint if exists bookings_worker_stage_check;
alter table bookings add constraint bookings_worker_stage_check
  check (worker_stage in ('requested', 'accepted', 'on_the_way', 'arrived',
                          'in_progress', 'completed', 'cancelled'));

-- Rows from before this migration: read the stage off the status, once.
update bookings set worker_stage = case status
    when 'confirmed' then 'accepted'
    when 'in_progress' then 'in_progress'
    when 'completed' then 'completed'
    when 'cancelled' then 'cancelled'
    else 'requested' end
  where worker_stage = 'requested' and status <> 'pending';

-- The two columns tell one story: a stage change moves the status, a status
-- change (customer cancels, payment confirms) moves the stage.
create or replace function sync_booking_stage_and_status()
returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.worker_stage is distinct from old.worker_stage then
    new.status := case new.worker_stage
      when 'accepted' then 'confirmed'::booking_status
      when 'on_the_way' then 'confirmed'::booking_status
      when 'arrived' then 'confirmed'::booking_status
      when 'in_progress' then 'in_progress'::booking_status
      when 'completed' then 'completed'::booking_status
      when 'cancelled' then 'cancelled'::booking_status
      else new.status end;
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    new.worker_stage := case new.status
      when 'cancelled' then 'cancelled'
      when 'completed' then 'completed'
      when 'confirmed' then case when new.worker_stage = 'requested' then 'accepted' else new.worker_stage end
      when 'in_progress' then case when new.worker_stage in ('requested', 'accepted', 'on_the_way', 'arrived')
                                   then 'in_progress' else new.worker_stage end
      else new.worker_stage end;
  end if;
  return new;
end $$;
drop trigger if exists bookings_sync_stage on bookings;
create trigger bookings_sync_stage
  before update on bookings
  for each row execute function sync_booking_stage_and_status();

-- 2. a cash booking carries a pending cash payment from the start ---------
create or replace function create_cash_payment_for_booking()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.payment_mode = 'cash'
     and not exists (select 1 from payments p where p.booking_id = new.booking_id) then
    insert into payments (booking_id, amount, payment_method, payment_status)
    values (new.booking_id, coalesce(new.estimated_cost, 0), 'cash', 'pending');
  end if;
  return new;
end $$;
drop trigger if exists bookings_cash_payment on bookings;
create trigger bookings_cash_payment
  after insert on bookings
  for each row execute function create_cash_payment_for_booking();

-- 3. the worker's cash ledger ---------------------------------------------
alter table worker_payout_accounts add column if not exists cash_in_hand numeric(10, 2) not null default 0;
alter table worker_payout_accounts add column if not exists commission_due numeric(10, 2) not null default 0;

create or replace function kaylo_commission_rate() returns numeric
language sql immutable as $$ select 0.15::numeric $$;
create or replace function kaylo_cash_due_limit() returns numeric
language sql immutable as $$ select 2000::numeric $$;

create table if not exists settlements (
  settlement_id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers (worker_id) on delete cascade,
  amount numeric(10, 2) not null check (amount > 0),
  reference text,
  settled_at timestamptz not null default now()
);
alter table settlements enable row level security;
drop policy if exists "own settlements" on settlements;
create policy "own settlements" on settlements for select
  using (worker_id = current_worker_id());
grant select on settlements to anon, authenticated;

-- The status a stage implies. The RPCs below set both columns in one UPDATE,
-- because triggers declared "after update of status" only fire when status is
-- in the statement itself, not when a BEFORE trigger changes it.
create or replace function booking_status_for_stage(p_stage text)
returns booking_status language sql immutable as $$
  select case p_stage
    when 'accepted' then 'confirmed'::booking_status
    when 'on_the_way' then 'confirmed'::booking_status
    when 'arrived' then 'confirmed'::booking_status
    when 'in_progress' then 'in_progress'::booking_status
    when 'completed' then 'completed'::booking_status
    when 'cancelled' then 'cancelled'::booking_status
    else 'pending'::booking_status end
$$;

-- 4. the worker moves a job along ------------------------------------------
create or replace function worker_advance_booking(p_booking_id uuid, p_stage text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me uuid := current_worker_id();
  b bookings%rowtype;
  due numeric;
begin
  if me is null then raise exception 'Sign in as a worker first'; end if;
  select * into b from bookings where booking_id = p_booking_id for update;
  if b.booking_id is null or b.worker_id is distinct from me then
    raise exception 'This job is not yours';
  end if;
  if p_stage not in ('accepted', 'on_the_way', 'arrived', 'in_progress', 'completed', 'cancelled') then
    raise exception 'Unknown stage %', p_stage;
  end if;
  if not (
       (b.worker_stage = 'requested'   and p_stage in ('accepted', 'cancelled'))
    or (b.worker_stage = 'accepted'    and p_stage in ('on_the_way', 'cancelled'))
    or (b.worker_stage = 'on_the_way'  and p_stage in ('arrived', 'cancelled'))
    or (b.worker_stage = 'arrived'     and p_stage in ('in_progress', 'cancelled'))
    or (b.worker_stage = 'in_progress' and p_stage = 'completed')
  ) then
    raise exception 'Cannot go from % to %', b.worker_stage, p_stage;
  end if;
  if p_stage = 'accepted' and b.payment_mode = 'cash' then
    select commission_due into due from worker_payout_accounts where worker_id = me;
    if coalesce(due, 0) >= kaylo_cash_due_limit() then
      raise exception 'Settle with Kaylo to accept cash jobs';
    end if;
  end if;
  if p_stage = 'completed' and b.payment_mode = 'cash'
     and not exists (select 1 from payments p where p.booking_id = b.booking_id and p.payment_status = 'success') then
    raise exception 'Confirm the cash you collected first';
  end if;
  update bookings set worker_stage = p_stage, status = booking_status_for_stage(p_stage)
    where booking_id = p_booking_id;
  return jsonb_build_object(
    'booking_id', p_booking_id,
    'worker_stage', p_stage,
    'status', (select status from bookings where booking_id = p_booking_id));
end $$;

-- 5. the worker confirms cash collected: payment done, job completed,
--    commission booked against the payout account ---------------------------
create or replace function confirm_cash_collected(p_booking_id uuid, p_amount numeric default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me uuid := current_worker_id();
  b bookings%rowtype;
  amt numeric;
  fee numeric;
  acct worker_payout_accounts%rowtype;
begin
  if me is null then raise exception 'Sign in as a worker first'; end if;
  select * into b from bookings where booking_id = p_booking_id for update;
  if b.booking_id is null or b.worker_id is distinct from me then
    raise exception 'This job is not yours';
  end if;
  if b.payment_mode <> 'cash' then raise exception 'This booking is paid online'; end if;
  if b.worker_stage <> 'in_progress' then raise exception 'Start the job before collecting cash'; end if;
  if exists (select 1 from payments p where p.booking_id = b.booking_id and p.payment_status = 'success') then
    raise exception 'Cash already confirmed for this booking';
  end if;
  amt := round(coalesce(p_amount, b.final_cost, b.estimated_cost, 0), 2);
  if amt <= 0 then raise exception 'Amount must be positive'; end if;
  fee := round(amt * kaylo_commission_rate(), 2);

  update payments set amount = amt, payment_method = 'cash', payment_status = 'success', paid_at = now()
    where booking_id = b.booking_id and payment_status = 'pending';
  if not found then
    insert into payments (booking_id, amount, payment_method, payment_status, paid_at)
    values (b.booking_id, amt, 'cash', 'success', now());
  end if;

  insert into worker_payout_accounts (worker_id, cash_in_hand, commission_due)
  values (me, amt, fee)
  on conflict (worker_id) do update
    set cash_in_hand = worker_payout_accounts.cash_in_hand + excluded.cash_in_hand,
        commission_due = worker_payout_accounts.commission_due + excluded.commission_due,
        updated_at = now();

  update bookings set worker_stage = 'completed', status = 'completed', final_cost = coalesce(final_cost, amt)
    where booking_id = b.booking_id;

  select * into acct from worker_payout_accounts where worker_id = me;
  return jsonb_build_object(
    'amount', amt, 'commission', fee,
    'cash_in_hand', acct.cash_in_hand, 'commission_due', acct.commission_due,
    'limit', kaylo_cash_due_limit());
end $$;

-- 6. the worker settles what is due. Until a collection flow exists this is
--    the worker's own confirmation; the dashboard sees every settlement. ----
create or replace function settle_cash_due(p_reference text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me uuid := current_worker_id();
  acct worker_payout_accounts%rowtype;
  sid uuid;
begin
  if me is null then raise exception 'Sign in as a worker first'; end if;
  select * into acct from worker_payout_accounts where worker_id = me for update;
  if acct.worker_id is null or acct.commission_due <= 0 then raise exception 'Nothing to settle'; end if;
  insert into settlements (worker_id, amount, reference) values (me, acct.commission_due, p_reference)
    returning settlement_id into sid;
  update worker_payout_accounts set commission_due = 0, cash_in_hand = 0, updated_at = now()
    where worker_id = me;
  return jsonb_build_object('settlement_id', sid, 'amount', acct.commission_due);
end $$;

-- 7. the customer rates a finished job -------------------------------------
create or replace function submit_review(p_booking_id uuid, p_rating int, p_review text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  me uuid := current_customer_id();
  b bookings%rowtype;
  rid uuid;
begin
  if me is null then raise exception 'Sign in first'; end if;
  if p_rating < 1 or p_rating > 5 then raise exception 'Rating must be between 1 and 5'; end if;
  select * into b from bookings where booking_id = p_booking_id;
  if b.booking_id is null or b.customer_id <> me then raise exception 'This booking is not yours'; end if;
  if b.status <> 'completed' then raise exception 'You can review a booking once it is completed'; end if;
  if b.worker_id is null then raise exception 'This booking has no worker to review'; end if;
  insert into reviews (booking_id, customer_id, worker_id, rating, review)
  values (p_booking_id, me, b.worker_id, p_rating, nullif(trim(coalesce(p_review, '')), ''))
  on conflict (booking_id) do update set rating = excluded.rating, review = excluded.review
  returning review_id into rid;
  return jsonb_build_object('review_id', rid, 'rating', p_rating);
end $$;

-- 8. notifications: the worker's side, and two moments for the customer ----
create or replace function notify_worker_about_booking()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_person uuid;
  v_service text;
  v_title text;
begin
  if new.worker_id is null then return new; end if;
  if tg_op = 'UPDATE' and new.status is not distinct from old.status
     and new.worker_id is not distinct from old.worker_id then
    return new;
  end if;
  v_title := case
    when tg_op = 'INSERT' or new.worker_id is distinct from old.worker_id then 'New job request'
    when new.status = 'cancelled' then 'Booking cancelled'
    when new.status = 'completed' then 'Job completed'
    else null end;
  if v_title is null then return new; end if;
  select p.person_id into v_person from workers w join persons p on p.person_id = w.person_id
    where w.worker_id = new.worker_id;
  if v_person is null then return new; end if;
  select s.service_name into v_service from services s where s.service_id = new.service_id;
  insert into notifications (person_id, title, message, type)
  values (v_person, v_title,
    coalesce(v_service, 'A service') || ' on ' || to_char(new.booking_date, 'DD Mon') || ', '
      || to_char(new.booking_time, 'HH12:MI AM')
      || case when new.payment_mode = 'cash' then ' · cash' else '' end,
    'booking');
  return new;
end $$;
drop trigger if exists bookings_notify_worker on bookings;
create trigger bookings_notify_worker
  after insert or update of status, worker_id on bookings
  for each row execute function notify_worker_about_booking();

create or replace function notify_customer_about_stage()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_person uuid;
  v_service text;
begin
  if new.worker_stage is not distinct from old.worker_stage
     or new.worker_stage not in ('on_the_way', 'arrived') then
    return new;
  end if;
  select c.person_id into v_person from customers c where c.customer_id = new.customer_id;
  if v_person is null then return new; end if;
  select s.service_name into v_service from services s where s.service_id = new.service_id;
  insert into notifications (person_id, title, message, type)
  values (v_person,
    case new.worker_stage when 'on_the_way' then 'Your worker is on the way' else 'Your worker has arrived' end,
    coalesce(v_service, 'Your service'), 'booking');
  return new;
end $$;
drop trigger if exists bookings_notify_customer_stage on bookings;
create trigger bookings_notify_customer_stage
  after update of worker_stage on bookings
  for each row execute function notify_customer_about_stage();

-- 9. who may call what ------------------------------------------------------
revoke all on function worker_advance_booking(uuid, text) from public;
revoke all on function confirm_cash_collected(uuid, numeric) from public;
revoke all on function settle_cash_due(text) from public;
revoke all on function submit_review(uuid, int, text) from public;
grant execute on function worker_advance_booking(uuid, text) to anon, authenticated;
grant execute on function confirm_cash_collected(uuid, numeric) to anon, authenticated;
grant execute on function settle_cash_due(text) to anon, authenticated;
grant execute on function submit_review(uuid, int, text) to anon, authenticated;

notify pgrst, 'reload schema';
commit;
