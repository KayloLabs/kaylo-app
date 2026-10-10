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
