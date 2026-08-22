-- ============================================================
-- Kaylo — row-level security
-- Every table has RLS enabled. The public catalog (categories,
-- services, worker profiles) is readable by anyone; everything
-- personal is scoped to the signed-in person.
-- ============================================================

-- Resolve the caller's person row once, from the Supabase Auth uid.
create or replace function current_person_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select person_id from persons where auth_user_id = auth.uid();
$$;

create or replace function current_customer_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select c.customer_id from customers c
  join persons p on p.person_id = c.person_id
  where p.auth_user_id = auth.uid();
$$;

create or replace function current_worker_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select w.worker_id from workers w
  join persons p on p.person_id = w.person_id
  where p.auth_user_id = auth.uid();
$$;

alter table roles enable row level security;
alter table persons enable row level security;
alter table person_roles enable row level security;
alter table customers enable row level security;
alter table workers enable row level security;
alter table locations enable row level security;
alter table notifications enable row level security;
alter table service_categories enable row level security;
alter table services enable row level security;
alter table worker_services enable row level security;
alter table bookings enable row level security;
alter table payments enable row level security;
alter table reviews enable row level security;
alter table chat_rooms enable row level security;
alter table messages enable row level security;
alter table senior_profiles enable row level security;
alter table medicine_reminders enable row level security;
alter table sos_alerts enable row level security;

-- ---------- Public catalog ----------
create policy "roles are readable" on roles for select using (true);
create policy "categories are public" on service_categories for select using (true);
create policy "services are public" on services for select using (true);
create policy "worker skills are public" on worker_services for select using (true);
create policy "workers are public" on workers for select using (true);

-- Person rows are visible when they belong to a listed worker (marketplace
-- profile) or to the caller themself.
create policy "worker persons and self are visible" on persons for select
  using (
    person_id = current_person_id()
    or exists (select 1 from workers w where w.person_id = persons.person_id)
  );
create policy "self insert" on persons for insert
  with check (auth_user_id = auth.uid());
create policy "self update" on persons for update
  using (person_id = current_person_id());

create policy "own roles visible" on person_roles for select
  using (person_id = current_person_id());

-- ---------- Customers ----------
create policy "own customer row" on customers for select
  using (person_id = current_person_id());
create policy "create own customer row" on customers for insert
  with check (person_id = current_person_id());
create policy "update own customer row" on customers for update
  using (person_id = current_person_id());

-- Workers can update their own listing.
create policy "workers update self" on workers for update
  using (person_id = current_person_id());
create policy "workers create self" on workers for insert
  with check (person_id = current_person_id());
create policy "workers manage own skills" on worker_services for all
  using (worker_id = current_worker_id())
  with check (worker_id = current_worker_id());

-- ---------- Locations ----------
-- Own addresses fully; a worker's district is exposed via worker_profiles,
-- so allow reading locations of listed workers too.
create policy "own or worker locations visible" on locations for select
  using (
    person_id = current_person_id()
    or exists (select 1 from workers w where w.person_id = locations.person_id)
  );
create policy "manage own locations" on locations for insert
  with check (person_id = current_person_id());
create policy "update own locations" on locations for update
  using (person_id = current_person_id());
create policy "delete own locations" on locations for delete
  using (person_id = current_person_id());

-- ---------- Notifications ----------
create policy "own notifications" on notifications for select
  using (person_id = current_person_id());
create policy "mark own notifications" on notifications for update
  using (person_id = current_person_id());

-- ---------- Bookings ----------
create policy "participants read bookings" on bookings for select
  using (
    customer_id = current_customer_id()
    or worker_id = current_worker_id()
  );
create policy "customers create bookings" on bookings for insert
  with check (customer_id = current_customer_id());
create policy "participants update bookings" on bookings for update
  using (
    customer_id = current_customer_id()
    or worker_id = current_worker_id()
  );

-- ---------- Payments ----------
create policy "participants read payments" on payments for select
  using (exists (
    select 1 from bookings b where b.booking_id = payments.booking_id
      and (b.customer_id = current_customer_id() or b.worker_id = current_worker_id())
  ));
create policy "customers create payments" on payments for insert
  with check (exists (
    select 1 from bookings b where b.booking_id = payments.booking_id
      and b.customer_id = current_customer_id()
  ));

-- ---------- Reviews ----------
create policy "reviews are public" on reviews for select using (true);
create policy "customers review own bookings" on reviews for insert
  with check (
    customer_id = current_customer_id()
    and exists (
      select 1 from bookings b where b.booking_id = reviews.booking_id
        and b.customer_id = current_customer_id()
        and b.status = 'completed'
    )
  );

-- ---------- Chat ----------
create policy "participants read rooms" on chat_rooms for select
  using (exists (
    select 1 from bookings b where b.booking_id = chat_rooms.booking_id
      and (b.customer_id = current_customer_id() or b.worker_id = current_worker_id())
  ));
create policy "participants create rooms" on chat_rooms for insert
  with check (exists (
    select 1 from bookings b where b.booking_id = chat_rooms.booking_id
      and (b.customer_id = current_customer_id() or b.worker_id = current_worker_id())
  ));
create policy "participants read messages" on messages for select
  using (exists (
    select 1 from chat_rooms cr
    join bookings b on b.booking_id = cr.booking_id
    where cr.room_id = messages.room_id
      and (b.customer_id = current_customer_id() or b.worker_id = current_worker_id())
  ));
create policy "participants send messages" on messages for insert
  with check (
    sender_id = current_person_id()
    and exists (
      select 1 from chat_rooms cr
      join bookings b on b.booking_id = cr.booking_id
      where cr.room_id = messages.room_id
        and (b.customer_id = current_customer_id() or b.worker_id = current_worker_id())
    )
  );

-- ---------- Family care ----------
create policy "own senior profiles" on senior_profiles for all
  using (customer_id = current_customer_id())
  with check (customer_id = current_customer_id());
create policy "own medicine reminders" on medicine_reminders for all
  using (exists (
    select 1 from senior_profiles sp where sp.senior_id = medicine_reminders.senior_id
      and sp.customer_id = current_customer_id()
  ))
  with check (exists (
    select 1 from senior_profiles sp where sp.senior_id = medicine_reminders.senior_id
      and sp.customer_id = current_customer_id()
  ));
create policy "own sos alerts" on sos_alerts for all
  using (exists (
    select 1 from senior_profiles sp where sp.senior_id = sos_alerts.senior_id
      and sp.customer_id = current_customer_id()
  ))
  with check (exists (
    select 1 from senior_profiles sp where sp.senior_id = sos_alerts.senior_id
      and sp.customer_id = current_customer_id()
  ));
