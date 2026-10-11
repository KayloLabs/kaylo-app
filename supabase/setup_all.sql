-- ============================================================
-- Kaylo — one-shot setup for the Supabase SQL Editor.
-- Concatenation of migrations/0001_initial_schema.sql,
-- migrations/0002_rls_policies.sql and seed.sql, in order.
-- Paste this whole file into SQL Editor and press Run once.
-- ============================================================

-- ============================================================
-- Kaylo — initial schema (from the team ERD)
-- Postgres / Supabase dialect.
--
-- Deliberate adaptations from the ERD (see BACKEND.md):
--   * UUID primary keys via gen_random_uuid()
--   * Person.password_hash -> persons.auth_user_id (Supabase Auth owns
--     credentials; never store password hashes in app tables)
--   * SOS -> sos_alerts, SOS.time -> triggered_at
--   * MedicineReminder.time -> remind_time
--   * Service.estimated_duration -> estimated_duration_minutes
--   * services gains icon_path / is_popular / is_active (app UI needs)
--   * service_categories gains slug ('home' | 'farm' | 'care')
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- Enums ----------
create type account_status as enum ('active', 'suspended', 'deleted');
create type booking_status as enum ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled');
create type payment_status as enum ('pending', 'success', 'failed', 'refunded');
create type sos_status as enum ('open', 'acknowledged', 'resolved');

-- ---------- Users & roles ----------
create table roles (
  role_id uuid primary key default gen_random_uuid(),
  role_name text not null unique
);

create table persons (
  person_id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique references auth.users (id) on delete set null,
  full_name text not null,
  phone_number text unique,
  email text unique,
  profile_photo text,
  date_of_birth date,
  gender text,
  language text not null default 'en',
  account_status account_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table person_roles (
  person_role_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references persons (person_id) on delete cascade,
  role_id uuid not null references roles (role_id) on delete cascade,
  unique (person_id, role_id)
);

create table customers (
  customer_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references persons (person_id) on delete cascade,
  preferred_language text,
  emergency_contact text,
  senior_mode_enabled boolean not null default false
);

create table workers (
  worker_id uuid primary key default gen_random_uuid(),
  person_id uuid not null unique references persons (person_id) on delete cascade,
  experience_years int not null default 0,
  hourly_rate numeric(10, 2),
  travel_radius_km numeric(6, 2),
  bio text,
  is_verified boolean not null default false,
  is_available boolean not null default true,
  average_rating numeric(3, 2) not null default 0,
  total_jobs int not null default 0,
  bank_account text,
  upi_id text,
  joined_date date not null default current_date
);

-- ---------- Location & communication ----------
create table locations (
  location_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references persons (person_id) on delete cascade,
  house_name text,
  street text,
  district text,
  state text not null default 'Kerala',
  country text not null default 'India',
  pincode text,
  latitude double precision,
  longitude double precision,
  nickname text
);

create table notifications (
  notification_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references persons (person_id) on delete cascade,
  title text not null,
  message text,
  type text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ---------- Services & skills ----------
create table service_categories (
  category_id uuid primary key default gen_random_uuid(),
  category_name text not null unique,
  slug text not null unique,
  description text
);

create table services (
  service_id uuid primary key default gen_random_uuid(),
  category_id uuid not null references service_categories (category_id) on delete cascade,
  service_name text not null,
  description text,
  base_price numeric(10, 2) not null default 0,
  estimated_duration_minutes int,
  icon_path text,
  is_popular boolean not null default false,
  is_active boolean not null default true
);

create table worker_services (
  worker_service_id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers (worker_id) on delete cascade,
  service_id uuid not null references services (service_id) on delete cascade,
  experience_years int not null default 0,
  price_override numeric(10, 2),
  verified_skill boolean not null default false,
  unique (worker_id, service_id)
);

-- ---------- Booking & transactions ----------
create table bookings (
  booking_id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers (customer_id) on delete cascade,
  worker_id uuid references workers (worker_id) on delete set null,
  service_id uuid not null references services (service_id),
  location_id uuid references locations (location_id) on delete set null,
  booking_date date not null,
  booking_time time not null,
  status booking_status not null default 'pending',
  estimated_cost numeric(10, 2),
  final_cost numeric(10, 2),
  notes text,
  created_at timestamptz not null default now()
);

create table payments (
  payment_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings (booking_id) on delete cascade,
  amount numeric(10, 2) not null,
  payment_method text,
  payment_status payment_status not null default 'pending',
  transaction_id text,
  paid_at timestamptz
);

create table reviews (
  review_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references bookings (booking_id) on delete cascade,
  customer_id uuid not null references customers (customer_id) on delete cascade,
  worker_id uuid not null references workers (worker_id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  review text,
  images text[],
  created_at timestamptz not null default now()
);

create table chat_rooms (
  room_id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references bookings (booking_id) on delete cascade,
  created_at timestamptz not null default now()
);

create table messages (
  message_id uuid primary key default gen_random_uuid(),
  room_id uuid not null references chat_rooms (room_id) on delete cascade,
  sender_id uuid not null references persons (person_id) on delete cascade,
  message text not null,
  sent_at timestamptz not null default now()
);

-- ---------- Family care ----------
create table senior_profiles (
  senior_id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references customers (customer_id) on delete cascade,
  name text not null,
  age int,
  blood_group text,
  medical_conditions text,
  doctor text,
  hospital text,
  emergency_contact text
);

create table medicine_reminders (
  reminder_id uuid primary key default gen_random_uuid(),
  senior_id uuid not null references senior_profiles (senior_id) on delete cascade,
  medicine text not null,
  dosage text,
  frequency text,
  remind_time time not null
);

create table sos_alerts (
  sos_id uuid primary key default gen_random_uuid(),
  senior_id uuid not null references senior_profiles (senior_id) on delete cascade,
  triggered_at timestamptz not null default now(),
  status sos_status not null default 'open',
  responded_by uuid references persons (person_id) on delete set null
);

-- ---------- Indexes ----------
create index idx_person_roles_person on person_roles (person_id);
create index idx_locations_person on locations (person_id);
create index idx_notifications_person on notifications (person_id, is_read);
create index idx_services_category on services (category_id);
create index idx_worker_services_worker on worker_services (worker_id);
create index idx_worker_services_service on worker_services (service_id);
create index idx_bookings_customer on bookings (customer_id, created_at desc);
create index idx_bookings_worker on bookings (worker_id, booking_date);
create index idx_payments_booking on payments (booking_id);
create index idx_reviews_worker on reviews (worker_id);
create index idx_messages_room on messages (room_id, sent_at);
create index idx_medicine_reminders_senior on medicine_reminders (senior_id);
create index idx_sos_alerts_senior on sos_alerts (senior_id, status);

-- ---------- Triggers ----------
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger trg_persons_updated_at
  before update on persons
  for each row execute function set_updated_at();

-- Keep workers.average_rating in sync with reviews.
create or replace function refresh_worker_rating()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  target uuid := coalesce(new.worker_id, old.worker_id);
begin
  update workers w set average_rating = coalesce((
    select round(avg(r.rating)::numeric, 2) from reviews r where r.worker_id = target
  ), 0)
  where w.worker_id = target;
  return coalesce(new, old);
end $$;

create trigger trg_reviews_refresh_rating
  after insert or update or delete on reviews
  for each row execute function refresh_worker_rating();

-- Count completed jobs.
create or replace function bump_worker_total_jobs()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'completed' and old.status is distinct from 'completed'
     and new.worker_id is not null then
    update workers set total_jobs = total_jobs + 1 where worker_id = new.worker_id;
  end if;
  return new;
end $$;

create trigger trg_bookings_total_jobs
  after update on bookings
  for each row execute function bump_worker_total_jobs();

-- ---------- Read views for the app ----------
create view service_catalog
with (security_invoker = true) as
select
  s.service_id,
  s.service_name,
  s.description,
  s.base_price,
  s.estimated_duration_minutes,
  s.icon_path,
  s.is_popular,
  c.slug as category_slug,
  c.category_name
from services s
join service_categories c on c.category_id = s.category_id
where s.is_active;

create view worker_profiles
with (security_invoker = true) as
select
  w.worker_id,
  p.full_name,
  coalesce(p.profile_photo, '') as profile_photo,
  w.average_rating,
  w.total_jobs,
  w.hourly_rate,
  w.is_verified,
  w.is_available,
  coalesce((select count(*) from reviews r where r.worker_id = w.worker_id), 0) as reviews_count,
  (select l.district from locations l where l.person_id = p.person_id limit 1) as district,
  coalesce(
    array(select ws.service_id::text from worker_services ws where ws.worker_id = w.worker_id),
    '{}'
  ) as skill_ids,
  least(
    100,
    round((case when w.is_verified then 20 else 0 end) + w.average_rating * 16)
  )::int as trust_score
from workers w
join persons p on p.person_id = w.person_id;


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


-- ============================================================
-- Kaylo — seed data
-- Mirrors the app's mock repositories so switching from
-- USE_MOCK to live Supabase changes nothing visually.
-- Fixed UUIDs so re-running is idempotent (on conflict do nothing).
-- ============================================================

-- ---------- Roles ----------
insert into roles (role_id, role_name) values
  ('00000000-0000-4000-8000-000000000001', 'customer'),
  ('00000000-0000-4000-8000-000000000002', 'worker'),
  ('00000000-0000-4000-8000-000000000003', 'admin')
on conflict (role_id) do nothing;

-- ---------- Categories ----------
insert into service_categories (category_id, category_name, slug, description) values
  ('10000000-0000-4000-8000-000000000001', 'Home Services', 'home', 'Plumbing, electrical, cleaning and everything for your home'),
  ('10000000-0000-4000-8000-000000000002', 'Farm Services', 'farm', 'Harvesting, gardening and irrigation support'),
  ('10000000-0000-4000-8000-000000000003', 'Kaylo Care', 'care', 'Medicine delivery, appointments and senior care')
on conflict (category_id) do nothing;

-- ---------- Services (ids 2xxx) ----------
insert into services (service_id, category_id, service_name, description, base_price, estimated_duration_minutes, icon_path, is_popular) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Coconut Plucking',    'Professional coconut climbers',        1000, 60,  'assets_kaylo/3d_transparent/icon_coconut.png',  true),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Arecanut Harvesting', 'Expert harvesting',                    1200, 90,  'assets_kaylo/3d_transparent/icon_arecanut.png', true),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Gardening',           'Lawn and garden maintenance',           800, 120, 'assets_kaylo/3d_transparent/icon_garden.png',   true),
  ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'Plumbing',            'Expert plumbing services',              500, 60,  'assets_kaylo/3d_transparent/icon_plumb.png',    true),
  ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Electrical',          'Electrical repairs and wiring',         400, 60,  'assets_kaylo/3d_transparent/icon_electric.png', true),
  ('20000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000001', 'House Cleaning',      'Deep cleaning by trained staff',        600, 180, 'assets_kaylo/3d_transparent/icon_more.png',     false),
  ('20000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000003', 'Medicine Delivery',   'Doorstep delivery from local pharmacies', 50, 45, 'assets_kaylo/3d_transparent/icon_more.png',     false),
  ('20000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000003', 'Caregiver Visit',     'Trained caregiver home visits',        700, 120, 'assets_kaylo/3d_transparent/icon_more.png',     false)
on conflict (service_id) do nothing;

-- ---------- Demo workers (persons 3xxx, workers 4xxx, locations 5xxx) ----------
insert into persons (person_id, full_name, phone_number, language) values
  ('30000000-0000-4000-8000-000000000001', 'Raju K.',   '+91 90000 00001', 'ml'),
  ('30000000-0000-4000-8000-000000000002', 'Manoj P.',  '+91 90000 00002', 'ml'),
  ('30000000-0000-4000-8000-000000000003', 'Suresh B.', '+91 90000 00003', 'ml')
on conflict (person_id) do nothing;

insert into person_roles (person_role_id, person_id, role_id) values
  ('35000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002'),
  ('35000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002'),
  ('35000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000002')
on conflict (person_role_id) do nothing;

insert into locations (location_id, person_id, district, state, pincode) values
  ('50000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Kochi',     'Kerala', '682001'),
  ('50000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', 'Ernakulam', 'Kerala', '682011'),
  ('50000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', 'Thrissur',  'Kerala', '680001')
on conflict (location_id) do nothing;

insert into workers (worker_id, person_id, experience_years, hourly_rate, is_verified, average_rating, total_jobs) values
  ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 8, 250, true,  4.8, 120),
  ('40000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', 5, 200, true,  4.5,  85),
  ('40000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', 12, 300, true, 4.9, 200)
on conflict (worker_id) do nothing;

insert into worker_services (worker_service_id, worker_id, service_id, experience_years, verified_skill) values
  -- Raju: coconut plucking
  ('45000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 8, true),
  -- Manoj: coconut plucking + plumbing
  ('45000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 5, true),
  ('45000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000004', 4, true),
  -- Suresh: electrical
  ('45000000-0000-4000-8000-000000000004', '40000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000005', 12, true)
on conflict (worker_service_id) do nothing;

-- ============================================================
-- migrations/0003_care_contacts_and_logs.sql
-- ============================================================

-- ============================================================
-- Kaylo — Care additions (Review 2 Care pillar)
--
-- The ERD's medicine_reminders and sos_alerts carry the schedule and the
-- alert, but not what the Care screens need day to day:
--   * emergency_contacts       who gets alerted, and who is called first
--   * medicine_reminder_logs   which doses were taken on which day
--   * sos_alerts.location / notified_count   what the alert reported
-- ============================================================

create table emergency_contacts (
  contact_id uuid primary key default gen_random_uuid(),
  senior_id uuid not null references senior_profiles (senior_id) on delete cascade,
  name text not null,
  relation text,
  phone text not null,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create index emergency_contacts_senior_idx on emergency_contacts (senior_id);

create table medicine_reminder_logs (
  log_id uuid primary key default gen_random_uuid(),
  reminder_id uuid not null references medicine_reminders (reminder_id) on delete cascade,
  taken_on date not null default current_date,
  unique (reminder_id, taken_on)
);

alter table sos_alerts
  add column if not exists location text,
  add column if not exists notified_count int not null default 0;

-- ---------- RLS: same ownership rule as medicine_reminders ----------
alter table emergency_contacts enable row level security;
alter table medicine_reminder_logs enable row level security;

create policy "own emergency contacts" on emergency_contacts for all
  using (exists (
    select 1 from senior_profiles sp where sp.senior_id = emergency_contacts.senior_id
      and sp.customer_id = current_customer_id()
  ))
  with check (exists (
    select 1 from senior_profiles sp where sp.senior_id = emergency_contacts.senior_id
      and sp.customer_id = current_customer_id()
  ));

create policy "own medicine reminder logs" on medicine_reminder_logs for all
  using (exists (
    select 1 from medicine_reminders mr
    join senior_profiles sp on sp.senior_id = mr.senior_id
    where mr.reminder_id = medicine_reminder_logs.reminder_id
      and sp.customer_id = current_customer_id()
  ))
  with check (exists (
    select 1 from medicine_reminders mr
    join senior_profiles sp on sp.senior_id = mr.senior_id
    where mr.reminder_id = medicine_reminder_logs.reminder_id
      and sp.customer_id = current_customer_id()
  ));

-- ============================================================
-- Kaylo — Care doctors and caregivers
--
-- The Care screens list doctors and caregivers and book appointments
-- against them, but the ERD has no such tables, so the live
-- repository always fell back to mock data. These tables carry the
-- columns lib/features/care/data/supabase_care_repository.dart reads
-- and writes:
--   * doctors              public directory, seeded below
--   * caregivers           public directory, seeded below
--   * doctor_appointments  one row per booked appointment, scoped to
--                          the customer who booked it
--
-- Ids are text (doc1, cg1, apt_<millis>) because the app generates
-- them client side and the mock data uses the same shape.
-- ============================================================

create table doctors (
  id text primary key,
  name text not null,
  specialty text not null,
  hospital text,
  experience_years int not null default 0,
  rating numeric(3, 2) not null default 0,
  reviews_count int not null default 0,
  consultation_fee numeric(10, 2) not null default 0,
  available_days text[] not null default '{}',
  time_slots text[] not null default '{}',
  image_url text,
  bio text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create index doctors_specialty_idx on doctors (specialty);

create table caregivers (
  id text primary key,
  name text not null,
  rating numeric(3, 2) not null default 0,
  reviews_count int not null default 0,
  hourly_rate numeric(10, 2) not null default 0,
  experience_years int not null default 0,
  is_verified boolean not null default false,
  image_url text,
  specialties text[] not null default '{}',
  bio text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- The app inserts without customer_id; the default stamps the caller.
create table doctor_appointments (
  id text primary key,
  customer_id uuid not null default current_customer_id()
    references customers (customer_id) on delete cascade,
  doctor_id text not null references doctors (id),
  doctor_name text not null,
  specialty text not null,
  hospital text,
  appointment_date timestamptz not null,
  time_slot text not null,
  consultation_type text not null default 'homeVisit'
    check (consultation_type in ('homeVisit', 'teleconsult')),
  status text not null default 'confirmed'
    check (status in ('confirmed', 'completed', 'cancelled')),
  patient_name text,
  notes text,
  created_at timestamptz not null default now()
);

create index doctor_appointments_customer_idx
  on doctor_appointments (customer_id, created_at desc);

-- ---------- row-level security ----------

alter table doctors enable row level security;
alter table caregivers enable row level security;
alter table doctor_appointments enable row level security;

create policy "doctors are public" on doctors for select using (is_active);
create policy "caregivers are public" on caregivers for select using (is_active);

create policy "own doctor appointments" on doctor_appointments for all
  using (customer_id = current_customer_id())
  with check (customer_id = current_customer_id());

-- ---------- seed (mirrors MockCareRepository) ----------

insert into doctors (id, name, specialty, hospital, experience_years, rating, reviews_count, consultation_fee, available_days, time_slots, bio) values
  ('doc1', 'Dr. Priya Nambiar', 'General Physician', 'Aster Medcity, Kochi', 14, 4.90, 142, 500,
   '{Mon,Tue,Wed,Thu,Fri,Sat}', '{"09:00 AM","10:30 AM","02:00 PM","04:30 PM"}',
   'Senior consultant in family medicine with over 14 years of experience specializing in geriatric and adult wellness care.'),
  ('doc2', 'Dr. Rajesh Varma', 'Cardiologist', 'Amrita Institute, Kochi', 18, 4.90, 210, 700,
   '{Mon,Wed,Fri}', '{"10:00 AM","11:30 AM","03:00 PM","05:00 PM"}',
   'Interventional cardiologist focused on preventative heart care, hypertension management, and senior cardiac health.'),
  ('doc3', 'Dr. Thomas George', 'Orthopedic', 'Lakeshore Hospital, Ernakulam', 12, 4.80, 98, 600,
   '{Tue,Thu,Sat}', '{"09:30 AM","11:00 AM","02:30 PM","04:00 PM"}',
   'Orthopedic specialist treating joint pain, arthritis, mobility challenges, and post-fall recovery.'),
  ('doc4', 'Dr. Meera Krishnan', 'Geriatrician', 'Silver Care Clinic, Kochi', 16, 4.95, 180, 550,
   '{Mon,Tue,Wed,Thu,Fri}', '{"09:00 AM","11:00 AM","03:00 PM"}',
   'Dedicated geriatrician focused on holistic elder care, polypharmacy management, and cognitive wellness.'),
  ('doc5', 'Dr. Anand Padmanabhan', 'Ayurvedic', 'Kottakkal Arya Vaidya Sala, Ernakulam', 15, 4.75, 88, 400,
   '{Mon,Tue,Thu,Fri,Sat}', '{"10:00 AM","02:00 PM","04:00 PM"}',
   'Ayurvedic physician offering authentic therapeutic management for chronic ailments, joint stiffness, and rejuvenation.');

insert into caregivers (id, name, rating, reviews_count, hourly_rate, experience_years, is_verified, specialties, bio) values
  ('cg1', 'Mary Varghese', 4.90, 64, 250, 7, true,
   '{"Elderly Care","Mobility Assistance",Companionship}',
   'Certified senior caregiver with 7 years of hospital and in-home care experience. Patient, warm, and attentive.'),
  ('cg2', 'Suma Prabhakaran', 4.80, 52, 250, 5, true,
   '{"Elderly Care","Post-operative Care","Medication Support"}',
   'Experienced in post-operative care, vital sign monitoring, and daily assistance for elderly individuals.'),
  ('cg3', 'Jaya Chandran', 4.70, 38, 220, 4, true,
   '{Companionship,"Mobility Assistance","Meal Prep"}',
   'Compassionate companion caregiver fluent in Malayalam and English. Expert in gentle physical assistance.');

-- ============================================================
-- Kaylo — Firebase Authentication and push tokens
--
-- Sign-in moves to Firebase Authentication (phone OTP). Supabase keeps
-- the data: it accepts the Firebase ID token as a third-party JWT
-- (Authentication -> Third-Party Auth -> Firebase in the dashboard), so
-- every policy keeps working, with one change: Firebase user ids are
-- not UUIDs, so persons.auth_user_id becomes text and the helpers read
-- the token subject instead of auth.uid().
--
-- device_tokens holds each signed-in device's Firebase Cloud Messaging
-- token so booking updates can be pushed to customers and workers.
-- ============================================================

-- ---------- persons.auth_user_id: Supabase uuid -> Firebase uid ----------

-- Postgres will not retype a column a policy refers to; the policy is
-- recreated further down against the new helper.
drop policy if exists "self insert" on persons;
alter table persons drop constraint if exists persons_auth_user_id_fkey;
alter table persons alter column auth_user_id type text using auth_user_id::text;

-- The subject of the verified JWT: a Firebase uid after this migration,
-- and still equal to auth.uid() for any Supabase-issued token.
create or replace function current_auth_subject()
returns text
language sql stable as $$
  select nullif(auth.jwt() ->> 'sub', '');
$$;

create or replace function current_person_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select person_id from persons where auth_user_id = current_auth_subject();
$$;

create or replace function current_customer_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select c.customer_id from customers c
  join persons p on p.person_id = c.person_id
  where p.auth_user_id = current_auth_subject();
$$;

create or replace function current_worker_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select w.worker_id from workers w
  join persons p on p.person_id = w.person_id
  where p.auth_user_id = current_auth_subject();
$$;

create policy "self insert" on persons for insert
  with check (auth_user_id = current_auth_subject());

-- ---------- push notification tokens ----------

create table device_tokens (
  token_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references persons (person_id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web')),
  app text not null check (app in ('customer', 'partner')),
  updated_at timestamptz not null default now()
);

create index device_tokens_person_idx on device_tokens (person_id);

alter table device_tokens enable row level security;

create policy "own device tokens" on device_tokens for all
  using (person_id = current_person_id())
  with check (person_id = current_person_id());

-- ============================================================
-- Kaylo — bookings default to the signed-in customer
--
-- bookings.customer_id references customers.customer_id, which is not
-- the person_id the app carries as the user id. Rather than have the
-- client look the customer up, the column now defaults to the caller's
-- customer, resolved from the verified JWT the same way the RLS
-- policies do. The app then omits customer_id on insert and relies on
-- row-level security to scope reads, so a Firebase uid or a person_id
-- can never land in this column again.
-- ============================================================

alter table bookings
  alter column customer_id set default current_customer_id();

-- Locations are inserted with the person_id already, but a default
-- keeps them correct if a client ever omits it, matching the pattern.
alter table locations
  alter column person_id set default current_person_id();

-- ============================================================
-- Kaylo — home services added after the first seed
--
-- The catalog grew (Carpentry, Painting, AC Service, Appliance Repair)
-- but supabase/seed.sql, which a live project runs once, was not
-- updated, so the live Home Services list showed only the original
-- four. These inserts add the missing services; idempotent, so a
-- project that already has them is unaffected.
-- ============================================================

insert into services
  (service_id, category_id, service_name, description, base_price, estimated_duration_minutes, icon_path, is_popular)
values
  ('20000000-0000-4000-8000-000000000011', '10000000-0000-4000-8000-000000000001',
   'Carpentry', 'Furniture repair, assembly, and woodwork', 450, 90,
   'assets_kaylo/3d_transparent/icon_carpentry.png', false),
  ('20000000-0000-4000-8000-000000000012', '10000000-0000-4000-8000-000000000001',
   'Painting', 'Interior and exterior home painting', 800, 240,
   'assets_kaylo/3d_transparent/icon_painting.png', false),
  ('20000000-0000-4000-8000-000000000013', '10000000-0000-4000-8000-000000000001',
   'AC Service', 'AC maintenance, repair, and gas refilling', 650, 60,
   'assets_kaylo/3d_transparent/icon_ac.png', false),
  ('20000000-0000-4000-8000-000000000014', '10000000-0000-4000-8000-000000000001',
   'Appliance Repair', 'Washing machine, fridge, and TV repair', 500, 60,
   'assets_kaylo/3d_transparent/icon_appliance.png', false)
on conflict (service_id) do nothing;

-- Give the seeded workers these skills so the new services are not
-- empty: Raju does carpentry and appliance repair, Suresh handles AC
-- and painting.
insert into worker_services (worker_service_id, worker_id, service_id, experience_years, verified_skill)
values
  ('45000000-0000-4000-8000-000000000011', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000011', 6, true),
  ('45000000-0000-4000-8000-000000000012', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000014', 4, true),
  ('45000000-0000-4000-8000-000000000013', '40000000-0000-4000-8000-000000000003',
   '20000000-0000-4000-8000-000000000013', 7, true),
  ('45000000-0000-4000-8000-000000000014', '40000000-0000-4000-8000-000000000003',
   '20000000-0000-4000-8000-000000000012', 5, true)
on conflict (worker_service_id) do nothing;

-- ============================================================
-- Kaylo — farm services the live project was seeded before
--
-- Tree Pruning and Plot Clearing were added to the catalog after this
-- project first ran seed.sql, so a live Farm Services list showed only
-- Coconut Plucking and Arecanut Harvesting. These inserts add them.
-- Idempotent; a project that already has them is unaffected. (They are
-- already in seed.sql for fresh projects.)
-- ============================================================

insert into services
  (service_id, category_id, service_name, description, base_price, estimated_duration_minutes, icon_path, is_popular)
values
  ('20000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000002',
   'Tree Pruning', 'Overhanging branches trimmed safely near roofs and power lines', 600, 90,
   'assets_kaylo/3d_transparent/icon_garden.png', false),
  ('20000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002',
   'Plot Clearing', 'Grass and bush cleared with brush cutters', 350, 60,
   'assets_kaylo/3d_transparent/mode_farm.png', false)
on conflict (service_id) do nothing;

-- Give the seeded workers these skills so the services are not empty.
insert into worker_services (worker_service_id, worker_id, service_id, experience_years, verified_skill)
values
  ('45000000-0000-4000-8000-000000000009', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000009', 5, true),
  ('45000000-0000-4000-8000-000000000010', '40000000-0000-4000-8000-000000000003',
   '20000000-0000-4000-8000-000000000010', 6, true)
on conflict (worker_service_id) do nothing;

-- ============================================================
-- 0009_live_demo_readiness.sql
-- ============================================================
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

-- ============================================================
-- 0010_payments_razorpay.sql
-- ============================================================
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

-- ============================================================
-- 0011_email_otps.sql
-- ============================================================
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

-- ============================================================
-- 0012_care_checkout_and_account_deletion.sql
-- ============================================================
-- Care checkout through verified payment, and account deletion.
-- Safe to run more than once.
insert into services(service_id,category_id,service_name,description,base_price,estimated_duration_minutes)
select '20000000-0000-4000-8000-000000000099',category_id,'Doctor Appointment','Book a doctor consultation',500,30
from service_categories where slug='care'
on conflict(service_id) do nothing;
alter table doctor_appointments add column if not exists booking_id uuid unique references bookings(booking_id) on delete cascade;
alter table caregiver_bookings add column if not exists booking_id uuid unique references bookings(booking_id) on delete cascade;
alter table doctor_appointments drop constraint if exists doctor_appointments_status_check;
alter table doctor_appointments add constraint doctor_appointments_status_check check (status in ('pending','confirmed','completed','cancelled'));
alter table caregiver_bookings drop constraint if exists caregiver_bookings_status_check;
alter table caregiver_bookings add constraint caregiver_bookings_status_check check (status in ('pending','confirmed','completed','cancelled'));

create or replace function create_care_checkout(p_request_id uuid, p_kind text, p_details jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  cid uuid := current_customer_id(); bid uuid; sid uuid; fee numeric;
  d doctors%rowtype; c caregivers%rowtype; scheduled date; slot time; hours int;
begin
  if cid is null then raise exception 'Sign in first'; end if;
  select booking_id into bid from bookings where booking_id=p_request_id and customer_id=cid;
  if bid is not null then return bid; end if;
  scheduled := (p_details->>'date')::date;
  if scheduled < current_date then raise exception 'Choose a future appointment date'; end if;
  slot := (p_details->>'time')::time;
  if p_kind='doctor' then
    select * into strict d from doctors where id=p_details->>'provider_id' and is_active;
    fee := d.consultation_fee;
    select service_id into sid from services where lower(service_name) like '%doctor%' limit 1;
  elsif p_kind='caregiver' then
    select * into strict c from caregivers where id=p_details->>'provider_id' and is_active;
    hours := (p_details->>'hours')::int;
    if hours not between 1 and 24 then raise exception 'Choose valid hours'; end if;
    fee := c.hourly_rate*hours;
    select service_id into sid from services where lower(service_name) like '%caregiver%' limit 1;
  else raise exception 'Unknown care service'; end if;
  if sid is null then raise exception 'This care service is not available for booking'; end if;
  if fee is null or fee < 1 then raise exception 'This provider has no payable fee'; end if;
  insert into bookings(booking_id,customer_id,service_id,booking_date,booking_time,status,estimated_cost,notes)
    values(p_request_id,cid,sid,scheduled,slot,'pending',fee,case when p_kind='doctor' then d.name else c.name end)
    returning booking_id into bid;
  if p_kind='doctor' then
    insert into doctor_appointments(id,booking_id,customer_id,doctor_id,doctor_name,specialty,hospital,appointment_date,time_slot,consultation_type,status,patient_name,notes)
    values(bid::text,bid,cid,d.id,d.name,d.specialty,d.hospital,((scheduled+slot) at time zone 'Asia/Kolkata'),p_details->>'time_slot',p_details->>'consultation_type','pending',p_details->>'patient_name',p_details->>'notes');
  else
    insert into caregiver_bookings(id,booking_id,customer_id,caregiver_id,caregiver_name,visit_date,start_time,hours,hourly_rate,total_amount,care_type,notes,status)
    values(bid::text,bid,cid,c.id,c.name,scheduled,p_details->>'time_slot',hours,c.hourly_rate,fee,p_details->>'care_type',p_details->>'notes','pending');
  end if;
  return bid;
end $$;
revoke all on function create_care_checkout(uuid,text,jsonb) from public;
grant execute on function create_care_checkout(uuid,text,jsonb) to authenticated;

-- Confirmation follows the same verified payment, including retried callbacks.
create or replace function confirm_paid_care_booking()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.payment_status='success' then
    update bookings set status='confirmed' where booking_id=new.booking_id and status='pending';
    update doctor_appointments set status='confirmed' where booking_id=new.booking_id and status='pending';
    update caregiver_bookings set status='confirmed' where booking_id=new.booking_id and status='pending';
  end if;
  return new;
end $$;
drop trigger if exists confirm_paid_care_booking on payments;
create trigger confirm_paid_care_booking after insert or update of payment_status on payments for each row execute function confirm_paid_care_booking();
create or replace function sync_care_booking_status()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status in ('cancelled','completed') then
    update doctor_appointments set status=new.status::text where booking_id=new.booking_id;
    update caregiver_bookings set status=new.status::text where booking_id=new.booking_id;
  end if;
  return new;
end $$;
drop trigger if exists sync_care_booking_status on bookings;
create trigger sync_care_booking_status after update of status on bookings for each row execute function sync_care_booking_status();

-- Private retry journal. No customer can inspect another deletion request.
create table if not exists account_deletion_requests (
  auth_subject text primary key, requested_at timestamptz not null default now(),
  auth_deleted_at timestamptz
);
alter table account_deletion_requests enable row level security;
create or replace function delete_current_kaylo_account()
returns text language plpgsql security definer set search_path=public as $$
declare uid text:=current_auth_subject(); pid uuid:=current_person_id();
begin
  if uid is null then raise exception 'Sign in first'; end if;
  if coalesce((auth.jwt()->>'auth_time')::bigint,0) < extract(epoch from now()-interval '30 minutes') then
    raise exception 'Please sign out and sign in again before deleting your account';
  end if;
  if exists(select 1 from bookings b where (b.customer_id=current_customer_id() or b.worker_id=current_worker_id()) and (b.status in ('confirmed','in_progress') or (b.status='pending' and exists(select 1 from payments p where p.booking_id=b.booking_id and p.payment_status='success')))) then
    raise exception 'Complete or cancel active bookings before deleting your account. Contact kayloapp@gmail.com for unresolved payments.';
  end if;
  insert into account_deletion_requests(auth_subject) values(uid) on conflict do nothing;
  delete from email_otps where email in (select email from persons where person_id=pid);
  delete from persons where person_id=pid;
  return uid;
end $$;
revoke all on function delete_current_kaylo_account() from public;
grant execute on function delete_current_kaylo_account() to authenticated;

-- ============================================================
-- 0013_care_group_calls.sql
-- ============================================================
-- Trusted contacts and in-app SOS group calls.
-- Safe to run more than once.
create table if not exists care_invite_codes (
  owner_id uuid primary key references persons(person_id) on delete cascade,
  code text not null unique default replace(gen_random_uuid()::text,'-',''),
  expires_at timestamptz not null default now()+interval '7 days'
);
create table if not exists care_connections (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references persons(person_id) on delete cascade,
  contact_id uuid not null references persons(person_id) on delete cascade,
  owner_name text not null, contact_name text not null,
  unique(owner_id,contact_id), check(owner_id<>contact_id)
);
create table if not exists care_calls (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references persons(person_id) on delete cascade,
  created_at timestamptz not null default now(), expires_at timestamptz not null default now()+interval '30 minutes', ended_at timestamptz
);
create table if not exists care_call_members (
  call_id uuid not null references care_calls(id) on delete cascade,
  person_id uuid not null references persons(person_id) on delete cascade,
  name text not null, status text not null default 'invited' check(status in ('invited','joined','declined','left')),
  primary key(call_id,person_id)
);
create table if not exists care_call_signals (
  id bigint generated always as identity primary key,
  call_id uuid not null references care_calls(id) on delete cascade,
  sender_id uuid not null references persons(person_id) on delete cascade,
  target_id uuid not null references persons(person_id) on delete cascade,
  payload jsonb not null check(octet_length(payload::text)<65536),
  created_at timestamptz not null default now()
);
create index if not exists care_call_signals_recipient on care_call_signals(call_id,target_id,id);
create or replace function is_care_call_member(cid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from care_call_members where call_id=cid and person_id=current_person_id());
$$;
create or replace function active_care_call_member(cid uuid,pid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from care_call_members m join care_calls c on c.id=m.call_id where m.call_id=cid and m.person_id=pid and m.status='joined' and c.ended_at is null and c.expires_at>now());
$$;
alter table care_invite_codes enable row level security;
alter table care_connections enable row level security;
alter table care_calls enable row level security;
alter table care_call_members enable row level security;
alter table care_call_signals enable row level security;
-- Created only when missing, so a second run keeps the roles 0014 widened.
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_invite_codes' and policyname='own_invite') then
    create policy own_invite on care_invite_codes for select to authenticated using(owner_id=current_person_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_connections' and policyname='own_connection') then
    create policy own_connection on care_connections for select to authenticated using(owner_id=current_person_id() or contact_id=current_person_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_connections' and policyname='remove_connection') then
    create policy remove_connection on care_connections for delete to authenticated using(owner_id=current_person_id() or contact_id=current_person_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_calls' and policyname='member_calls') then
    create policy member_calls on care_calls for select to authenticated using(is_care_call_member(id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_call_members' and policyname='member_list') then
    create policy member_list on care_call_members for select to authenticated using(is_care_call_member(call_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_call_signals' and policyname='read_call_signal') then
    create policy read_call_signal on care_call_signals for select to authenticated using(target_id=current_person_id() and is_care_call_member(call_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_call_signals' and policyname='send_call_signal') then
    create policy send_call_signal on care_call_signals for insert to authenticated with check(sender_id=current_person_id() and active_care_call_member(call_id,sender_id) and active_care_call_member(call_id,target_id));
  end if;
end $$;

create or replace function care_invite_code() returns text language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); result text;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 insert into care_invite_codes(owner_id) values(pid) on conflict(owner_id) do update set code=case when care_invite_codes.expires_at<now() then replace(gen_random_uuid()::text,'-','') else care_invite_codes.code end, expires_at=now()+interval '7 days' returning code into result;
 return result;
end $$;
create or replace function accept_care_invite(p_code text) returns void language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); owner uuid;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 select owner_id into owner from care_invite_codes where code=lower(trim(p_code)) and expires_at>now();
 if owner is null or owner=pid then raise exception 'This invite is invalid or belongs to you'; end if;
 perform 1 from persons where person_id=owner for update;
 if (select count(*) from care_connections where owner_id=owner)>=5 then raise exception 'This person already has five trusted contacts'; end if;
 insert into care_connections(owner_id,contact_id,owner_name,contact_name)
 select owner,pid,(select full_name from persons where person_id=owner),(select full_name from persons where person_id=pid)
 on conflict(owner_id,contact_id) do nothing;
end $$;
create or replace function start_care_call() returns uuid language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); cid uuid;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 perform 1 from persons where person_id=pid for update;
 if not exists(select 1 from care_connections where owner_id=pid) then raise exception 'Add trusted contacts in Kaylo Care first'; end if;
 select id into cid from care_calls where owner_id=pid and ended_at is null and expires_at>now() order by created_at desc limit 1;
 if cid is not null then return cid; end if;
 insert into care_calls(owner_id) values(pid) returning id into cid;
 insert into care_call_members(call_id,person_id,name,status) select cid,pid,full_name,'joined' from persons where person_id=pid;
 insert into care_call_members(call_id,person_id,name) select cid,contact_id,contact_name from care_connections where owner_id=pid;
 delete from care_call_signals where created_at<now()-interval '1 day';
 return cid;
end $$;
create or replace function respond_care_call(p_call_id uuid,p_action text) returns void language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); owner uuid;
begin
 select owner_id into owner from care_calls where id=p_call_id and ended_at is null and expires_at>now();
 if owner is null or not is_care_call_member(p_call_id) then raise exception 'This call has ended'; end if;
 if p_action='end' and pid=owner then
   update care_calls set ended_at=now() where id=p_call_id;
   update care_call_members set status='left' where call_id=p_call_id and status in ('invited','joined');
 elsif p_action in ('joined','declined','left') then
   update care_call_members set status=p_action where call_id=p_call_id and person_id=pid;
 else raise exception 'Invalid call response'; end if;
end $$;
revoke all on function care_invite_code(),accept_care_invite(text),start_care_call(),respond_care_call(uuid,text) from public;
grant execute on function care_invite_code(),accept_care_invite(text),start_care_call(),respond_care_call(uuid,text) to authenticated;

-- ============================================================
-- 0014_care_firebase_session_access.sql
-- ============================================================
-- Existing Firebase sessions have a verified subject but no Postgres role
-- claim, so Supabase routes them as anon. Match the person-scoped policies
-- used by Kaylo's other tables; the subject is still verified by the gateway.
-- An unsigned/public request has no person id and cannot match these rules.
alter policy own_invite on care_invite_codes to anon, authenticated;
alter policy own_connection on care_connections to anon, authenticated;
alter policy remove_connection on care_connections to anon, authenticated;
alter policy member_calls on care_calls to anon, authenticated;
alter policy member_list on care_call_members to anon, authenticated;
alter policy read_call_signal on care_call_signals to anon, authenticated;
alter policy send_call_signal on care_call_signals to anon, authenticated;

-- ============================================================
-- 0015_booking_offers.sql
-- ============================================================
-- Demo offers approved for Kaylo. Payment orders already read estimated_cost.
alter table bookings add column if not exists subtotal_amount numeric(10,2);
alter table bookings add column if not exists discount_amount numeric(10,2) not null default 0;
alter table bookings add column if not exists offer_code text;

create or replace function kaylo_available_offers(p_exclude_booking uuid default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare
  cid uuid := current_customer_id(); first_ok boolean; reward_ok boolean;
  big_used boolean; weekend_used boolean; reward_used boolean; weekend boolean;
begin
  if cid is null then raise exception 'Sign in to see your offers'; end if;
  select not exists(select 1 from bookings where customer_id=cid and status<>'cancelled'
    and (p_exclude_booking is null or booking_id<>p_exclude_booking)) into first_ok;
  select exists(select 1 from bookings where customer_id=cid and status in ('confirmed','in_progress','completed')
    and (p_exclude_booking is null or booking_id<>p_exclude_booking)) into reward_ok;
  select coalesce(bool_or(offer_code='KAYLO150'),false),
         coalesce(bool_or(offer_code='WEEKEND100'),false), coalesce(bool_or(offer_code='NEXT75'),false)
    into big_used,weekend_used,reward_used
    from bookings where customer_id=cid and status<>'cancelled'
    and (p_exclude_booking is null or booking_id<>p_exclude_booking);
  weekend := extract(isodow from now() at time zone 'Asia/Kolkata') in (6,7);
  return jsonb_build_array(
    jsonb_build_object('code','FIRST100','title','Your first one is special',
      'description','₹100 off your first booking of ₹499 or more.',
      'discount',100,'minimum',499,'eligible',first_ok,'scratch',false,
      'reason',case when not first_ok then 'For your first booking only' end),
    jsonb_build_object('code','KAYLO150','title','A little help with bigger jobs',
      'description','₹150 off a booking of ₹1,499 or more. Once per account.',
      'discount',150,'minimum',1499,'eligible',not big_used,'scratch',false,
      'reason',case when big_used then 'Already used' end),
    jsonb_build_object('code','WEEKEND100','title','A weekend well spent',
      'description','₹100 off ₹999 or more on Saturdays and Sundays. Once per account.',
      'discount',100,'minimum',999,'eligible',weekend and not weekend_used,'scratch',false,
      'reason',case when weekend_used then 'Already used' when not weekend then 'Available on weekends' end),
    jsonb_build_object('code','NEXT75','title','Something for next time',
      'description','₹75 off your next booking of ₹799 or more. Unlocks after a confirmed booking.',
      'discount',75,'minimum',799,'eligible',reward_ok and not reward_used,'scratch',true,
      'reason',case when reward_used then 'Reward used' when not reward_ok then 'Unlocks after your first confirmed booking' end)
  );
end $$;

create or replace function kaylo_apply_booking_offer(p_booking_id uuid,p_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare cid uuid:=current_customer_id(); b bookings%rowtype; offer jsonb; base numeric; amount numeric;
begin
  if cid is null then raise exception 'Sign in to apply an offer'; end if;
  -- One customer cannot redeem the same offer on simultaneous checkouts.
  perform 1 from customers where customer_id=cid for update;
  select * into b from bookings where booking_id=p_booking_id and customer_id=cid for update;
  if not found then raise exception 'Booking not found'; end if;
  p_code:=upper(trim(p_code));
  if b.status='cancelled' then raise exception 'This booking was cancelled'; end if;
  if b.offer_code=p_code and b.discount_amount>0 then return to_jsonb(b); end if;
  if b.status<>'pending' or exists(select 1 from payments where booking_id=b.booking_id and payment_status in ('pending','success')) then
    raise exception 'This checkout has already started. Keep its current offer or start a new booking.';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers(b.booking_id)) where value->>'code'=p_code;
  if offer is null then raise exception 'That coupon code is not available'; end if;
  if not (offer->>'eligible')::boolean then raise exception '%',offer->>'reason'; end if;
  base:=coalesce(b.subtotal_amount,b.estimated_cost);
  amount:=(offer->>'discount')::numeric;
  if base is null or base<(offer->>'minimum')::numeric or base<=amount then raise exception 'The booking does not meet this offer’s minimum amount'; end if;
  update bookings set subtotal_amount=base,discount_amount=amount,offer_code=p_code,estimated_cost=base-amount
    where booking_id=b.booking_id returning * into b;
  update caregiver_bookings set total_amount=b.estimated_cost where booking_id=b.booking_id;
  return to_jsonb(b);
end $$;

revoke all on function kaylo_available_offers(uuid) from public;
revoke all on function kaylo_apply_booking_offer(uuid,text) from public;
-- Firebase sessions may use anon; functions still require a verified customer's ID.
grant execute on function kaylo_available_offers(uuid) to anon,authenticated;
grant execute on function kaylo_apply_booking_offer(uuid,text) to anon,authenticated;
-- Preserve chosen addresses and map pins in the primary Care booking too.
create or replace function create_care_checkout(p_request_id uuid, p_kind text, p_details jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  cid uuid := current_customer_id(); bid uuid; sid uuid; fee numeric;
  d doctors%rowtype; c caregivers%rowtype; scheduled date; slot time; hours int; chosen_location uuid;
begin
  if cid is null then raise exception 'Sign in first'; end if;
  select booking_id into bid from bookings where booking_id=p_request_id and customer_id=cid;
  if bid is not null then return bid; end if;
  chosen_location := nullif(p_details->>'location_id','')::uuid;
  if chosen_location is not null and not exists(select 1 from locations where location_id=chosen_location and person_id=current_person_id()) then
    raise exception 'Choose an address saved to your account';
  end if;
  scheduled := (p_details->>'date')::date;
  if scheduled < current_date then raise exception 'Choose a future appointment date'; end if;
  slot := (p_details->>'time')::time;
  if p_kind='doctor' then
    select * into strict d from doctors where id=p_details->>'provider_id' and is_active;
    fee := d.consultation_fee;
    select service_id into sid from services where lower(service_name) like '%doctor%' limit 1;
  elsif p_kind='caregiver' then
    select * into strict c from caregivers where id=p_details->>'provider_id' and is_active;
    hours := (p_details->>'hours')::int;
    if hours not between 1 and 24 then raise exception 'Choose valid hours'; end if;
    fee := c.hourly_rate*hours;
    select service_id into sid from services where lower(service_name) like '%caregiver%' limit 1;
  else raise exception 'Unknown care service'; end if;
  if sid is null then raise exception 'This care service is not available for booking'; end if;
  if fee is null or fee < 1 then raise exception 'This provider has no payable fee'; end if;
  insert into bookings(booking_id,customer_id,service_id,booking_date,booking_time,status,estimated_cost,notes,location_id)
    values(p_request_id,cid,sid,scheduled,slot,'pending',fee,concat_ws(E'\n',case when p_kind='doctor' then d.name else c.name end,nullif(p_details->>'notes','')),chosen_location)
    returning booking_id into bid;
  if p_kind='doctor' then
    insert into doctor_appointments(id,booking_id,customer_id,doctor_id,doctor_name,specialty,hospital,appointment_date,time_slot,consultation_type,status,patient_name,notes)
    values(bid::text,bid,cid,d.id,d.name,d.specialty,d.hospital,((scheduled+slot) at time zone 'Asia/Kolkata'),p_details->>'time_slot',p_details->>'consultation_type','pending',p_details->>'patient_name',p_details->>'notes');
  else
    insert into caregiver_bookings(id,booking_id,customer_id,caregiver_id,caregiver_name,visit_date,start_time,hours,hourly_rate,total_amount,care_type,notes,status)
    values(bid::text,bid,cid,c.id,c.name,scheduled,p_details->>'time_slot',hours,c.hourly_rate,fee,p_details->>'care_type',p_details->>'notes','pending');
  end if;
  return bid;
end $$;

revoke all on function create_care_checkout(uuid,text,jsonb) from public;
grant execute on function create_care_checkout(uuid,text,jsonb) to anon,authenticated;
notify pgrst,'reload schema';

-- ============================================================
-- 0016_more_offers.sql
-- ============================================================
-- More offers, offers tied to one kind of service, and online checkouts
-- that were opened but never paid no longer using up an offer.
-- Replaces the two offer functions from 0015. Safe to run more than once;
-- when re-applying older files, run this one after them.

-- An online checkout that was opened and never paid: a Razorpay order
-- exists for the booking, no payment succeeded. A pay-after-service
-- booking has no payment row at all, so it still counts as a booking.
create or replace function kaylo_unpaid_checkout(p_booking_id uuid, p_status booking_status)
returns boolean language sql stable security definer set search_path = public as $$
  select p_status = 'pending'
    and exists(select 1 from payments where booking_id = p_booking_id and payment_method like 'razorpay%')
    and not exists(select 1 from payments where booking_id = p_booking_id and payment_status = 'success');
$$;
-- Internal: only the offer functions below call it.
revoke all on function kaylo_unpaid_checkout(uuid, booking_status) from public, anon, authenticated;

-- Every offer with whether this customer can use it. `reason_code` lets the
-- app explain in the customer's language; `reason` is the English fallback.
-- `category` is a service_categories slug, or null for any booking.
create or replace function kaylo_available_offers(p_exclude_booking uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  cid uuid := current_customer_id();
  rs text := chr(8377); -- the rupee sign, kept out of the source text
  booked int; settled int; used text[]; dow int;
begin
  if cid is null then raise exception 'Sign in to see your offers'; end if;
  select count(*),
         count(*) filter (where b.status in ('confirmed', 'in_progress', 'completed')),
         coalesce(array_agg(b.offer_code) filter (where b.offer_code is not null), '{}')
    into booked, settled, used
    from bookings b
   where b.customer_id = cid and b.status <> 'cancelled'
     and (p_exclude_booking is null or b.booking_id <> p_exclude_booking)
     and not kaylo_unpaid_checkout(b.booking_id, b.status);
  dow := extract(isodow from now() at time zone 'Asia/Kolkata');
  return (
    select jsonb_agg(jsonb_build_object(
        'code', o.code, 'title', o.title, 'description', o.description,
        'discount', o.discount, 'minimum', o.minimum, 'category', o.category,
        'scratch', o.scratch, 'eligible', o.why is null, 'reason_code', o.why,
        'reason', case o.why
          when 'first_only' then 'For your first booking only'
          when 'used' then 'Already used'
          when 'reward_used' then 'Reward used'
          when 'weekend_only' then 'Available on weekends'
          when 'weekday_only' then 'Available Monday to Friday'
          when 'needs_confirmed' then 'Unlocks after your first confirmed booking'
          when 'needs_three' then 'Unlocks after three confirmed bookings'
        end) order by o.pos)
    from (values
      (1, 'FIRST100', 'Your first one is special',
        rs || '100 off your first booking of ' || rs || '499 or more.',
        100, 499, null::text, false,
        case when booked > 0 then 'first_only' end),
      (2, 'KAYLO150', 'A little help with bigger jobs',
        rs || '150 off a booking of ' || rs || '1,499 or more. Once per account.',
        150, 1499, null, false,
        case when 'KAYLO150' = any(used) then 'used' end),
      (3, 'WEEKEND100', 'A weekend well spent',
        rs || '100 off ' || rs || '999 or more on Saturdays and Sundays. Once per account.',
        100, 999, null, false,
        case when 'WEEKEND100' = any(used) then 'used' when dow not in (6, 7) then 'weekend_only' end),
      (4, 'WEEKDAY50', 'A midweek lift',
        rs || '50 off ' || rs || '599 or more, Monday to Friday. Once per account.',
        50, 599, null, false,
        case when 'WEEKDAY50' = any(used) then 'used' when dow in (6, 7) then 'weekday_only' end),
      (5, 'HOME80', 'Home, sorted',
        rs || '80 off a home service of ' || rs || '499 or more. Once per account.',
        80, 499, 'home', false,
        case when 'HOME80' = any(used) then 'used' end),
      (6, 'FARM125', 'For the land that feeds us',
        rs || '125 off a farm service of ' || rs || '999 or more. Once per account.',
        125, 999, 'farm', false,
        case when 'FARM125' = any(used) then 'used' end),
      (7, 'CARE60', 'Care, made a little lighter',
        rs || '60 off a Care booking of ' || rs || '399 or more. Once per account.',
        60, 399, 'care', false,
        case when 'CARE60' = any(used) then 'used' end),
      (8, 'KAYLO300', 'For the really big days',
        rs || '300 off a booking of ' || rs || '2,999 or more. Once per account.',
        300, 2999, null, false,
        case when 'KAYLO300' = any(used) then 'used' end),
      (9, 'NEXT75', 'Something for next time',
        rs || '75 off your next booking of ' || rs || '799 or more. Unlocks after a confirmed booking.',
        75, 799, null, true,
        case when 'NEXT75' = any(used) then 'reward_used' when settled < 1 then 'needs_confirmed' end),
      (10, 'THANKS120', 'Three bookings in. Thank you.',
        rs || '120 off a booking of ' || rs || '999 or more. Unlocks after three confirmed bookings.',
        120, 999, null, true,
        case when 'THANKS120' = any(used) then 'reward_used' when settled < 3 then 'needs_three' end)
    ) as o(pos, code, title, description, discount, minimum, category, scratch, why)
  );
end $$;

create or replace function kaylo_apply_booking_offer(p_booking_id uuid, p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  cid uuid := current_customer_id(); b bookings%rowtype; offer jsonb;
  base numeric; amount numeric; kind text;
begin
  if cid is null then raise exception 'Sign in to apply an offer'; end if;
  -- One customer cannot redeem the same offer on simultaneous checkouts.
  perform 1 from customers where customer_id = cid for update;
  select * into b from bookings where booking_id = p_booking_id and customer_id = cid for update;
  if not found then raise exception 'Booking not found'; end if;
  p_code := upper(trim(p_code));
  if b.status = 'cancelled' then raise exception 'This booking was cancelled'; end if;
  if b.offer_code = p_code and b.discount_amount > 0 then return to_jsonb(b); end if;
  if b.status <> 'pending' or exists(select 1 from payments where booking_id = b.booking_id and payment_status in ('pending', 'success')) then
    raise exception 'This checkout has already started. Keep its current offer or start a new booking.';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers(b.booking_id)) where value->>'code' = p_code;
  if offer is null then raise exception 'That coupon code is not available'; end if;
  if not (offer->>'eligible')::boolean then raise exception '%', offer->>'reason'; end if;
  if offer->>'category' is not null then
    select c.slug into kind from services s join service_categories c on c.category_id = s.category_id
     where s.service_id = b.service_id;
    if kind is distinct from offer->>'category' then
      raise exception 'This offer is for % bookings only', offer->>'category';
    end if;
  end if;
  base := coalesce(b.subtotal_amount, b.estimated_cost);
  amount := (offer->>'discount')::numeric;
  if base is null or base < (offer->>'minimum')::numeric or base <= amount then
    raise exception 'The booking does not meet the minimum amount for this offer';
  end if;
  -- The same code may still sit on a checkout this customer opened and never
  -- paid. That booking gives it up here, so it cannot be paid later at the
  -- discount: a new payment order always reads the current total.
  with released as (
    update bookings o
       set estimated_cost = coalesce(o.subtotal_amount, o.estimated_cost), discount_amount = 0, offer_code = null
     where o.customer_id = cid and o.booking_id <> b.booking_id and o.offer_code = p_code
       and kaylo_unpaid_checkout(o.booking_id, o.status)
    returning o.booking_id, o.estimated_cost)
  update caregiver_bookings c set total_amount = r.estimated_cost from released r where c.booking_id = r.booking_id;
  update bookings set subtotal_amount = base, discount_amount = amount, offer_code = p_code, estimated_cost = base - amount
    where booking_id = b.booking_id returning * into b;
  update caregiver_bookings set total_amount = b.estimated_cost where booking_id = b.booking_id;
  return to_jsonb(b);
end $$;

revoke all on function kaylo_available_offers(uuid) from public;
revoke all on function kaylo_apply_booking_offer(uuid, text) from public;
-- Firebase sessions may use anon; both functions still require a verified customer.
grant execute on function kaylo_available_offers(uuid) to anon, authenticated;
grant execute on function kaylo_apply_booking_offer(uuid, text) to anon, authenticated;
notify pgrst, 'reload schema';

-- ============================================================
-- 0017_realistic_prices.sql
-- ============================================================
-- Prices a customer in Kerala would recognise. Farm work is booked per
-- tree or per hour, so the earlier figures (1,000 for one coconut tree)
-- made an ordinary booking cost many times what it should. Existing
-- bookings keep the amount they were made at. Safe to run more than once.

-- Per tree: coconut, arecanut, pruning. Per hour: plot clearing, gardening.
-- Everything else is one visit.
update services s set base_price = v.price
  from (values
    ('Coconut Plucking', 50), ('Arecanut Harvesting', 30), ('Tree Pruning', 300),
    ('Plot Clearing', 300), ('Gardening', 180),
    ('Electrical', 250), ('Plumbing', 300), ('Appliance Repair', 300), ('Carpentry', 350),
    ('AC Service', 550), ('House Cleaning', 600), ('Painting', 600),
    ('Medicine Delivery', 40), ('Doctor Appointment', 300), ('Caregiver Visit', 300)
  ) as v(name, price)
 where s.service_name = v.name;

-- A consultation, by speciality.
update doctors d set consultation_fee = v.fee
  from (values ('doc1', 300), ('doc2', 600), ('doc3', 500), ('doc4', 400), ('doc5', 250)) as v(id, fee)
 where d.id = v.id;

-- A caregiver, per hour.
update caregivers c set hourly_rate = v.rate
  from (values ('cg1', 150), ('cg2', 150), ('cg3', 130)) as v(id, rate)
 where c.id = v.id;

-- ============================================================
-- 0018_worker_payout_accounts.sql
-- ============================================================
-- Payout details leave the public worker row. workers is readable by every
-- signed-in customer (that is how the marketplace lists workers), and until
-- now that included bank_account and upi_id. They move to
-- worker_payout_accounts, which only the worker it belongs to can read or
-- write; the service role (dashboard, payouts) sees everything as usual.
-- Safe to run more than once.
begin;

create table if not exists worker_payout_accounts (
  worker_id uuid primary key references workers (worker_id) on delete cascade,
  bank_account text,
  upi_id text,
  updated_at timestamptz not null default now()
);

-- Carry over anything already stored, then drop the public columns.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workers'
      and column_name = 'bank_account'
  ) then
    insert into worker_payout_accounts (worker_id, bank_account, upi_id)
      select worker_id, bank_account, upi_id from workers
      where bank_account is not null or upi_id is not null
    on conflict (worker_id) do update
      set bank_account = coalesce(excluded.bank_account, worker_payout_accounts.bank_account),
          upi_id = coalesce(excluded.upi_id, worker_payout_accounts.upi_id),
          updated_at = now();
    alter table workers drop column bank_account, drop column upi_id;
  end if;
end $$;

alter table worker_payout_accounts enable row level security;

drop policy if exists "own payout account" on worker_payout_accounts;
create policy "own payout account" on worker_payout_accounts
  for all
  using (worker_id = current_worker_id())
  with check (worker_id = current_worker_id());

-- Firebase sessions may use anon; the policy still requires the caller to be
-- the worker the row belongs to.
grant select, insert, update, delete on worker_payout_accounts to anon, authenticated;

notify pgrst, 'reload schema';
commit;

-- ============================================================
-- 0019_cash_and_worker_stages.sql
-- ============================================================
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


-- ============================================================
-- 0020_worker_registration.sql
-- ============================================================
-- Worker registration and verification.
--
-- A signed-in person registers as a worker in one call (register_worker):
-- profile, services offered, service area, payout account. Their documents
-- (photo, Aadhaar front and back, police certificate, selfie) live in the
-- private storage bucket worker-documents under <worker_id>/..., tracked in
-- worker_documents. Only the worker sees their own documents; the Trust Team
-- reviews with review_worker and review_worker_document, which only the
-- service role can call. workers.is_verified now follows
-- workers.verification_status.
-- Run after 0019. Safe to run more than once.
begin;

-- 1. verification status on the worker ------------------------------------
alter table workers add column if not exists verification_status text not null default 'unverified';
alter table workers drop constraint if exists workers_verification_status_check;
alter table workers add constraint workers_verification_status_check
  check (verification_status in ('unverified', 'under_review', 'verified', 'rejected'));
alter table workers add column if not exists working_hours text;

update workers set verification_status = 'verified'
  where is_verified and verification_status = 'unverified';

create or replace function sync_worker_verified()
returns trigger language plpgsql as $$
begin
  -- Rows written with the old flag only (seed data, dashboards) keep meaning
  -- what they say; otherwise the status is the source of truth.
  if tg_op = 'INSERT' and new.is_verified and new.verification_status = 'unverified' then
    new.verification_status := 'verified';
  end if;
  new.is_verified := (new.verification_status = 'verified');
  return new;
end $$;
drop trigger if exists workers_sync_verified on workers;
create trigger workers_sync_verified
  before insert or update of verification_status, is_verified on workers
  for each row execute function sync_worker_verified();

-- 2. documents ----------------------------------------------------------------
create table if not exists worker_documents (
  document_id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers (worker_id) on delete cascade,
  doc_type text not null
    check (doc_type in ('photo', 'aadhaar_front', 'aadhaar_back', 'police_certificate', 'selfie')),
  storage_path text not null,
  status text not null default 'pending' check (status in ('pending', 'verified', 'rejected')),
  note text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (worker_id, doc_type)
);
alter table worker_documents enable row level security;
drop policy if exists "own documents" on worker_documents;
create policy "own documents" on worker_documents for select
  using (worker_id = current_worker_id());
drop policy if exists "submit own documents" on worker_documents;
create policy "submit own documents" on worker_documents for insert
  with check (worker_id = current_worker_id() and status = 'pending');
drop policy if exists "replace own pending documents" on worker_documents;
create policy "replace own pending documents" on worker_documents for delete
  using (worker_id = current_worker_id() and status = 'pending');
grant select, insert, delete on worker_documents to anon, authenticated;

-- 3. the private bucket, when storage is present (it is on Supabase) --------
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    insert into storage.buckets (id, name, public)
      values ('worker-documents', 'worker-documents', false)
      on conflict (id) do nothing;
    execute $p$drop policy if exists "workers upload own documents" on storage.objects$p$;
    execute $p$create policy "workers upload own documents" on storage.objects for insert
      to anon, authenticated
      with check (bucket_id = 'worker-documents'
                  and (storage.foldername(name))[1] = current_worker_id()::text)$p$;
    execute $p$drop policy if exists "workers read own documents" on storage.objects$p$;
    execute $p$create policy "workers read own documents" on storage.objects for select
      to anon, authenticated
      using (bucket_id = 'worker-documents'
             and (storage.foldername(name))[1] = current_worker_id()::text)$p$;
    execute $p$drop policy if exists "workers replace own documents" on storage.objects$p$;
    execute $p$create policy "workers replace own documents" on storage.objects for delete
      to anon, authenticated
      using (bucket_id = 'worker-documents'
             and (storage.foldername(name))[1] = current_worker_id()::text)$p$;
  end if;
end $$;

-- 4. registration in one call -----------------------------------------------
-- p_details: { full_name, photo_path?, services: [service_id, ...],
--   experience_years?, hourly_rate?, district?, travel_radius_km?,
--   working_hours?, bio?, upi_id?, bank_account? }
create or replace function register_worker(p_details jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  me uuid := current_person_id();
  wid uuid;
  svc text;
  v_upi text := nullif(trim(coalesce(p_details->>'upi_id', '')), '');
  v_bank text := nullif(trim(coalesce(p_details->>'bank_account', '')), '');
begin
  if me is null then raise exception 'Sign in first'; end if;
  if coalesce(trim(p_details->>'full_name'), '') = '' then raise exception 'Name is required'; end if;
  if jsonb_typeof(p_details->'services') is distinct from 'array'
     or jsonb_array_length(p_details->'services') = 0 then
    raise exception 'Choose at least one service';
  end if;
  if v_upi is null and v_bank is null then
    raise exception 'A UPI ID or a bank account is required';
  end if;

  update persons
    set full_name = trim(p_details->>'full_name'),
        profile_photo = coalesce(nullif(p_details->>'photo_path', ''), profile_photo)
    where person_id = me;

  insert into workers (person_id, experience_years, hourly_rate, travel_radius_km, bio, working_hours,
                       verification_status)
  values (me,
          coalesce((p_details->>'experience_years')::int, 0),
          (p_details->>'hourly_rate')::numeric,
          coalesce((p_details->>'travel_radius_km')::numeric, 10),
          nullif(p_details->>'bio', ''),
          nullif(p_details->>'working_hours', ''),
          'under_review')
  on conflict (person_id) do update
    set experience_years = excluded.experience_years,
        hourly_rate = excluded.hourly_rate,
        travel_radius_km = excluded.travel_radius_km,
        bio = excluded.bio,
        working_hours = excluded.working_hours,
        verification_status = case when workers.verification_status = 'verified'
                                   then 'verified' else 'under_review' end
  returning worker_id into wid;

  delete from worker_services where worker_id = wid;
  for svc in select jsonb_array_elements_text(p_details->'services') loop
    insert into worker_services (worker_id, service_id, experience_years)
    values (wid, svc::uuid, coalesce((p_details->>'experience_years')::int, 0))
    on conflict (worker_id, service_id) do nothing;
  end loop;

  if coalesce(p_details->>'district', '') <> '' then
    if exists (select 1 from locations where person_id = me) then
      update locations set district = p_details->>'district'
        where location_id = (
          select location_id from locations where person_id = me
          order by is_default desc, created_at limit 1);
    else
      insert into locations (person_id, district, is_default, nickname)
      values (me, p_details->>'district', true, 'Work area');
    end if;
  end if;

  insert into worker_payout_accounts (worker_id, upi_id, bank_account)
  values (wid, v_upi, v_bank)
  on conflict (worker_id) do update
    set upi_id = coalesce(excluded.upi_id, worker_payout_accounts.upi_id),
        bank_account = coalesce(excluded.bank_account, worker_payout_accounts.bank_account),
        updated_at = now();

  return wid;
end $$;

-- 5. the Trust Team's side: service role only ---------------------------------
create or replace function review_worker(p_worker_id uuid, p_status text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_status not in ('under_review', 'verified', 'rejected') then
    raise exception 'Unknown status %', p_status;
  end if;
  update workers set verification_status = p_status where worker_id = p_worker_id;
  if not found then raise exception 'No such worker'; end if;
  if p_status in ('verified', 'rejected') then
    update worker_documents
      set status = p_status, reviewed_at = now(), note = coalesce(p_note, note)
      where worker_id = p_worker_id and status = 'pending';
  end if;
  insert into notifications (person_id, title, message, type)
  select person_id,
         case p_status when 'verified' then 'You are verified'
                       when 'rejected' then 'Verification needs attention'
                       else 'Verification under review' end,
         coalesce(p_note, 'Kaylo Trust Team'), 'system'
  from workers where worker_id = p_worker_id;
end $$;

create or replace function review_worker_document(p_document_id uuid, p_status text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_status not in ('pending', 'verified', 'rejected') then
    raise exception 'Unknown status %', p_status;
  end if;
  update worker_documents
    set status = p_status, reviewed_at = case when p_status = 'pending' then null else now() end,
        note = coalesce(p_note, note)
    where document_id = p_document_id;
  if not found then raise exception 'No such document'; end if;
end $$;

revoke all on function register_worker(jsonb) from public;
grant execute on function register_worker(jsonb) to anon, authenticated;
revoke all on function review_worker(uuid, text, text) from public, anon, authenticated;
revoke all on function review_worker_document(uuid, text, text) from public, anon, authenticated;
grant execute on function review_worker(uuid, text, text) to service_role;
grant execute on function review_worker_document(uuid, text, text) to service_role;

notify pgrst, 'reload schema';
commit;

-- ============================================================
-- 0021_worker_time_slots.sql
-- ============================================================
-- A worker's time slot is taken the moment a booking holds it.
--
-- The customer app shows a worker's slots for a day; the ones already held
-- by an open booking (pending, confirmed or in progress) are read through
-- worker_taken_slots and shown as booked. The database also refuses a
-- second open booking for the same worker, day and time, so two customers
-- booking at once cannot both get the slot. Cancelled and completed
-- bookings free the slot again. Safe to run more than once.
begin;

create or replace function worker_taken_slots(p_worker_id uuid, p_date date)
returns setof time
language sql stable security definer set search_path = public as $$
  select booking_time from bookings
  where worker_id = p_worker_id
    and booking_date = p_date
    and status in ('pending', 'confirmed', 'in_progress');
$$;
revoke all on function worker_taken_slots(uuid, date) from public;
grant execute on function worker_taken_slots(uuid, date) to anon, authenticated;

-- Runs with the owner's rights so it sees every customer's bookings, not
-- only the caller's.
create or replace function prevent_double_booking()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.worker_id is null
     or new.status not in ('pending', 'confirmed', 'in_progress') then
    return new;
  end if;
  if exists (
    select 1 from bookings b
    where b.worker_id = new.worker_id
      and b.booking_date = new.booking_date
      and b.booking_time = new.booking_time
      and b.status in ('pending', 'confirmed', 'in_progress')
      and b.booking_id <> new.booking_id
  ) then
    raise exception 'That time is no longer available for this worker'
      using errcode = 'unique_violation';
  end if;
  return new;
end $$;

drop trigger if exists bookings_no_double_booking on bookings;
create trigger bookings_no_double_booking
  before insert or update of worker_id, booking_date, booking_time, status on bookings
  for each row execute function prevent_double_booking();

notify pgrst, 'reload schema';
commit;

-- ============================================================
-- 0022_worker_profile_rpcs.sql
-- ============================================================
-- The partner app's own profile, in three calls.
--
-- my_worker_profile() returns everything the profile screen shows for the
-- signed-in worker in one round trip: the person, the worker row, the
-- services offered, the service area, the payout account and the state of
-- each submitted document. update_worker_profile(details) changes only the
-- keys it is given, the same shape register_worker takes, so a partial edit
-- never blanks a field. set_worker_available(flag) is the on-duty switch:
-- false hides the worker from new bookings without touching anything else.
-- All three run as the owner and find the worker through the Firebase
-- subject, so a worker can never read or change another worker's row.
-- Safe to run more than once.
begin;

create or replace function my_worker_profile()
returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'worker_id', w.worker_id,
    'person_id', p.person_id,
    'full_name', p.full_name,
    'phone_number', p.phone_number,
    'email', p.email,
    'profile_photo', p.profile_photo,
    'experience_years', w.experience_years,
    'hourly_rate', w.hourly_rate,
    'travel_radius_km', w.travel_radius_km,
    'bio', w.bio,
    'is_verified', w.is_verified,
    'verification_status', w.verification_status,
    'is_available', w.is_available,
    'average_rating', w.average_rating,
    'total_jobs', w.total_jobs,
    'reviews_count', (select count(*) from reviews r where r.worker_id = w.worker_id),
    'joined_date', w.joined_date,
    'working_hours', w.working_hours,
    'district', (select l.district from locations l
                 where l.person_id = p.person_id
                 order by l.is_default desc, l.created_at limit 1),
    'services', coalesce((
      select jsonb_agg(jsonb_build_object('service_id', s.service_id, 'service_name', s.service_name)
                       order by s.service_name)
      from worker_services ws join services s on s.service_id = ws.service_id
      where ws.worker_id = w.worker_id), '[]'::jsonb),
    'upi_id', pa.upi_id,
    'bank_account', pa.bank_account,
    'documents', coalesce((
      select jsonb_agg(jsonb_build_object('doc_type', d.doc_type, 'status', d.status) order by d.doc_type)
      from worker_documents d where d.worker_id = w.worker_id), '[]'::jsonb)
  )
  from workers w
  join persons p on p.person_id = w.person_id
  left join worker_payout_accounts pa on pa.worker_id = w.worker_id
  where w.worker_id = current_worker_id();
$$;
revoke all on function my_worker_profile() from public;
grant execute on function my_worker_profile() to anon, authenticated;

-- details: any of { full_name, photo_path, bio, experience_years, hourly_rate,
--   travel_radius_km, working_hours, district, services: [service_id, ...],
--   upi_id, bank_account }. Keys that are absent stay as they are.
create or replace function update_worker_profile(p_details jsonb)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  wid uuid := current_worker_id();
  me uuid := current_person_id();
  svc text;
begin
  if me is null then raise exception 'Sign in first'; end if;
  if wid is null then raise exception 'Register as a worker first'; end if;

  if p_details ? 'full_name' then
    if coalesce(trim(p_details->>'full_name'), '') = '' then
      raise exception 'Name is required';
    end if;
    update persons set full_name = trim(p_details->>'full_name') where person_id = me;
  end if;
  if p_details ? 'photo_path' and coalesce(p_details->>'photo_path', '') <> '' then
    update persons set profile_photo = p_details->>'photo_path' where person_id = me;
  end if;

  if p_details ? 'travel_radius_km' then
    if (p_details->>'travel_radius_km')::numeric not between 1 and 100 then
      raise exception 'Travel radius must be between 1 and 100 km';
    end if;
  end if;
  update workers set
    bio = case when p_details ? 'bio' then nullif(trim(p_details->>'bio'), '') else bio end,
    experience_years = case when p_details ? 'experience_years'
                            then coalesce((p_details->>'experience_years')::int, experience_years)
                            else experience_years end,
    hourly_rate = case when p_details ? 'hourly_rate' then (p_details->>'hourly_rate')::numeric else hourly_rate end,
    travel_radius_km = case when p_details ? 'travel_radius_km'
                            then (p_details->>'travel_radius_km')::numeric else travel_radius_km end,
    working_hours = case when p_details ? 'working_hours'
                         then nullif(trim(p_details->>'working_hours'), '') else working_hours end
    where worker_id = wid;

  if p_details ? 'services' then
    if jsonb_typeof(p_details->'services') is distinct from 'array'
       or jsonb_array_length(p_details->'services') = 0 then
      raise exception 'Choose at least one service';
    end if;
    delete from worker_services where worker_id = wid
      and service_id not in (select jsonb_array_elements_text(p_details->'services')::uuid);
    for svc in select jsonb_array_elements_text(p_details->'services') loop
      insert into worker_services (worker_id, service_id, experience_years)
      values (wid, svc::uuid, (select experience_years from workers where worker_id = wid))
      on conflict (worker_id, service_id) do nothing;
    end loop;
  end if;

  if coalesce(p_details->>'district', '') <> '' then
    if exists (select 1 from locations where person_id = me) then
      update locations set district = p_details->>'district'
        where location_id = (
          select location_id from locations where person_id = me
          order by is_default desc, created_at limit 1);
    else
      insert into locations (person_id, district, is_default, nickname)
      values (me, p_details->>'district', true, 'Work area');
    end if;
  end if;

  if p_details ? 'upi_id' or p_details ? 'bank_account' then
    insert into worker_payout_accounts (worker_id, upi_id, bank_account)
    values (wid, nullif(trim(coalesce(p_details->>'upi_id', '')), ''),
                 nullif(trim(coalesce(p_details->>'bank_account', '')), ''))
    on conflict (worker_id) do update
      set upi_id = case when p_details ? 'upi_id' then excluded.upi_id else worker_payout_accounts.upi_id end,
          bank_account = case when p_details ? 'bank_account'
                              then excluded.bank_account else worker_payout_accounts.bank_account end,
          updated_at = now();
  end if;

  return my_worker_profile();
end $$;
revoke all on function update_worker_profile(jsonb) from public;
grant execute on function update_worker_profile(jsonb) to anon, authenticated;

create or replace function set_worker_available(p_available boolean)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  wid uuid := current_worker_id();
begin
  if wid is null then raise exception 'Register as a worker first'; end if;
  update workers set is_available = coalesce(p_available, true) where worker_id = wid;
  return coalesce(p_available, true);
end $$;
revoke all on function set_worker_available(boolean) from public;
grant execute on function set_worker_available(boolean) to anon, authenticated;

notify pgrst, 'reload schema';
commit;

-- ============================================================
-- 0023_worker_availability.sql
-- ============================================================
-- When a worker is available at all: weekly working hours and days off.
--
-- Migration 0021 made a slot unavailable once a booking holds it. This adds
-- the worker's own side: worker_weekly_hours (one row per weekday, a window
-- or a day off) and worker_time_off (date ranges). Both tables belong to the
-- worker, whose id fills in by default, so the partner app writes them
-- directly. A worker with no weekly rows is available at any time, which
-- keeps every existing worker bookable.
--
-- The customer app keeps calling worker_taken_slots(worker, date): it now
-- also lists every half hour outside the working window, or the whole day
-- for a day off, so those slots show as unavailable without any app change.
-- The booking trigger refuses a new or moved booking outside the hours; a
-- status change on an existing booking is never re-checked, so adding a day
-- off later does not stop a job from being completed. Safe to run more than
-- once.
begin;

create table if not exists worker_weekly_hours (
  worker_id uuid not null default current_worker_id() references workers (worker_id) on delete cascade,
  weekday smallint not null check (weekday between 1 and 7),  -- 1 = Monday, 7 = Sunday (ISO)
  works boolean not null default true,
  start_time time not null default '08:00',
  end_time time not null default '19:00',
  updated_at timestamptz not null default now(),
  primary key (worker_id, weekday),
  check (end_time > start_time)
);
alter table worker_weekly_hours enable row level security;
drop policy if exists "own weekly hours" on worker_weekly_hours;
create policy "own weekly hours" on worker_weekly_hours
  for all
  using (worker_id = current_worker_id())
  with check (worker_id = current_worker_id());
grant select, insert, update, delete on worker_weekly_hours to anon, authenticated;

create table if not exists worker_time_off (
  time_off_id uuid primary key default gen_random_uuid(),
  worker_id uuid not null default current_worker_id() references workers (worker_id) on delete cascade,
  starts_on date not null,
  ends_on date not null,
  reason text,
  created_at timestamptz not null default now(),
  check (ends_on >= starts_on)
);
create index if not exists worker_time_off_worker_idx on worker_time_off (worker_id, starts_on);
alter table worker_time_off enable row level security;
drop policy if exists "own time off" on worker_time_off;
create policy "own time off" on worker_time_off
  for all
  using (worker_id = current_worker_id())
  with check (worker_id = current_worker_id());
grant select, insert, update, delete on worker_time_off to anon, authenticated;

-- True when the worker's own hours allow a job at that moment.
create or replace function worker_is_available_at(p_worker_id uuid, p_date date, p_time time)
returns boolean
language sql stable security definer set search_path = public as $$
  select not exists (
      select 1 from worker_time_off t
      where t.worker_id = p_worker_id and p_date between t.starts_on and t.ends_on)
    and coalesce((
      select h.works and p_time >= h.start_time and p_time < h.end_time
      from worker_weekly_hours h
      where h.worker_id = p_worker_id and h.weekday = extract(isodow from p_date)), true);
$$;
revoke all on function worker_is_available_at(uuid, date, time) from public;
grant execute on function worker_is_available_at(uuid, date, time) to anon, authenticated;

-- Every half hour of the day the worker is not working: all 48 on a day
-- off, otherwise the ones outside the window. Nothing when hours are unset.
create or replace function worker_blocked_times(p_worker_id uuid, p_date date)
returns setof time
language sql stable security definer set search_path = public as $$
  select t
  from generate_series(0, 47) as n, lateral (select (n * interval '30 minutes')::time) as s(t)
  where not worker_is_available_at(p_worker_id, p_date, s.t);
$$;
revoke all on function worker_blocked_times(uuid, date) from public;
grant execute on function worker_blocked_times(uuid, date) to anon, authenticated;

-- Held by a booking, or outside the worker's hours: either makes a slot
-- unavailable in the customer app.
create or replace function worker_taken_slots(p_worker_id uuid, p_date date)
returns setof time
language sql stable security definer set search_path = public as $$
  select booking_time from bookings
  where worker_id = p_worker_id
    and booking_date = p_date
    and status in ('pending', 'confirmed', 'in_progress')
  union
  select * from worker_blocked_times(p_worker_id, p_date);
$$;

create or replace function prevent_double_booking()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.worker_id is null
     or new.status not in ('pending', 'confirmed', 'in_progress') then
    return new;
  end if;
  if exists (
    select 1 from bookings b
    where b.worker_id = new.worker_id
      and b.booking_date = new.booking_date
      and b.booking_time = new.booking_time
      and b.status in ('pending', 'confirmed', 'in_progress')
      and b.booking_id <> new.booking_id
  ) then
    raise exception 'That time is no longer available for this worker'
      using errcode = 'unique_violation';
  end if;
  -- Only a new booking, or one moved to another worker, day or time, has
  -- to fall inside the worker's hours.
  if tg_op = 'INSERT'
     or new.worker_id is distinct from old.worker_id
     or new.booking_date is distinct from old.booking_date
     or new.booking_time is distinct from old.booking_time then
    if not worker_is_available_at(new.worker_id, new.booking_date, new.booking_time) then
      raise exception 'The worker is not available at that time'
        using errcode = 'check_violation';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists bookings_no_double_booking on bookings;
create trigger bookings_no_double_booking
  before insert or update of worker_id, booking_date, booking_time, status on bookings
  for each row execute function prevent_double_booking();

notify pgrst, 'reload schema';
commit;


-- BEGIN 0024_worker_applications.sql
-- Public partner applications, with private documents and one open application per phone.
-- Run after 0023. Safe to rerun. A submission is not an identity or worker account.
begin;

create table if not exists worker_applications (
  application_id uuid primary key default gen_random_uuid(),
  reference text not null unique default ('KA-' || upper(encode(gen_random_bytes(12), 'hex'))),
  status text not null default 'submitted' check (status in ('submitted','under_review','approved','rejected')),
  phone text not null,
  details jsonb not null,
  upload_token_hash text not null,
  upload_expires_at timestamptz not null default now() + interval '24 hours',
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  review_note text,
  worker_id uuid references workers(worker_id)
);
create unique index if not exists worker_applications_open_phone on worker_applications(phone)
  where status in ('submitted','under_review','approved');
create table if not exists worker_application_documents (
  application_id uuid not null references worker_applications(application_id) on delete cascade,
  doc_type text not null check (doc_type in ('photo','aadhaar_front','aadhaar_back','police_certificate','selfie')),
  storage_path text not null unique,
  content_type text not null check (content_type in ('image/jpeg','image/png','application/pdf')),
  byte_size integer not null check (byte_size between 1 and 10485760),
  submitted_at timestamptz not null default now(),
  primary key (application_id,doc_type)
);
alter table worker_applications enable row level security;
alter table worker_application_documents enable row level security;
revoke all on worker_applications,worker_application_documents from public,anon,authenticated;
grant all on worker_applications,worker_application_documents to service_role;

-- Normalize existing legacy formatting and Indian ten-digit numbers before
-- comparing identities. International numbers retain their country code.
create or replace function canonical_partner_phone(p_phone text)
returns text language sql immutable as $$
  select case when length(d)=10 then '+91'||d else '+'||d end
    from (select regexp_replace(coalesce(p_phone,''),'[^0-9]','','g') d) n;
$$;

create or replace function submit_worker_application(p_details jsonb)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare
  v_phone text := canonical_partner_phone(p_details->>'phone');
  v_email text := lower(trim(coalesce(p_details->>'email','')));
  v_token text := p_details->>'client_request_token';
  v_app worker_applications;
  svc text;
  v_bank jsonb := p_details->'bank_account';
begin
  if jsonb_typeof(p_details) is distinct from 'object' or octet_length(p_details::text)>16384 then
    raise exception 'INVALID_APPLICATION'; end if;
  if length(trim(coalesce(p_details->>'full_name',''))) not between 2 and 120 then raise exception 'INVALID_NAME'; end if;
  if v_phone !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'INVALID_PHONE'; end if;
  if length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
     or v_email like '%@partners.kaylo.app' then raise exception 'INVALID_EMAIL'; end if;
  if p_details->'consent' is distinct from 'true'::jsonb then raise exception 'CONSENT_REQUIRED'; end if;
  if length(trim(coalesce(p_details->>'profession',''))) not between 2 and 120
     or length(trim(coalesce(p_details->>'district',''))) not between 2 and 100 then raise exception 'INVALID_SERVICE_AREA'; end if;
  if coalesce(p_details->>'experience_years','') !~ '^[0-9]{1,2}$'
     or (p_details->>'experience_years')::int not between 0 and 70 then raise exception 'INVALID_EXPERIENCE'; end if;
  if coalesce(p_details->>'travel_radius_km','') !~ '^[0-9]{1,3}(\.[0-9]{1,2})?$'
     or (p_details->>'travel_radius_km')::numeric not between 1 and 100 then raise exception 'INVALID_RADIUS'; end if;
  if jsonb_typeof(p_details->'services') is distinct from 'array' then raise exception 'INVALID_SERVICES'; end if;
  if jsonb_array_length(p_details->'services') not between 1 and 30 then raise exception 'INVALID_SERVICES'; end if;
  for svc in select jsonb_array_elements_text(p_details->'services') loop
    if not exists(select 1 from services where service_id::text=svc and is_active) then raise exception 'INVALID_SERVICES'; end if;
  end loop;
  if coalesce(p_details->>'upi_id','') !~ '^[A-Za-z0-9._-]{2,255}@[A-Za-z0-9.-]{2,64}$' then
    if jsonb_typeof(v_bank) is distinct from 'object'
      or coalesce(v_bank->>'account_number','') !~ '^[0-9]{6,20}$'
      or coalesce(v_bank->>'ifsc','') !~ '^[A-Z]{4}0[A-Z0-9]{6}$'
      or length(trim(coalesce(v_bank->>'account_holder',''))) not between 2 and 120
      or length(trim(coalesce(v_bank->>'bank_name',''))) not between 2 and 120 then raise exception 'INVALID_PAYOUT'; end if;
  end if;
  if coalesce(v_token,'') !~ '^[0-9a-f]{64}$' then raise exception 'INVALID_REQUEST_TOKEN'; end if;
  -- Serialize phone checks even for repeated concurrent unauthenticated submits.
  perform pg_advisory_xact_lock(hashtextextended(v_phone,2400));
  select * into v_app from worker_applications where phone=v_phone
    and upload_token_hash=encode(digest(v_token,'sha256'),'hex')
    and status in ('submitted','under_review') and upload_expires_at>now();
  if found then return jsonb_build_object('application_id',v_app.application_id,'reference',v_app.reference,
    'upload_token',v_token,'upload_expires_at',v_app.upload_expires_at,'status',v_app.status); end if;
  if exists(select 1 from worker_applications where phone=v_phone and
      (status in ('submitted','under_review','approved') or submitted_at>now()-interval '24 hours')) then
    raise exception 'APPLICATION_ALREADY_EXISTS'; end if;
  if exists(select 1 from persons p where
      canonical_partner_phone(p.phone_number)=v_phone or lower(p.email)=v_email) then
    raise exception 'IDENTITY_ALREADY_IN_USE'; end if;
  insert into worker_applications(phone,details,upload_token_hash)
  values(v_phone,(p_details - 'client_request_token') || jsonb_build_object('phone',v_phone,'email',v_email),encode(digest(v_token,'sha256'),'hex'))
  returning * into v_app;
  return jsonb_build_object('application_id',v_app.application_id,'reference',v_app.reference,
    'upload_token',v_token,'upload_expires_at',v_app.upload_expires_at,'status',v_app.status);
end $$;
revoke all on function submit_worker_application(jsonb) from public;
grant execute on function submit_worker_application(jsonb) to anon,authenticated;

create or replace function worker_application_status(p_reference text)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('reference',a.reference,'status',a.status,
    'documents_received',(select count(*) from worker_application_documents d where d.application_id=a.application_id))
  from worker_applications a where a.reference=upper(trim(p_reference));
$$;
revoke all on function worker_application_status(text) from public;
grant execute on function worker_application_status(text) to anon,authenticated;

-- Called only after the edge has uploaded and checked the object. The lock
-- serializes the final record with an admin review; approved evidence is immutable.
create or replace function record_worker_application_document(p_application_id uuid,p_token text,
  p_doc_type text,p_path text,p_content_type text,p_byte_size integer)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare a worker_applications;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found or a.status not in ('submitted','under_review') or a.upload_expires_at<now()
    or encode(digest(p_token,'sha256'),'hex')<>a.upload_token_hash then raise exception 'UPLOAD_NOT_ALLOWED'; end if;
  if p_path not like 'applications/'||p_application_id::text||'/'||p_doc_type||'/%'
    or p_path like '%..%' then raise exception 'INVALID_DOCUMENT_PATH'; end if;
  if not exists(select 1 from storage.objects where bucket_id='worker-documents' and name=p_path) then
    raise exception 'DOCUMENT_NOT_UPLOADED'; end if;
  -- Never replace the reviewed file at the same path. New uploads get fresh UUIDs.
  insert into worker_application_documents(application_id,doc_type,storage_path,content_type,byte_size)
    values(p_application_id,p_doc_type,p_path,p_content_type,p_byte_size)
    on conflict(application_id,doc_type) do update set storage_path=excluded.storage_path,
      content_type=excluded.content_type,byte_size=excluded.byte_size,submitted_at=now();
  if (select count(*) from worker_application_documents where application_id=p_application_id)=5 then
    update worker_applications set status='under_review' where application_id=p_application_id; end if;
end $$;
revoke all on function record_worker_application_document(uuid,text,text,text,text,integer) from public,anon,authenticated;
grant execute on function record_worker_application_document(uuid,text,text,text,text,integer) to service_role;

notify pgrst, 'reload schema';
commit;
-- END 0024_worker_applications.sql


-- BEGIN 0025_issued_partner_identities.sql
-- Kaylo-issued partner identities, admin review and strict role separation.
-- Run after 0024. Safe to rerun. No password or password hash is stored here.
begin;
create sequence if not exists kaylo_partner_id_seq maxvalue 999999;
alter table workers add column if not exists partner_id text unique;
alter table workers add column if not exists must_change_password boolean not null default true;
alter table workers drop constraint if exists workers_partner_id_format;
alter table workers add constraint workers_partner_id_format check (partner_id is null or partner_id ~ '^KP-[0-9]{6}$');
create table if not exists partner_credentials (
  worker_id uuid primary key references workers(worker_id) on delete cascade,
  issuance_id uuid not null,
  firebase_uid text not null unique,
  state text not null check(state in ('issuing','ready','delivered','failed')),
  lock_expires_at timestamptz,
  password_updated_at_ms numeric,
  issued_at timestamptz,
  delivered_at timestamptz
);
alter table partner_credentials enable row level security;
revoke all on partner_credentials from public,anon,authenticated;
grant all on partner_credentials to service_role;
insert into roles(role_name) values ('worker'),('customer') on conflict(role_name) do nothing;
-- Preserve legacy marketplace profiles and booking history. Conflicting old
-- identities are quarantined, never silently deleted or given dual access.
update persons p set account_status='suspended' where exists(select 1 from workers w where w.person_id=p.person_id)
  and exists(select 1 from customers c where c.person_id=p.person_id) and p.account_status='active';
insert into person_roles(person_id,role_id)
  select w.person_id,r.role_id from workers w cross join roles r where r.role_name='worker'
    and not exists(select 1 from customers c where c.person_id=w.person_id)
    and not exists(select 1 from person_roles pr where pr.person_id=w.person_id and pr.role_id=r.role_id)
  on conflict(person_id,role_id) do nothing;
insert into person_roles(person_id,role_id)
  select c.person_id,r.role_id from customers c cross join roles r where r.role_name='customer'
    and not exists(select 1 from workers w where w.person_id=c.person_id)
    and not exists(select 1 from person_roles pr where pr.person_id=c.person_id and pr.role_id=r.role_id)
  on conflict(person_id,role_id) do nothing;

create or replace function enforce_single_person_role()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_person uuid := new.person_id; v_role text;
begin
  perform 1 from persons where person_id=v_person for update;
  if tg_table_name='person_roles' then select role_name into v_role from roles where role_id=new.role_id;
  elsif tg_table_name='customers' then v_role:='customer'; else v_role:='worker'; end if;
  if v_role='customer' and (exists(select 1 from workers where person_id=v_person) or exists(
    select 1 from person_roles pr join roles r using(role_id) where pr.person_id=v_person and r.role_name='worker')) then
    raise exception 'PARTNER_ACCOUNT_NOT_ALLOWED'; end if;
  if v_role='worker' and (exists(select 1 from customers where person_id=v_person) or exists(
    select 1 from person_roles pr join roles r using(role_id) where pr.person_id=v_person and r.role_name='customer')) then
    raise exception 'CUSTOMER_ACCOUNT_NOT_ALLOWED'; end if;
  return new;
end $$;
drop trigger if exists customers_single_role on customers;
create trigger customers_single_role before insert or update of person_id on customers for each row execute function enforce_single_person_role();
drop trigger if exists workers_single_role on workers;
create trigger workers_single_role before insert or update of person_id on workers for each row execute function enforce_single_person_role();
drop trigger if exists person_roles_single_role on person_roles;
create trigger person_roles_single_role before insert or update on person_roles for each row execute function enforce_single_person_role();

create or replace function caller_is_partner_identity()
returns boolean language sql stable as $$
  select coalesce(auth.jwt()->>'kaylo_role'='worker',false)
    or lower(coalesce(auth.jwt()->>'email','')) like '%@partners.kaylo.app';
$$;
create or replace function issued_partner_session(p_worker uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from workers w join persons p using(person_id) join partner_credentials c using(worker_id)
    where w.worker_id=p_worker and p.auth_user_id=current_auth_subject() and p.account_status='active'
      and w.partner_id=auth.jwt()->>'kaylo_partner_id' and auth.jwt()->>'kaylo_role'='worker'
      and auth.jwt()->'firebase'->>'sign_in_provider'='password'
      and c.issuance_id::text=auth.jwt()->>'kaylo_issuance_id'
      and coalesce((auth.jwt()->>'auth_time')::numeric,0)>=floor(c.password_updated_at_ms/1000)
      and c.firebase_uid=p.auth_user_id and c.state in ('ready','delivered') and c.issued_at is not null);
$$;
create or replace function current_worker_id()
returns uuid language sql stable security definer set search_path=public as $$
  select w.worker_id from workers w join persons p using(person_id)
    where p.auth_user_id=current_auth_subject() and issued_partner_session(w.worker_id)
      and not w.must_change_password and w.verification_status='verified';
$$;
create or replace function current_person_id()
returns uuid language sql stable security definer set search_path=public as $$
  select p.person_id from persons p where p.auth_user_id=current_auth_subject() and p.account_status='active'
    and case when exists(select 1 from workers w where w.person_id=p.person_id)
      then exists(select 1 from workers w where w.person_id=p.person_id and w.worker_id=current_worker_id())
      else not caller_is_partner_identity() end;
$$;
create or replace function current_customer_id()
returns uuid language sql stable security definer set search_path=public as $$
  select c.customer_id from customers c where c.person_id=current_person_id()
    and not exists(select 1 from person_roles pr join roles r using(role_id) where pr.person_id=c.person_id and r.role_name='worker');
$$;
-- Closed legacy paths: account creation only goes through reviewed applications.
revoke all on function register_worker(jsonb) from public,anon,authenticated;
drop policy if exists "workers create self" on workers;
drop policy if exists "workers update self" on workers;
revoke insert,update,delete on workers from public,anon,authenticated;
revoke insert,update,delete on worker_services from public,anon,authenticated;
-- A customer must not create a reserved identity before an admin links it.
drop policy if exists "self insert" on persons;
create policy "self insert" on persons for insert to anon,authenticated
  with check(auth_user_id=current_auth_subject() and not caller_is_partner_identity()
    and lower(coalesce(email,'')) not like '%@partners.kaylo.app' and account_status='active');
revoke update on persons from public,anon,authenticated;
grant update(full_name,phone_number,email,profile_photo,date_of_birth,gender,language,updated_at) on persons to anon,authenticated;
revoke insert,update,delete on person_roles from public,anon,authenticated;

create or replace function ensure_customer_profile()
returns void language plpgsql security definer set search_path=public as $$
declare me uuid;
begin
  select person_id into me from persons where auth_user_id=current_auth_subject() for update;
  if caller_is_partner_identity() or exists(select 1 from workers where person_id=me)
    or exists(select 1 from person_roles pr join roles r using(role_id) where pr.person_id=me and r.role_name='worker') then
    raise exception 'PARTNER_ACCOUNT_NOT_ALLOWED'; end if;
  if me is null or me is distinct from current_person_id() then raise exception 'SIGN_IN_REQUIRED'; end if;
  insert into person_roles(person_id,role_id) select me,role_id from roles where role_name='customer'
    on conflict(person_id,role_id) do nothing;
  insert into customers(person_id) values(me) on conflict(person_id) do nothing;
end $$;
revoke all on function ensure_customer_profile() from public;
grant execute on function ensure_customer_profile() to anon,authenticated;

create or replace function partner_login_state()
returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object('partner_id',w.partner_id,'person_id',p.person_id,'worker_id',w.worker_id,
    'must_change_password',w.must_change_password,'verification_status',w.verification_status)
  from workers w join persons p using(person_id) where p.auth_user_id=current_auth_subject()
    and issued_partner_session(w.worker_id);
$$;
revoke all on function partner_login_state() from public;
grant execute on function partner_login_state() to anon,authenticated;

create or replace function approve_worker_application(p_application_id uuid,p_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare a worker_applications; pid uuid; wid uuid; svc text;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found then raise exception 'APPLICATION_NOT_FOUND'; end if;
  if a.status not in ('submitted','under_review') then raise exception 'APPLICATION_ALREADY_REVIEWED'; end if;
  if (select count(*) from worker_application_documents d join storage.objects o
    on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=p_application_id)<>5 then
    raise exception 'ALL_DOCUMENTS_REQUIRED'; end if;
  if exists(select 1 from persons where canonical_partner_phone(phone_number)=a.phone
      or lower(email)=lower(a.details->>'email')) then raise exception 'IDENTITY_ALREADY_IN_USE'; end if;
  insert into persons(full_name,phone_number,email,profile_photo)
    values(trim(a.details->>'full_name'),a.phone,lower(a.details->>'email'),
      (select storage_path from worker_application_documents where application_id=p_application_id and doc_type='photo')) returning person_id into pid;
  insert into workers(person_id,experience_years,travel_radius_km,bio,verification_status,is_available,partner_id)
    values(pid,(a.details->>'experience_years')::int,(a.details->>'travel_radius_km')::numeric,
      a.details->>'profession','verified',false,'KP-'||lpad(nextval('kaylo_partner_id_seq')::text,6,'0')) returning worker_id into wid;
  insert into person_roles(person_id,role_id) select pid,role_id from roles where role_name='worker';
  for svc in select jsonb_array_elements_text(a.details->'services') loop
    insert into worker_services(worker_id,service_id,experience_years)
      values(wid,svc::uuid,(a.details->>'experience_years')::int) on conflict(worker_id,service_id) do nothing;
  end loop;
  insert into locations(person_id,district,is_default,nickname) values(pid,a.details->>'district',true,'Work area');
  insert into worker_payout_accounts(worker_id,upi_id,bank_account)
    values(wid,nullif(a.details->>'upi_id',''),case when a.details ? 'bank_account' then (a.details->'bank_account')::text end);
  -- Calling approval is the admin's explicit attestation that all five supplied
  -- documents were reviewed. Record that decision, not invented check methods.
  insert into worker_documents(worker_id,doc_type,storage_path,status,note,reviewed_at)
    select wid,doc_type,storage_path,'verified',
      coalesce(nullif(trim(p_note),''),'Application documents reviewed by Kaylo.'),now()
    from worker_application_documents where application_id=p_application_id;
  update worker_applications set status='approved',worker_id=wid,reviewed_at=now(),review_note=p_note,
    upload_expires_at=now() where application_id=p_application_id;
  return wid;
end $$;
create or replace function reject_worker_application(p_application_id uuid,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
begin
  perform 1 from worker_applications where application_id=p_application_id for update;
  update worker_applications set status='rejected',reviewed_at=now(),review_note=p_note,upload_expires_at=now()
    where application_id=p_application_id and status in ('submitted','under_review');
  if not found then raise exception 'APPLICATION_ALREADY_REVIEWED'; end if;
end $$;
revoke all on function approve_worker_application(uuid,text),reject_worker_application(uuid,text) from public,anon,authenticated;
grant execute on function approve_worker_application(uuid,text),reject_worker_application(uuid,text) to service_role;

-- One issuance lease at a time, including support resets. The worker loses
-- private access before Firebase is touched. Retries after a failure rotate
-- the password again; no plaintext credential is persisted for retries.
create or replace function begin_partner_credential_issue(p_worker_id uuid,p_reset boolean default false)
returns jsonb language plpgsql security definer set search_path=public as $$
declare w workers; p persons; c partner_credentials; op uuid:=gen_random_uuid(); uid text;
begin
  select * into w from workers where worker_id=p_worker_id for update;
  if not found or w.verification_status<>'verified' or not exists(select 1 from worker_applications
    where worker_id=p_worker_id and status='approved') then raise exception 'APPROVED_APPLICATION_REQUIRED'; end if;
  select * into p from persons where person_id=w.person_id;
  if p.account_status<>'active' then raise exception 'ACCOUNT_NOT_ACTIVE'; end if;
  select * into c from partner_credentials where worker_id=p_worker_id;
  if c.state in ('issuing','ready') and c.lock_expires_at>now() then raise exception 'ISSUANCE_IN_PROGRESS'; end if;
  if c.state='delivered' and not p_reset then
    return jsonb_build_object('already_issued',true,'partner_id',w.partner_id); end if;
  uid:='kaylo_partner_'||replace(p_worker_id::text,'-','');
  if p.auth_user_id is not null and p.auth_user_id<>uid then raise exception 'IDENTITY_ALREADY_LINKED'; end if;
  update workers set must_change_password=true,is_available=false where worker_id=p_worker_id;
  insert into partner_credentials(worker_id,issuance_id,firebase_uid,state,lock_expires_at)
    values(p_worker_id,op,uid,'issuing',now()+interval '10 minutes')
    on conflict(worker_id) do update set issuance_id=op,state='issuing',password_updated_at_ms=null,
      issued_at=null,delivered_at=null,lock_expires_at=excluded.lock_expires_at;
  return jsonb_build_object('issuance_id',op,'worker_id',w.worker_id,'firebase_uid',uid,
    'partner_id',w.partner_id,'email',p.email,'phone',p.phone_number,'name',p.full_name);
end $$;
create or replace function finish_partner_credential_issue(p_worker_id uuid,p_issuance_id uuid,p_password_updated_at_ms numeric)
returns void language plpgsql security definer set search_path=public as $$
declare c partner_credentials;
begin
  select * into c from partner_credentials where worker_id=p_worker_id for update;
  if not found or c.issuance_id<>p_issuance_id or c.state<>'issuing' or c.lock_expires_at<now()
    or p_password_updated_at_ms is null or p_password_updated_at_ms<=0 then raise exception 'INVALID_ISSUANCE'; end if;
  update persons set auth_user_id=c.firebase_uid where person_id=(select person_id from workers where worker_id=p_worker_id);
  update partner_credentials set state='ready',issued_at=now(),password_updated_at_ms=p_password_updated_at_ms
    where worker_id=p_worker_id;
end $$;
create or replace function mark_password_changed(p_worker_id uuid,p_issuance_id uuid,p_password_updated_at_ms numeric)
returns void language plpgsql security definer set search_path=public as $$
declare c partner_credentials;
begin
  select * into c from partner_credentials where worker_id=p_worker_id for update;
  if not found or c.issuance_id<>p_issuance_id or c.state not in ('ready','delivered')
    or c.password_updated_at_ms is null or p_password_updated_at_ms is null
    or p_password_updated_at_ms<=c.password_updated_at_ms then raise exception 'PASSWORD_CHANGE_NOT_VERIFIED'; end if;
  update workers set must_change_password=false where worker_id=p_worker_id;
end $$;
revoke all on function begin_partner_credential_issue(uuid,boolean),finish_partner_credential_issue(uuid,uuid,numeric),
  mark_password_changed(uuid,uuid,numeric) from public,anon,authenticated;
grant execute on function begin_partner_credential_issue(uuid,boolean),finish_partner_credential_issue(uuid,uuid,numeric),
  mark_password_changed(uuid,uuid,numeric) to service_role;

-- Application evidence stays admin-managed after approval. The old worker
-- upload path can no longer replace the supplied identity documents.
drop policy if exists "submit own documents" on worker_documents;
drop policy if exists "replace own pending documents" on worker_documents;
revoke insert,update,delete on worker_documents from anon,authenticated;
drop policy if exists "workers upload own documents" on storage.objects;
drop policy if exists "workers replace own documents" on storage.objects;
-- Approved workers may read their application evidence, with their current issued session.
drop policy if exists "workers read application documents" on storage.objects;
create policy "workers read application documents" on storage.objects for select to anon,authenticated
  using(bucket_id='worker-documents' and exists(select 1 from worker_documents d
    where d.worker_id=current_worker_id() and d.storage_path=name));

-- Preserve deletion retries without letting a gated session delete Firebase alone.
create or replace function delete_current_kaylo_account()
returns text language plpgsql security definer set search_path=public as $$
declare uid text:=current_auth_subject(); pid uuid:=current_person_id();
begin
  if uid is null then raise exception 'Sign in first'; end if;
  -- A password/review gate returning NULL is not evidence the person was deleted.
  if pid is null and (exists(select 1 from persons where auth_user_id=uid)
    or not exists(select 1 from account_deletion_requests where auth_subject=uid)) then
    raise exception 'ACCOUNT_ACCESS_REQUIRED'; end if;
  if coalesce((auth.jwt()->>'auth_time')::bigint,0) < extract(epoch from now()-interval '30 minutes') then
    raise exception 'Please sign out and sign in again before deleting your account';
  end if;
  if exists(select 1 from bookings b where (b.customer_id=current_customer_id() or b.worker_id=current_worker_id()) and (b.status in ('confirmed','in_progress') or (b.status='pending' and exists(select 1 from payments p where p.booking_id=b.booking_id and p.payment_status='success')))) then
    raise exception 'Complete or cancel active bookings before deleting your account. Contact kayloapp@gmail.com for unresolved payments.';
  end if;
  insert into account_deletion_requests(auth_subject) values(uid) on conflict do nothing;
  delete from email_otps where email in (select email from persons where person_id=pid);
  delete from persons where person_id=pid;
  return uid;
end $$;

notify pgrst, 'reload schema';
commit;
-- END 0025_issued_partner_identities.sql


-- BEGIN 0026_worker_application_notifications.sql
-- A small durable delivery lease for completed partner application emails.
-- Run after 0025. Safe to rerun. No applicant secrets enter notification state.
begin;
alter table worker_applications add column if not exists admin_notified_at timestamptz;
alter table worker_applications add column if not exists admin_notification_claim uuid;
alter table worker_applications add column if not exists admin_notification_lease_until timestamptz;

create or replace function claim_worker_application_notification(p_application_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare a worker_applications; claim uuid;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found then return jsonb_build_object('state','not_required'); end if;
  if a.admin_notified_at is not null then return jsonb_build_object('state','sent'); end if;
  if a.status<>'under_review' or (select count(*) from worker_application_documents d
    join storage.objects o on o.bucket_id='worker-documents' and o.name=d.storage_path
    where d.application_id=p_application_id)<>5 then
    return jsonb_build_object('state','not_required'); end if;
  if a.admin_notification_claim is not null and a.admin_notification_lease_until>now() then
    return jsonb_build_object('state','busy'); end if;
  claim:=gen_random_uuid();
  update worker_applications set admin_notification_claim=claim,
    admin_notification_lease_until=now()+interval '5 minutes'
    where application_id=p_application_id;
  return jsonb_build_object('state','claimed','claim_id',claim,'reference',a.reference);
end $$;

create or replace function finish_worker_application_notification(
  p_application_id uuid,p_claim_id uuid,p_sent boolean)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  -- The claim ID fences off a slow sender after another retry took its lease.
  update worker_applications set
    admin_notified_at=case when p_sent is true then now() else admin_notified_at end,
    admin_notification_claim=null,admin_notification_lease_until=null
    where application_id=p_application_id and admin_notification_claim=p_claim_id
      and p_claim_id is not null;
  return found;
end $$;
revoke all on function claim_worker_application_notification(uuid),
  finish_worker_application_notification(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function claim_worker_application_notification(uuid),
  finish_worker_application_notification(uuid,uuid,boolean) to service_role;

notify pgrst, 'reload schema';
commit;
-- END 0026_worker_application_notifications.sql


-- BEGIN 0027_partner_admin_review.sql
-- Kaylo admin review, correction history, certificates and durable email delivery.
-- Run after 0026. Safe to rerun. All admin operations require an active actor.
begin;

create table if not exists admin_users (
  firebase_uid text primary key check(length(firebase_uid) between 1 and 128),
  email text not null,
  role text not null check(role in ('reviewer','admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
-- The name is intentionally explicit in SQL and matches the edge admin registry.
alter table worker_applications add column if not exists version integer not null default 1 check(version>0);
alter table worker_applications add column if not exists correction_version integer;
alter table worker_applications add column if not exists correction_expires_at timestamptz;
alter table worker_applications drop constraint if exists worker_applications_status_check;
alter table worker_applications add constraint worker_applications_status_check
  check(status in ('submitted','under_review','changes_requested','approved','rejected'));
drop index if exists worker_applications_open_phone;
create unique index worker_applications_open_phone on worker_applications(phone)
  where status in ('submitted','under_review','changes_requested','approved');
create index if not exists worker_applications_review_queue on worker_applications(status,submitted_at desc);

create table if not exists worker_application_audit (
  event_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references worker_applications(application_id),
  application_version integer not null,
  action text not null,
  actor_uid text,
  actor_email text,
  actor_role text,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index if not exists worker_application_audit_timeline on worker_application_audit(application_id,created_at,event_id);
create table if not exists worker_application_corrections (
  application_id uuid not null references worker_applications(application_id),
  request_version integer not null,
  doc_type text not null check(doc_type in ('photo','aadhaar_front','aadhaar_back','police_certificate','selfie')),
  note text not null,
  requested_at timestamptz not null default now(),
  requested_by text not null,
  received_at timestamptz,
  storage_path text,
  primary key(application_id,request_version,doc_type)
);
create table if not exists worker_application_document_history (
  history_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references worker_applications(application_id),
  application_version integer not null,
  doc_type text not null,
  storage_path text not null,
  content_type text not null,
  byte_size integer not null,
  uploaded_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  unique(application_id,doc_type,storage_path)
);
create index if not exists worker_application_document_history_lookup
  on worker_application_document_history(application_id,doc_type,recorded_at);
create table if not exists partner_certificates (
  certificate_id uuid primary key default gen_random_uuid(),
  certificate_number text not null unique default ('KC-'||to_char(now(),'YYYY')||'-'||upper(encode(gen_random_bytes(6),'hex'))),
  application_id uuid not null unique references worker_applications(application_id),
  worker_id uuid not null unique references workers(worker_id),
  application_version integer not null,
  issued_at timestamptz not null default now(),
  issued_by text not null,
  checked_document_types text[] not null,
  snapshot jsonb not null
);
create table if not exists application_mail_outbox (
  mail_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references worker_applications(application_id),
  application_version integer not null,
  kind text not null check(kind in ('submitted','approved','rejected','changes_requested')),
  recipient_email text not null,
  template_data jsonb not null,
  status text not null default 'pending' check(status in ('pending','sending','sent','failed')),
  attempts integer not null default 0,
  last_error text,
  claim_id uuid,
  lease_until timestamptz,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  unique(application_id,application_version,kind)
);
create index if not exists application_mail_outbox_delivery on application_mail_outbox(status,created_at);
create index if not exists application_mail_outbox_application on application_mail_outbox(application_id,created_at desc);

alter table admin_users enable row level security;
alter table worker_application_audit enable row level security;
alter table worker_application_corrections enable row level security;
alter table worker_application_document_history enable row level security;
alter table partner_certificates enable row level security;
alter table application_mail_outbox enable row level security;
revoke all on admin_users,worker_application_audit,worker_application_corrections,
  worker_application_document_history,partner_certificates,application_mail_outbox from public,anon,authenticated;
grant all on admin_users,worker_application_audit,worker_application_corrections,
  worker_application_document_history,partner_certificates,application_mail_outbox to service_role;

-- Service clients may append, but cannot rewrite or truncate immutable evidence.
revoke update,delete,truncate on worker_application_audit,worker_application_document_history,partner_certificates from service_role;

create or replace function require_application_admin(p_actor_uid text,p_write_decision boolean default false)
returns admin_users language plpgsql stable security definer set search_path=public as $$
declare actor admin_users;
begin
  select * into actor from admin_users where firebase_uid=p_actor_uid and is_active;
  if not found then raise exception 'ADMIN_ACCESS_REQUIRED'; end if;
  if p_write_decision and actor.role<>'admin' then raise exception 'ADMIN_DECISION_REQUIRED'; end if;
  return actor;
end $$;
revoke all on function require_application_admin(text,boolean) from public,anon,authenticated;
grant execute on function require_application_admin(text,boolean) to service_role;

create or replace function immutable_application_record()
returns trigger language plpgsql as $$
begin raise exception 'IMMUTABLE_APPLICATION_RECORD'; end $$;
drop trigger if exists worker_application_audit_immutable on worker_application_audit;
create trigger worker_application_audit_immutable before update or delete on worker_application_audit
  for each row execute function immutable_application_record();
drop trigger if exists worker_application_history_immutable on worker_application_document_history;
create trigger worker_application_history_immutable before update or delete on worker_application_document_history
  for each row execute function immutable_application_record();
drop trigger if exists partner_certificates_immutable on partner_certificates;
create trigger partner_certificates_immutable before update or delete on partner_certificates
  for each row execute function immutable_application_record();

-- Retain existing evidence before enabling history on subsequent replacements.
insert into worker_application_document_history(application_id,application_version,doc_type,storage_path,content_type,byte_size,uploaded_at)
  select d.application_id,a.version,d.doc_type,d.storage_path,d.content_type,d.byte_size,d.submitted_at
  from worker_application_documents d join worker_applications a using(application_id)
  on conflict(application_id,doc_type,storage_path) do nothing;
create or replace function audit_worker_application_document()
returns trigger language plpgsql security definer set search_path=public as $$
declare v integer;
begin
  if tg_op='UPDATE' and new.storage_path=old.storage_path and new.content_type=old.content_type and new.byte_size=old.byte_size then return new;end if;
  update worker_applications set version=version+1 where application_id=new.application_id returning version into v;
  insert into worker_application_document_history(application_id,application_version,doc_type,storage_path,content_type,byte_size,uploaded_at)
    values(new.application_id,v,new.doc_type,new.storage_path,new.content_type,new.byte_size,new.submitted_at)
    on conflict(application_id,doc_type,storage_path) do nothing;
  insert into worker_application_audit(application_id,application_version,action,data)
    values(new.application_id,v,case when tg_op='INSERT' then 'document_uploaded' else 'document_replaced' end,
      jsonb_build_object('doc_type',new.doc_type,'storage_path',new.storage_path,
        'previous_path',case when tg_op='UPDATE' then old.storage_path else null end));
  return new;
end $$;
drop trigger if exists worker_application_document_audit on worker_application_documents;
create trigger worker_application_document_audit after insert or update on worker_application_documents
  for each row execute function audit_worker_application_document();

create or replace function queue_application_mail(p_application_id uuid,p_version integer,p_kind text,p_recipient text,p_data jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare id uuid;
begin
  insert into application_mail_outbox(application_id,application_version,kind,recipient_email,template_data)
    values(p_application_id,p_version,p_kind,p_recipient,p_data)
    on conflict(application_id,application_version,kind) do nothing;
  select mail_id into id from application_mail_outbox where application_id=p_application_id
    and application_version=p_version and kind=p_kind;
  return id;
end $$;
revoke all on function queue_application_mail(uuid,integer,text,text,jsonb) from public,anon,authenticated;
grant execute on function queue_application_mail(uuid,integer,text,text,jsonb) to service_role;

create or replace function queue_completed_application_review()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status='under_review' and old.status is distinct from new.status
    and (select count(*) from worker_application_documents d join storage.objects o
      on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=new.application_id)=5 then
    perform queue_application_mail(new.application_id,new.version,'submitted','kayloapp@gmail.com',
      jsonb_build_object('reference',new.reference,'application_id',new.application_id,'version',new.version));
  end if;
  -- Migration 0026 compatibility: a completed old-sender acknowledgement must
  -- not cause the newer outbox to deliver the same initial alert again.
  if new.admin_notified_at is not null and old.admin_notified_at is distinct from new.admin_notified_at then
    update application_mail_outbox set status='sent',sent_at=new.admin_notified_at,claim_id=null,lease_until=null,last_error=null
      where mail_id=(select mail_id from application_mail_outbox where application_id=new.application_id
        and kind='submitted' order by application_version desc limit 1) and status<>'sent';
  end if;
  return new;
end $$;
drop trigger if exists worker_application_review_mail on worker_applications;
create trigger worker_application_review_mail after update of status,admin_notified_at on worker_applications
  for each row execute function queue_completed_application_review();

create or replace function get_application_for_correction(p_application_id uuid,p_version integer)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a worker_applications;
begin
  select * into a from worker_applications where application_id=p_application_id;
  if not found or a.correction_version is distinct from p_version then raise exception 'CORRECTION_LINK_INVALID';end if;
  if a.correction_expires_at is null or a.correction_expires_at<=now() then raise exception 'CORRECTION_LINK_EXPIRED';end if;
  return jsonb_build_object('application_id',a.application_id,'reference',a.reference,'version',a.correction_version,
    'correction_version',a.correction_version,'application_version',a.version,'status',a.status,
    'completed',a.status<>'changes_requested','expires_at',a.correction_expires_at,
    'requested_documents',coalesce((select jsonb_agg(jsonb_build_object('doc_type',c.doc_type,'note',c.note,
      'received',c.received_at is not null) order by c.doc_type) from worker_application_corrections c
      where c.application_id=a.application_id and c.request_version=p_version),'[]'::jsonb));
end $$;
revoke all on function get_application_for_correction(uuid,integer) from public,anon,authenticated;
grant execute on function get_application_for_correction(uuid,integer) to service_role;

create or replace function record_application_correction(p_application_id uuid,p_version integer,p_doc_type text,
  p_path text,p_content_type text,p_byte_size integer)
returns jsonb language plpgsql security definer set search_path=public as $$
declare a worker_applications; v integer;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found or a.status<>'changes_requested' or a.correction_version is distinct from p_version
    then raise exception 'CORRECTION_NOT_ALLOWED';end if;
  if a.correction_expires_at<=now() then raise exception 'CORRECTION_LINK_EXPIRED';end if;
  if not exists(select 1 from worker_application_corrections where application_id=p_application_id
    and request_version=p_version and doc_type=p_doc_type) then raise exception 'DOCUMENT_NOT_REQUESTED';end if;
  if p_path not like 'applications/'||p_application_id::text||'/corrections/'||p_version::text||'/'||p_doc_type||'/%'
    or p_path like '%..%' then raise exception 'INVALID_DOCUMENT_PATH';end if;
  if p_content_type not in ('image/jpeg','image/png','application/pdf') or p_byte_size not between 1 and 10485760
    or (p_doc_type in ('photo','selfie') and p_content_type='application/pdf') then raise exception 'INVALID_DOCUMENT';end if;
  if not exists(select 1 from storage.objects where bucket_id='worker-documents' and name=p_path) then raise exception 'DOCUMENT_NOT_UPLOADED';end if;
  insert into worker_application_documents(application_id,doc_type,storage_path,content_type,byte_size)
    values(p_application_id,p_doc_type,p_path,p_content_type,p_byte_size)
    on conflict(application_id,doc_type) do update set storage_path=excluded.storage_path,
      content_type=excluded.content_type,byte_size=excluded.byte_size,submitted_at=now();
  update worker_application_corrections set received_at=now(),storage_path=p_path
    where application_id=p_application_id and request_version=p_version and doc_type=p_doc_type;
  select version into v from worker_applications where application_id=p_application_id;
  insert into worker_application_audit(application_id,application_version,action,data)
    values(p_application_id,v,'correction_received',jsonb_build_object('request_version',p_version,'doc_type',p_doc_type));
  if not exists(select 1 from worker_application_corrections where application_id=p_application_id and request_version=p_version and received_at is null)
    and (select count(*) from worker_application_documents d join storage.objects o
      on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=p_application_id)=5 then
    update worker_applications set status='under_review',version=version+1,review_note=null
      where application_id=p_application_id returning version into v;
    insert into worker_application_audit(application_id,application_version,action,data)
      values(p_application_id,v,'corrections_completed',jsonb_build_object('request_version',p_version));
  end if;
  return get_application_for_correction(p_application_id,p_version);
end $$;
revoke all on function record_application_correction(uuid,integer,text,text,text,integer) from public,anon,authenticated;
grant execute on function record_application_correction(uuid,integer,text,text,text,integer) to service_role;

create or replace function admin_review_application(p_actor_uid text,p_application_id uuid,p_expected_version integer,
  p_action text,p_note text default null,p_document_types text[] default '{}')
returns jsonb language plpgsql security definer set search_path=public as $$
declare actor admin_users; a worker_applications; next_version integer; docs text[];
  required_docs constant text[]:=array['aadhaar_back','aadhaar_front','photo','police_certificate','selfie'];
  wid uuid; cert uuid; cert_number text; snap jsonb; doc text;
begin
  if p_action not in ('approve','reject','request_changes') then raise exception 'INVALID_REVIEW_ACTION';end if;
  actor:=require_application_admin(p_actor_uid,p_action in ('approve','reject'));
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found then raise exception 'APPLICATION_NOT_FOUND';end if;
  if a.version is distinct from p_expected_version then raise exception 'APPLICATION_VERSION_CONFLICT';end if;
  if a.status in ('approved','rejected') then raise exception 'APPLICATION_ALREADY_REVIEWED';end if;
  if length(coalesce(p_note,''))>4000 then raise exception 'REVIEW_NOTE_TOO_LONG';end if;
  select coalesce(array_agg(distinct x order by x),'{}') into docs from unnest(coalesce(p_document_types,'{}')) x;
  if not docs<@required_docs then raise exception 'INVALID_DOCUMENT_TYPES';end if;
  next_version:=a.version+1;
  if p_action='approve' then
    if a.status<>'under_review' then raise exception 'APPLICATION_NOT_READY';end if;
    if docs is distinct from required_docs then raise exception 'ALL_DOCUMENT_CHECKS_REQUIRED';end if;
    wid:=approve_worker_application(p_application_id,p_note);
    update worker_applications set version=next_version where application_id=p_application_id;
    cert:=gen_random_uuid();cert_number:='KC-'||to_char(now(),'YYYY')||'-'||upper(encode(gen_random_bytes(6),'hex'));
    snap:=jsonb_build_object('certificate_number',cert_number,'partner_id',(select partner_id from workers where worker_id=wid),
      'full_name',a.details->>'full_name','profession',a.details->>'profession','district',a.details->>'district',
      'services',(select coalesce(jsonb_agg(jsonb_build_object('service_id',s.service_id,'service_name',s.service_name) order by s.service_name),'[]'::jsonb)
        from worker_services ws join services s using(service_id) where ws.worker_id=wid),
      'approved_at',now(),'checked_document_types',to_jsonb(docs),'review_scope','Application and supplied documents reviewed by Kaylo.');
    insert into partner_certificates(certificate_id,certificate_number,application_id,worker_id,application_version,issued_by,checked_document_types,snapshot)
      values(cert,cert_number,p_application_id,wid,next_version,p_actor_uid,docs,snap);
    perform queue_application_mail(p_application_id,next_version,'approved',a.details->>'email',
      jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',next_version,
        'worker_id',wid,'partner_id',(select partner_id from workers where worker_id=wid),'certificate_id',cert));
  elsif p_action='reject' then
    if length(trim(coalesce(p_note,'')))=0 then raise exception 'REVIEW_REASON_REQUIRED';end if;
    update worker_applications set status='rejected',reviewed_at=now(),review_note=p_note,
      version=next_version,upload_expires_at=now(),correction_expires_at=now() where application_id=p_application_id;
    perform queue_application_mail(p_application_id,next_version,'rejected',a.details->>'email',
      jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',next_version,'note',p_note));
  else
    if a.status not in ('submitted','under_review','changes_requested') then raise exception 'APPLICATION_NOT_READY';end if;
    if length(trim(coalesce(p_note,'')))=0 then raise exception 'REVIEW_REASON_REQUIRED';end if;
    if cardinality(docs)=0 then raise exception 'REQUESTED_DOCUMENTS_REQUIRED';end if;
    -- If reviewing an incomplete application, request every still-missing file.
    foreach doc in array required_docs loop
      if not exists(select 1 from worker_application_documents d join storage.objects o
        on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=p_application_id and d.doc_type=doc)
        and not doc=any(docs) then raise exception 'MISSING_DOCUMENT_MUST_BE_REQUESTED';end if;
    end loop;
    insert into worker_application_corrections(application_id,request_version,doc_type,note,requested_by)
      select p_application_id,next_version,x,p_note,p_actor_uid from unnest(docs) x;
    update worker_applications set status='changes_requested',version=next_version,correction_version=next_version,
      correction_expires_at=now()+interval '7 days',upload_expires_at=now(),review_note=p_note
      where application_id=p_application_id;
    perform queue_application_mail(p_application_id,next_version,'changes_requested',a.details->>'email',
      jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',next_version,
        'correction_version',next_version,'expires_at',now()+interval '7 days','note',p_note,'requested_documents',to_jsonb(docs)));
  end if;
  insert into worker_application_audit(application_id,application_version,action,actor_uid,actor_email,actor_role,data)
    values(p_application_id,next_version,p_action,p_actor_uid,actor.email,actor.role,
      jsonb_build_object('previous_status',a.status,'note',p_note,'document_types',to_jsonb(docs),'certificate_id',cert));
  select * into a from worker_applications where application_id=p_application_id;
  return jsonb_build_object('application_id',a.application_id,'reference',a.reference,'status',a.status,'version',a.version,
    'worker_id',a.worker_id,'certificate_id',cert,'correction_version',a.correction_version);
end $$;
revoke all on function admin_review_application(text,uuid,integer,text,text,text[]) from public,anon,authenticated;
grant execute on function admin_review_application(text,uuid,integer,text,text,text[]) to service_role;

create or replace function application_mail_is_current(p_mail_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from application_mail_outbox m join worker_applications a using(application_id)
    where m.mail_id=p_mail_id and case m.kind
      when 'submitted' then a.status='under_review'
        and (select count(*) from worker_application_documents d join storage.objects o
          on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=a.application_id)=5
        and not exists(select 1 from application_mail_outbox newer
        where newer.application_id=m.application_id and newer.kind='submitted' and newer.application_version>m.application_version)
      when 'changes_requested' then a.status='changes_requested' and a.correction_version=m.application_version
        and a.correction_expires_at>now()
      when 'approved' then a.status='approved' and a.version=m.application_version
      when 'rejected' then a.status='rejected' and a.version=m.application_version
      else false end);
$$;
revoke all on function application_mail_is_current(uuid) from public,anon,authenticated;
grant execute on function application_mail_is_current(uuid) to service_role;

create or replace function claim_application_mail(p_mail_id uuid default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m application_mail_outbox; claim uuid:=gen_random_uuid();
begin
  select * into m from application_mail_outbox x where (p_mail_id is null or x.mail_id=p_mail_id)
    and (x.status in ('pending','failed') or (x.status='sending' and x.lease_until<now()))
    and application_mail_is_current(x.mail_id)
    order by x.created_at,x.mail_id for update skip locked limit 1;
  if not found then return null;end if;
  update application_mail_outbox set status='sending',claim_id=claim,lease_until=now()+interval '5 minutes',
    attempts=attempts+1,last_error=null where mail_id=m.mail_id returning * into m;
  return jsonb_build_object('mail_id',m.mail_id,'claim_id',claim,'application_id',m.application_id,
    'application_version',m.application_version,'kind',m.kind,'recipient_email',m.recipient_email,
    'template_data',m.template_data,'attempts',m.attempts);
end $$;
create or replace function finish_application_mail(p_mail_id uuid,p_claim_id uuid,p_sent boolean,p_error text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare m application_mail_outbox;
begin
  update application_mail_outbox set status=case when p_sent is true then 'sent' else 'failed' end,
    sent_at=case when p_sent is true then now() else null end,claim_id=null,lease_until=null,
    last_error=case when p_sent is true then null else left(coalesce(p_error,'DELIVERY_FAILED'),512) end
    where mail_id=p_mail_id and claim_id=p_claim_id and p_claim_id is not null and status='sending'
    returning * into m;
  if not found then return false;end if;
  if p_sent is true and m.kind='submitted' then
    update worker_applications set admin_notified_at=now() where application_id=m.application_id;
  end if;
  insert into worker_application_audit(application_id,application_version,action,data)
    values(m.application_id,m.application_version,case when p_sent is true then 'email_sent' else 'email_failed' end,
      jsonb_build_object('mail_id',m.mail_id,'kind',m.kind,'attempt',m.attempts,'error',m.last_error));
  return true;
end $$;
revoke all on function claim_application_mail(uuid),finish_application_mail(uuid,uuid,boolean,text) from public,anon,authenticated;
grant execute on function claim_application_mail(uuid),finish_application_mail(uuid,uuid,boolean,text) to service_role;

create or replace function admin_application_list(p_actor_uid text,p_status text default null,p_page integer default 1,
  p_page_size integer default 25,p_search text default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb; count_all integer; page_n integer:=greatest(coalesce(p_page,1),1);
  size_n integer:=greatest(1,least(coalesce(p_page_size,25),100)); search_n text:=nullif(trim(left(coalesce(p_search,''),120)),'');
begin
  perform require_application_admin(p_actor_uid,false);
  if p_status is not null and p_status not in ('submitted','under_review','changes_requested','approved','rejected') then raise exception 'INVALID_APPLICATION_STATUS';end if;
  select count(*) into count_all from worker_applications a where (p_status is null or a.status=p_status)
    and (search_n is null or a.reference ilike '%'||search_n||'%' or a.details->>'full_name' ilike '%'||search_n||'%'
      or a.details->>'email' ilike '%'||search_n||'%');
  select coalesce(jsonb_agg(to_jsonb(x) order by x.submitted_at desc,x.application_id),'[]'::jsonb) into result from (
    select a.application_id,a.reference,a.status,a.version,a.submitted_at,a.reviewed_at,
      a.details->>'full_name' as full_name,a.details->>'profession' as profession,a.details->>'district' as district,
      (select count(*) from worker_application_documents d where d.application_id=a.application_id) as documents_received,
      (select m.status from application_mail_outbox m where m.application_id=a.application_id order by m.application_version desc,m.created_at desc,m.mail_id desc limit 1) as delivery_status
    from worker_applications a where (p_status is null or a.status=p_status)
      and (search_n is null or a.reference ilike '%'||search_n||'%' or a.details->>'full_name' ilike '%'||search_n||'%'
        or a.details->>'email' ilike '%'||search_n||'%')
    order by a.submitted_at desc,a.application_id limit size_n offset ((page_n::bigint-1)*size_n)
  ) x;
  return jsonb_build_object('applications',result,'total',count_all,'page',page_n,'page_size',size_n);
end $$;

create or replace function admin_application_certificate(p_actor_uid text,p_application_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare cert jsonb;
begin
  perform require_application_admin(p_actor_uid,false);
  select to_jsonb(c) into cert from partner_certificates c join worker_applications a using(application_id)
    where c.application_id=p_application_id and a.status='approved';
  return cert;
end $$;

create or replace function admin_application_detail(p_actor_uid text,p_application_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a worker_applications;
begin
  perform require_application_admin(p_actor_uid,false);
  select * into a from worker_applications where application_id=p_application_id;
  if not found then raise exception 'APPLICATION_NOT_FOUND';end if;
  return jsonb_build_object('application',jsonb_build_object('application_id',a.application_id,'reference',a.reference,
    'status',a.status,'version',a.version,'details',a.details,'phone',a.phone,'submitted_at',a.submitted_at,
    'reviewed_at',a.reviewed_at,'review_note',a.review_note,'worker_id',a.worker_id,'correction_version',a.correction_version,
    'correction_expires_at',a.correction_expires_at),
    'documents',coalesce((select jsonb_agg(jsonb_build_object('doc_type',d.doc_type,'storage_path',d.storage_path,
      'content_type',d.content_type,'byte_size',d.byte_size,'submitted_at',d.submitted_at,
      'history',coalesce((select jsonb_agg(to_jsonb(h) order by h.recorded_at,h.history_id)
        from worker_application_document_history h where h.application_id=d.application_id and h.doc_type=d.doc_type),'[]'::jsonb),
      'corrections',coalesce((select jsonb_agg(to_jsonb(c) order by c.request_version)
        from worker_application_corrections c where c.application_id=d.application_id and c.doc_type=d.doc_type),'[]'::jsonb)) order by d.doc_type)
      from worker_application_documents d where d.application_id=p_application_id),'[]'::jsonb),
    'audit',coalesce((select jsonb_agg(to_jsonb(e) order by e.created_at,e.event_id) from worker_application_audit e
      where e.application_id=p_application_id),'[]'::jsonb),
    'deliveries',coalesce((select jsonb_agg(jsonb_build_object('mail_id',m.mail_id,'application_version',m.application_version,
      'kind',m.kind,'recipient_email',m.recipient_email,'status',m.status,'is_current',application_mail_is_current(m.mail_id),'attempts',m.attempts,'last_error',m.last_error,
      'created_at',m.created_at,'sent_at',m.sent_at) order by m.application_version desc,m.created_at desc,m.mail_id desc)
      from application_mail_outbox m where m.application_id=p_application_id),'[]'::jsonb),
    'certificate',admin_application_certificate(p_actor_uid,p_application_id));
end $$;
revoke all on function admin_application_list(text,text,integer,integer,text),admin_application_detail(text,uuid),
  admin_application_certificate(text,uuid) from public,anon,authenticated;
grant execute on function admin_application_list(text,text,integer,integer,text),admin_application_detail(text,uuid),
  admin_application_certificate(text,uuid) to service_role;

insert into application_mail_outbox(application_id,application_version,kind,recipient_email,template_data,status,sent_at)
  select a.application_id,a.version,'submitted','kayloapp@gmail.com',
    jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',a.version),
    case when a.admin_notified_at is null then 'pending' else 'sent' end,a.admin_notified_at
  from worker_applications a where a.status='under_review'
    and (select count(*) from worker_application_documents d where d.application_id=a.application_id)=5
    and not exists(select 1 from application_mail_outbox m where m.application_id=a.application_id and m.kind='submitted')
  on conflict(application_id,application_version,kind) do nothing;

-- Open correction requests also reserve their phone number.
create or replace function submit_worker_application(p_details jsonb)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare
  v_phone text := canonical_partner_phone(p_details->>'phone');
  v_email text := lower(trim(coalesce(p_details->>'email','')));
  v_token text := p_details->>'client_request_token';
  v_app worker_applications;
  svc text;
  v_bank jsonb := p_details->'bank_account';
begin
  if jsonb_typeof(p_details) is distinct from 'object' or octet_length(p_details::text)>16384 then
    raise exception 'INVALID_APPLICATION'; end if;
  if length(trim(coalesce(p_details->>'full_name',''))) not between 2 and 120 then raise exception 'INVALID_NAME'; end if;
  if v_phone !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'INVALID_PHONE'; end if;
  if length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
     or v_email like '%@partners.kaylo.app' then raise exception 'INVALID_EMAIL'; end if;
  if p_details->'consent' is distinct from 'true'::jsonb then raise exception 'CONSENT_REQUIRED'; end if;
  if length(trim(coalesce(p_details->>'profession',''))) not between 2 and 120
     or length(trim(coalesce(p_details->>'district',''))) not between 2 and 100 then raise exception 'INVALID_SERVICE_AREA'; end if;
  if coalesce(p_details->>'experience_years','') !~ '^[0-9]{1,2}$'
     or (p_details->>'experience_years')::int not between 0 and 70 then raise exception 'INVALID_EXPERIENCE'; end if;
  if coalesce(p_details->>'travel_radius_km','') !~ '^[0-9]{1,3}(\.[0-9]{1,2})?$'
     or (p_details->>'travel_radius_km')::numeric not between 1 and 100 then raise exception 'INVALID_RADIUS'; end if;
  if jsonb_typeof(p_details->'services') is distinct from 'array' then raise exception 'INVALID_SERVICES'; end if;
  if jsonb_array_length(p_details->'services') not between 1 and 30 then raise exception 'INVALID_SERVICES'; end if;
  for svc in select jsonb_array_elements_text(p_details->'services') loop
    if not exists(select 1 from services where service_id::text=svc and is_active) then raise exception 'INVALID_SERVICES'; end if;
  end loop;
  if coalesce(p_details->>'upi_id','') !~ '^[A-Za-z0-9._-]{2,255}@[A-Za-z0-9.-]{2,64}$' then
    if jsonb_typeof(v_bank) is distinct from 'object'
      or coalesce(v_bank->>'account_number','') !~ '^[0-9]{6,20}$'
      or coalesce(v_bank->>'ifsc','') !~ '^[A-Z]{4}0[A-Z0-9]{6}$'
      or length(trim(coalesce(v_bank->>'account_holder',''))) not between 2 and 120
      or length(trim(coalesce(v_bank->>'bank_name',''))) not between 2 and 120 then raise exception 'INVALID_PAYOUT'; end if;
  end if;
  if coalesce(v_token,'') !~ '^[0-9a-f]{64}$' then raise exception 'INVALID_REQUEST_TOKEN'; end if;
  -- Serialize phone checks even for repeated concurrent unauthenticated submits.
  perform pg_advisory_xact_lock(hashtextextended(v_phone,2400));
  select * into v_app from worker_applications where phone=v_phone
    and upload_token_hash=encode(digest(v_token,'sha256'),'hex')
    and status in ('submitted','under_review') and upload_expires_at>now();
  if found then return jsonb_build_object('application_id',v_app.application_id,'reference',v_app.reference,
    'upload_token',v_token,'upload_expires_at',v_app.upload_expires_at,'status',v_app.status); end if;
  if exists(select 1 from worker_applications where phone=v_phone and
      (status in ('submitted','under_review','changes_requested','approved') or submitted_at>now()-interval '24 hours')) then
    raise exception 'APPLICATION_ALREADY_EXISTS'; end if;
  if exists(select 1 from persons p where
      canonical_partner_phone(p.phone_number)=v_phone or lower(p.email)=v_email) then
    raise exception 'IDENTITY_ALREADY_IN_USE'; end if;
  insert into worker_applications(phone,details,upload_token_hash)
  values(v_phone,(p_details - 'client_request_token') || jsonb_build_object('phone',v_phone,'email',v_email),encode(digest(v_token,'sha256'),'hex'))
  returning * into v_app;
  return jsonb_build_object('application_id',v_app.application_id,'reference',v_app.reference,
    'upload_token',v_token,'upload_expires_at',v_app.upload_expires_at,'status',v_app.status);
end $$;
revoke all on function submit_worker_application(jsonb) from public;
grant execute on function submit_worker_application(jsonb) to anon,authenticated;


notify pgrst, 'reload schema';
commit;

-- END 0027_partner_admin_review.sql

-- BEGIN 0030_booking_chat_and_partner_activity.sql
-- Booking-scoped communication. Existing rooms/messages and notifications survive.
begin;
alter table public.messages add column if not exists client_message_id uuid;
alter table public.messages add column if not exists read_at timestamptz;
create unique index if not exists messages_client_retry on public.messages(room_id,sender_id,client_message_id) where client_message_id is not null;
create index if not exists messages_room_latest on public.messages(room_id,sent_at desc,message_id desc);
create index if not exists messages_unread_room on public.messages(room_id,sender_id) where read_at is null;
alter table public.notifications add column if not exists booking_id uuid references public.bookings(booking_id) on delete set null;
create table if not exists public.chat_typing (
  room_id uuid not null references public.chat_rooms(room_id) on delete cascade,
  person_id uuid not null references public.persons(person_id) on delete cascade,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key(room_id,person_id)
);
alter table public.chat_typing enable row level security;

create or replace function public.chat_is_member(p_room_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.chat_rooms r join public.bookings b using(booking_id)
    where r.room_id=p_room_id and b.worker_id is not null
      and b.status in ('confirmed','in_progress','completed','cancelled')
      and (b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id()));
$$;
drop policy if exists "participants read rooms" on public.chat_rooms;
drop policy if exists "participants create rooms" on public.chat_rooms;
drop policy if exists "participants read messages" on public.messages;
drop policy if exists "participants send messages" on public.messages;
drop policy if exists "booking members read rooms" on public.chat_rooms;
drop policy if exists "booking members read messages" on public.messages;
drop policy if exists "booking members read typing" on public.chat_typing;
create policy "booking members read rooms" on public.chat_rooms for select to anon,authenticated using(public.chat_is_member(room_id));
create policy "booking members read messages" on public.messages for select to anon,authenticated using(public.chat_is_member(room_id));
create policy "booking members read typing" on public.chat_typing for select to anon,authenticated using(public.chat_is_member(room_id));
revoke insert,update,delete,truncate on public.chat_rooms,public.messages,public.chat_typing from public,anon,authenticated;
grant select on public.chat_rooms,public.messages,public.chat_typing to anon,authenticated;
grant all on public.chat_typing to service_role;

create or replace function public.chat_threads()
returns table(room_id uuid,booking_id uuid,other_person_id uuid,other_name text,worker_id uuid,
  service_name text,booking_status text,last_message text,last_message_at timestamptz,unread_count bigint,can_send boolean)
language sql stable security definer set search_path='' as $$
  with me as (select public.current_customer_id() customer_id,public.current_worker_id() worker_id,public.current_person_id() person_id),
  mine as (
    select r.room_id,b.booking_id,b.worker_id,b.status,b.worker_stage,s.service_name,
      case when b.customer_id=me.customer_id then wp.person_id else cp.person_id end other_person_id,
      case when b.customer_id=me.customer_id then wp.full_name else cp.full_name end other_name,me.person_id
    from public.chat_rooms r join public.bookings b using(booking_id)
    join public.customers c using(customer_id) join public.persons cp on cp.person_id=c.person_id
    join public.workers w on w.worker_id=b.worker_id join public.persons wp on wp.person_id=w.person_id
    join public.services s using(service_id) cross join me
    where me.person_id is not null and (b.customer_id=me.customer_id or b.worker_id=me.worker_id)
      and b.status in ('confirmed','in_progress','completed','cancelled')
  ), unread as (
    select m.room_id,count(*) n from public.messages m join mine on mine.room_id=m.room_id
    where m.sender_id<>mine.person_id and m.read_at is null group by m.room_id
  )
  select mine.room_id,mine.booking_id,mine.other_person_id,mine.other_name,mine.worker_id,
    mine.service_name,mine.status::text,last.message,last.sent_at,coalesce(unread.n,0),
    mine.status in ('confirmed','in_progress') and mine.worker_stage in ('accepted','on_the_way','arrived','in_progress')
  from mine left join unread on unread.room_id=mine.room_id
  left join lateral(select m.message,m.sent_at from public.messages m where m.room_id=mine.room_id order by m.sent_at desc,m.message_id desc limit 1) last on true
  order by last.sent_at desc nulls last,mine.booking_id;
$$;

create or replace function public.chat_open_booking(p_booking_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare b public.bookings; result jsonb;
begin
  select * into b from public.bookings where booking_id=p_booking_id for share;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  insert into public.chat_rooms(booking_id) values(p_booking_id) on conflict(booking_id) do nothing;
  select to_jsonb(t) into result from public.chat_threads() t where t.booking_id=p_booking_id;
  if result is null then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  return result;
end $$;

create or replace function public.chat_send(p_room_id uuid,p_text text,p_client_message_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare me uuid:=public.current_person_id(); b public.bookings; existing public.messages; result uuid;
begin
  if me is null or not public.chat_is_member(p_room_id) then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  if p_client_message_id is null or p_text is null or length(btrim(p_text)) not between 1 and 4000 or octet_length(p_text)>16000 then raise exception 'CHAT_INVALID_MESSAGE' using errcode='22023';end if;
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id) where r.room_id=p_room_id for share of booked;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  select * into existing from public.messages where room_id=p_room_id and sender_id=me and client_message_id=p_client_message_id;
  if found then
    if existing.message<>btrim(p_text) then raise exception 'CHAT_RETRY_MISMATCH' using errcode='22023';end if;
    return existing.message_id;
  end if;
  if b.status not in ('confirmed','in_progress') or b.worker_stage not in ('accepted','on_the_way','arrived','in_progress') then raise exception 'CHAT_READ_ONLY' using errcode='42501';end if;
  insert into public.messages(room_id,sender_id,message,client_message_id)
    values(p_room_id,me,btrim(p_text),p_client_message_id)
    on conflict(room_id,sender_id,client_message_id) where client_message_id is not null do nothing returning message_id into result;
  if result is null then
    select * into existing from public.messages where room_id=p_room_id and sender_id=me and client_message_id=p_client_message_id;
    if existing.message<>btrim(p_text) then raise exception 'CHAT_RETRY_MISMATCH' using errcode='22023';end if;
    result:=existing.message_id;
  end if;
  update public.chat_typing set expires_at=clock_timestamp(),updated_at=clock_timestamp() where room_id=p_room_id and person_id=me;
  return result;
end $$;

create or replace function public.chat_mark_read(p_room_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare b public.bookings;
begin
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id) where r.room_id=p_room_id for share of booked;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  update public.messages set read_at=clock_timestamp()
    where room_id=p_room_id and sender_id<>public.current_person_id() and read_at is null;
end $$;
create or replace function public.chat_set_typing(p_room_id uuid,p_typing boolean)
returns void language plpgsql security definer set search_path='' as $$
declare me uuid:=public.current_person_id(); active boolean; b public.bookings;
begin
  if me is null or not public.chat_is_member(p_room_id) then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id) where r.room_id=p_room_id for share of booked;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  active:=b.status in ('confirmed','in_progress') and b.worker_stage in ('accepted','on_the_way','arrived','in_progress');
  if p_typing is true and not active then raise exception 'CHAT_READ_ONLY' using errcode='42501';end if;
  insert into public.chat_typing(room_id,person_id,expires_at,updated_at)
    values(p_room_id,me,clock_timestamp()+case when p_typing is true then interval '8 seconds' else interval '0 seconds' end,clock_timestamp())
  on conflict(room_id,person_id) do update set expires_at=excluded.expires_at,updated_at=excluded.updated_at
    where p_typing is not true or public.chat_typing.updated_at<clock_timestamp()-interval '2 seconds';
end $$;
create or replace function public.clear_finished_booking_typing()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.status in ('completed','cancelled') and new.status is distinct from old.status then
    update public.chat_typing set expires_at=clock_timestamp(),updated_at=clock_timestamp()
      where room_id in(select room_id from public.chat_rooms where booking_id=new.booking_id);
  end if;return new;
end $$;
drop trigger if exists bookings_clear_typing on public.bookings;
create trigger bookings_clear_typing after update of status on public.bookings for each row execute function public.clear_finished_booking_typing();

create or replace function public.my_worker_reviews()
returns table(review_id uuid,booking_id uuid,customer_name text,service_name text,rating integer,review text,created_at timestamptz)
language sql stable security definer set search_path='' as $$
  select r.review_id,r.booking_id,p.full_name,s.service_name,r.rating,r.review,r.created_at
    from public.reviews r join public.bookings b using(booking_id) join public.customers c on c.customer_id=r.customer_id
    join public.persons p on p.person_id=c.person_id join public.services s using(service_id)
    where r.worker_id=public.current_worker_id() order by r.created_at desc,r.review_id;
$$;
create or replace function public.mark_my_notifications_read(p_notification_id uuid default null)
returns void language plpgsql security definer set search_path='' as $$
begin
  if public.current_person_id() is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
  update public.notifications set is_read=true where person_id=public.current_person_id()
    and (p_notification_id is null or notification_id=p_notification_id) and not is_read;
end $$;
-- Marking an alert read never permits rewriting its owner or contents.
revoke update on public.notifications from public,anon,authenticated;
grant update(is_read) on public.notifications to anon,authenticated;

-- Preserve existing booking notification semantics, now with an explicit route.
create or replace function public.notify_worker_about_booking()
returns trigger language plpgsql security definer set search_path='' as $$
declare who uuid; service text; heading text;
begin
  if new.worker_id is null then return new;end if;
  if tg_op='UPDATE' and new.status is not distinct from old.status and new.worker_id is not distinct from old.worker_id and new.worker_stage is not distinct from old.worker_stage then return new;end if;
  heading:=case when tg_op='INSERT' or new.worker_id is distinct from old.worker_id then 'New job request'
    when new.status='cancelled' then 'Booking cancelled' when new.status='completed' then 'Job completed'
    when new.worker_stage='accepted' then 'Job accepted' when new.worker_stage='on_the_way' then 'On the way'
    when new.worker_stage='arrived' then 'Arrival confirmed' when new.worker_stage='in_progress' then 'Job started' else null end;
  if heading is null then return new;end if;
  select person_id into who from public.workers where worker_id=new.worker_id;
  select service_name into service from public.services where service_id=new.service_id;
  insert into public.notifications(person_id,title,message,type,booking_id)
    values(who,heading,coalesce(service,'A service')||' on '||to_char(new.booking_date,'DD Mon')||', '||to_char(new.booking_time,'HH12:MI AM')||case when new.payment_mode='cash' then ' · cash' else '' end,
      case when heading='New job request' then 'request' else 'job' end,new.booking_id);
  return new;
end $$;

revoke all on function public.chat_is_member(uuid),public.chat_threads(),public.chat_open_booking(uuid),public.chat_send(uuid,text,uuid),public.chat_mark_read(uuid),public.chat_set_typing(uuid,boolean),public.my_worker_reviews(),public.mark_my_notifications_read(uuid) from public;
grant execute on function public.chat_is_member(uuid),public.chat_threads(),public.chat_open_booking(uuid),public.chat_send(uuid,text,uuid),public.chat_mark_read(uuid),public.chat_set_typing(uuid,boolean),public.my_worker_reviews(),public.mark_my_notifications_read(uuid) to anon,authenticated;
-- Realtime postgres_changes sends rows only after evaluating table SELECT RLS.
do $$ declare t text;begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach t in array array['chat_rooms','messages','chat_typing','bookings','notifications','reviews'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
        execute format('alter publication supabase_realtime add table public.%I',t);
      end if;
    end loop;
  end if;
end $$;

-- Preferences are enforced at creation for live alerts as well as in each UI.
create table if not exists public.partner_notification_preferences (
  person_id uuid primary key references public.persons(person_id) on delete cascade,
  requests boolean not null default true, jobs boolean not null default true,
  payouts boolean not null default true, updated_at timestamptz not null default now()
);
alter table public.partner_notification_preferences enable row level security;
revoke all on public.partner_notification_preferences from public,anon,authenticated;
grant all on public.partner_notification_preferences to service_role;
create or replace function public.set_partner_notification_preferences(p_requests boolean,p_jobs boolean,p_payouts boolean)
returns void language plpgsql security definer set search_path='' as $$
begin
  if public.current_worker_id() is null or public.current_person_id() is null then raise exception 'WORKER_ACCESS_REQUIRED' using errcode='42501';end if;
  if p_requests is null or p_jobs is null or p_payouts is null then raise exception 'INVALID_PREFERENCES' using errcode='22023';end if;
  insert into public.partner_notification_preferences(person_id,requests,jobs,payouts)
    values(public.current_person_id(),p_requests,p_jobs,p_payouts)
    on conflict(person_id) do update set requests=excluded.requests,jobs=excluded.jobs,payouts=excluded.payouts,updated_at=now();
end $$;
revoke all on function public.set_partner_notification_preferences(boolean,boolean,boolean) from public;
grant execute on function public.set_partner_notification_preferences(boolean,boolean,boolean) to anon,authenticated;
create or replace function public.filter_partner_notification_preferences()
returns trigger language plpgsql security definer set search_path='' as $$
declare pref public.partner_notification_preferences;
begin
  select * into pref from public.partner_notification_preferences where person_id=new.person_id;
  if found and ((new.type='request' and not pref.requests) or (new.type in ('job','booking') and not pref.jobs) or (new.type='payout' and not pref.payouts)) then return null;end if;
  return new;
end $$;
drop trigger if exists notifications_partner_preferences on public.notifications;
create trigger notifications_partner_preferences before insert on public.notifications for each row execute function public.filter_partner_notification_preferences();
drop trigger if exists bookings_notify_worker on public.bookings;
create trigger bookings_notify_worker after insert or update of status,worker_id,worker_stage on public.bookings for each row execute function public.notify_worker_about_booking();

create or replace function public.notify_partner_payment()
returns trigger language plpgsql security definer set search_path='' as $$
declare who uuid;
begin
  if new.payment_status<>'success' or (tg_op='UPDATE' and old.payment_status='success') then return new;end if;
  select w.person_id into who from public.bookings b join public.workers w using(worker_id) where b.booking_id=new.booking_id;
  if who is not null then
    insert into public.notifications(person_id,title,message,type,booking_id) values(who,
      case when new.payment_method='cash' then 'Cash collected' else 'Payment received' end,
      'Payment recorded for your booking.','payout',new.booking_id);
  end if;return new;
end $$;
drop trigger if exists payments_notify_partner on public.payments;
create trigger payments_notify_partner after insert or update of payment_status on public.payments for each row execute function public.notify_partner_payment();
create or replace function public.notify_partner_settlement()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  insert into public.notifications(person_id,title,message,type)
    select person_id,'Settlement recorded','Your cash settlement has been recorded.','payout' from public.workers where worker_id=new.worker_id;
  return new;
end $$;
drop trigger if exists settlements_notify_partner on public.settlements;
create trigger settlements_notify_partner after insert on public.settlements for each row execute function public.notify_partner_settlement();

-- Private channel authorization only permits the caller's own channel topics.
-- Actual postgres_changes row delivery is independently checked by table RLS.
do $$ begin
  if to_regclass('realtime.messages') is not null then
    execute 'drop policy if exists "kaylo private chat channel" on realtime.messages';
    execute $policy$create policy "kaylo private chat channel" on realtime.messages for select to anon,authenticated
      using (realtime.topic() like 'kaylo-chat:%' and split_part(realtime.topic(),':',2)=public.current_person_id()::text)$policy$;
  end if;
end $$;


-- A worker can navigate an alert/chat back to the real assigned booking.
create or replace function public.my_partner_jobs()
returns table(booking_id uuid,service_name text,service_icon text,customer_name text,customer_phone text,
  address text,latitude double precision,longitude double precision,scheduled_at timestamptz,
  payout numeric,customer_price numeric,payment_mode text,notes text,status text,booking_status text)
language sql stable security definer set search_path='' as $$
  select b.booking_id,s.service_name,s.icon_path,p.full_name,p.phone_number,
    concat_ws(', ',nullif(l.house_name,''),nullif(l.street,''),nullif(l.district,''),nullif(l.pincode,'')),
    l.latitude,l.longitude,(b.booking_date+b.booking_time) at time zone 'Asia/Kolkata',
    round(coalesce(b.final_cost,b.estimated_cost,0)*(1-public.kaylo_commission_rate()),2),
    coalesce(b.final_cost,b.estimated_cost,0),b.payment_mode,b.notes,b.worker_stage,b.status::text
  from public.bookings b join public.services s using(service_id) join public.customers c using(customer_id)
    join public.persons p on p.person_id=c.person_id left join public.locations l using(location_id)
  where b.worker_id=public.current_worker_id() order by b.booking_date desc,b.booking_time desc,b.booking_id;
$$;
revoke all on function public.my_partner_jobs() from public;
grant execute on function public.my_partner_jobs() to anon,authenticated;

notify pgrst,'reload schema';
commit;

-- END 0030_booking_chat_and_partner_activity.sql

-- BEGIN 0031_chat_read_boundaries.sql
-- A receipt acknowledges a rendered snapshot, never messages arriving afterwards.
begin;
create or replace function public.chat_mark_read_through(p_room_id uuid,p_message_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare b public.bookings; boundary public.messages; me uuid:=public.current_person_id();
begin
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id)
    where r.room_id=p_room_id for share of booked;
  if me is null or not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  select * into boundary from public.messages where message_id=p_message_id and room_id=p_room_id;
  if not found then raise exception 'CHAT_INVALID_MESSAGE' using errcode='22023';end if;
  update public.messages set read_at=clock_timestamp()
    where room_id=p_room_id and sender_id<>me and read_at is null
      and (sent_at,message_id)<=(boundary.sent_at,boundary.message_id);
end $$;
revoke all on function public.chat_mark_read_through(uuid,uuid) from public;
grant execute on function public.chat_mark_read_through(uuid,uuid) to anon,authenticated;
commit;

-- END 0031_chat_read_boundaries.sql
