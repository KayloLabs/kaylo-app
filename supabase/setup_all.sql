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
