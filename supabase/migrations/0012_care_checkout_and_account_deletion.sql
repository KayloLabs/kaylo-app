-- Care checkout through verified payment, and account deletion.
-- Safe to run more than once.
begin;
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
commit;
