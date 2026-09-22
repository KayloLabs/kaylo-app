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
