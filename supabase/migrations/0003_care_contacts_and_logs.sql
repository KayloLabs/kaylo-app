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
