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
