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
