-- ============================================================
-- Kaylo: what the live app needs beyond the ERD, found while
-- preparing the review. Safe to run more than once.
--
-- 1. persons: a signed-in user can always read their own row, so an
--    INSERT ... RETURNING on first sign-in passes the read rule.
--    (current_person_id() cannot see the row the statement is inserting.)
-- 2. caregiver_bookings: caregiver visits booked from Care. The app
--    inserts without customer_id; the default stamps the caller.
-- 3. chat_rooms: every booking with a worker gets its room, so the
--    Messages tab has a thread to open.
-- 4. notifications: the customer hears about a new booking and every
--    status change, so the bell and the inbox are live.
-- 5. realtime: messages and notifications stream to the app.
-- 6. device_tokens: person_id defaults to the caller like other tables.
-- 7. locations: a default flag for saved addresses, and creation order.
-- ============================================================

-- 1. persons read rule ----------------------------------------
drop policy if exists "worker persons and self are visible" on persons;
create policy "worker persons and self are visible" on persons for select
  using (
    person_id = current_person_id()
    or auth_user_id = current_auth_subject()
    or exists (select 1 from workers w where w.person_id = persons.person_id)
  );

-- 2. caregiver bookings ---------------------------------------
create table if not exists caregiver_bookings (
  id text primary key,
  customer_id uuid not null default current_customer_id()
    references customers (customer_id) on delete cascade,
  caregiver_id text not null references caregivers (id),
  caregiver_name text not null,
  visit_date date not null,
  start_time text not null,
  hours int not null check (hours between 1 and 24),
  hourly_rate numeric(10, 2) not null,
  total_amount numeric(10, 2) not null,
  care_type text not null,
  notes text,
  status text not null default 'confirmed'
    check (status in ('confirmed', 'completed', 'cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists caregiver_bookings_customer_idx
  on caregiver_bookings (customer_id, created_at desc);

alter table caregiver_bookings enable row level security;

drop policy if exists "own caregiver bookings" on caregiver_bookings;
create policy "own caregiver bookings" on caregiver_bookings for all
  using (customer_id = current_customer_id())
  with check (customer_id = current_customer_id());

-- 3. a chat room for every booking with a worker ----------------
create or replace function ensure_chat_room_for_booking()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.worker_id is not null then
    insert into chat_rooms (booking_id) values (new.booking_id)
    on conflict (booking_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists bookings_chat_room on bookings;
create trigger bookings_chat_room
  after insert or update of worker_id on bookings
  for each row execute function ensure_chat_room_for_booking();

insert into chat_rooms (booking_id)
select booking_id from bookings where worker_id is not null
on conflict (booking_id) do nothing;

-- 4. booking notifications ------------------------------------
create or replace function notify_customer_about_booking()
returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_person uuid;
  v_service text;
  v_when text;
  v_title text;
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  select c.person_id into v_person
  from customers c where c.customer_id = new.customer_id;
  if v_person is null then
    return new;
  end if;

  select s.service_name into v_service
  from services s where s.service_id = new.service_id;
  v_service := coalesce(v_service, 'Your service');
  v_when := to_char(new.booking_date, 'DD Mon') || ', '
    || to_char(new.booking_time, 'HH12:MI AM');

  v_title := case
    when tg_op = 'INSERT' and new.status = 'confirmed' then 'Booking confirmed'
    when tg_op = 'INSERT' then 'Booking received'
    when new.status = 'confirmed' then 'Booking confirmed'
    when new.status = 'in_progress' then 'Work has started'
    when new.status = 'completed' then 'Booking completed'
    when new.status = 'cancelled' then 'Booking cancelled'
    else 'Booking updated'
  end;

  insert into notifications (person_id, title, message, type)
  values (v_person, v_title, v_service || ' on ' || v_when, 'booking');
  return new;
end;
$$;

drop trigger if exists bookings_notify_customer on bookings;
create trigger bookings_notify_customer
  after insert or update of status on bookings
  for each row execute function notify_customer_about_booking();

-- 5. realtime -------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'messages'
    ) then
      alter publication supabase_realtime add table public.messages;
    end if;
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'notifications'
    ) then
      alter publication supabase_realtime add table public.notifications;
    end if;
  end if;
end;
$$;

-- 6. device tokens --------------------------------------------
alter table device_tokens
  alter column person_id set default current_person_id();

-- 7. saved addresses ------------------------------------------
-- A default flag the app can set, and a creation time so the list
-- keeps the order addresses were added in.
alter table locations add column if not exists is_default boolean not null default false;
alter table locations add column if not exists created_at timestamptz not null default now();
