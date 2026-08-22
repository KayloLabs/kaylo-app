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
