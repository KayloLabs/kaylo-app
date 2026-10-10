-- Run after migration 0023 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic accounts, a service and bookings are created.
begin;

-- Test-only fixture: emulate an admin-issued password session for a synthetic
-- worker. Temporary function and rows disappear at ROLLBACK; never deployed.
create function pg_temp.use_issued_worker_fixture()
returns void language plpgsql security definer set search_path=public as $$
declare w workers; uid text:=current_auth_subject(); claims jsonb:=auth.jwt();
begin
  select wk.* into w from workers wk join persons p using(person_id) where p.auth_user_id=uid;
  if not found then return;end if;
  if w.partner_id is null then
    update workers set partner_id='KP-'||lpad(nextval('kaylo_partner_id_seq')::text,6,'0')
      where worker_id=w.worker_id returning * into w;
  end if;
  update workers set must_change_password=false,verification_status='verified' where worker_id=w.worker_id;
  insert into partner_credentials(worker_id,issuance_id,firebase_uid,state,password_updated_at_ms,issued_at)
    values(w.worker_id,gen_random_uuid(),uid,'delivered',1,now()) on conflict(worker_id) do nothing;
  perform set_config('request.jwt.claims',(claims||jsonb_build_object('auth_time',extract(epoch from now())::bigint,
    'kaylo_role','worker','kaylo_partner_id',w.partner_id,
    'kaylo_issuance_id',(select issuance_id from partner_credentials where worker_id=w.worker_id),'firebase',jsonb_build_object('sign_in_provider','password')))::text,true);
end $$;


do $$
declare
  person_w uuid := gen_random_uuid();
  worker_w uuid := gen_random_uuid();
  uid_w text := 'avail_w_' || gen_random_uuid();
  person_o uuid := gen_random_uuid();
  worker_o uuid := gen_random_uuid();
  uid_o text := 'avail_o_' || gen_random_uuid();
  person_c uuid := gen_random_uuid();
  cust_c uuid := gen_random_uuid();
  uid_c text := 'avail_c_' || gen_random_uuid();
  svc uuid := gen_random_uuid();
  -- A Monday at least a week ahead, and the Sunday after it.
  monday date := current_date + 7 + ((8 - extract(isodow from current_date)::int) % 7);
  sunday date;
  early_booking uuid := gen_random_uuid();
  ok_booking uuid := gen_random_uuid();
  n int;
  denied boolean;
begin
  sunday := monday + 6;
  insert into persons (person_id, auth_user_id, full_name) values
    (person_w, uid_w, 'Hours worker'), (person_o, uid_o, 'Other worker'), (person_c, uid_c, 'Hours customer');
  insert into workers (worker_id, person_id) values (worker_w, person_w), (worker_o, person_o);
  insert into customers (customer_id, person_id) values (cust_c, person_c);
  insert into services (service_id, category_id, service_name, base_price)
    select svc, category_id, 'Hours test ' || svc, 300 from service_categories where slug = 'home';

  -- 1. No hours set: nothing is blocked and any time can be booked.
  select count(*) into n from worker_blocked_times(worker_w, monday);
  if n <> 0 then raise exception 'a worker without hours has blocked times'; end if;

  -- 2. The worker sets Monday 09:00-17:00, Sunday off; the id fills in.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_w)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  insert into worker_weekly_hours (weekday, works, start_time, end_time) values (1, true, '09:00', '17:00');
  insert into worker_weekly_hours (weekday, works) values (7, false);
  execute 'reset role';
  select count(*) into n from worker_weekly_hours where worker_id = worker_w;
  if n <> 2 then raise exception 'weekly hours did not land on the worker'; end if;

  -- 3. Outside the window is blocked, inside is free, the whole Sunday is blocked.
  select count(*) into n from worker_blocked_times(worker_w, monday) t where t = '07:00';
  if n <> 1 then raise exception '07:00 should be blocked before a 09:00 start'; end if;
  select count(*) into n from worker_blocked_times(worker_w, monday) t where t = '10:30';
  if n <> 0 then raise exception '10:30 should be free inside the window'; end if;
  select count(*) into n from worker_blocked_times(worker_w, monday) t where t = '17:00';
  if n <> 1 then raise exception '17:00 should be blocked at the end of the window'; end if;
  select count(*) into n from worker_blocked_times(worker_w, sunday);
  if n <> 48 then raise exception 'a day off should block all 48 half hours, got %', n; end if;
  -- Tuesday has no row, so it stays open.
  select count(*) into n from worker_blocked_times(worker_w, monday + 1);
  if n <> 0 then raise exception 'a weekday without a row should be open'; end if;
  -- The customer app's call includes the blocked times.
  select count(*) into n from worker_taken_slots(worker_w, monday) t where t = '07:00';
  if n <> 1 then raise exception 'taken slots should include blocked times'; end if;

  -- 4. A customer cannot book outside the hours, but can inside.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_c)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  denied := false;
  begin
    insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
      values (early_booking, cust_c, worker_w, svc, monday, '07:00', 300);
  exception when others then denied := true; end;
  if not denied then raise exception 'a booking before the start of the day was accepted'; end if;
  denied := false;
  begin
    insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
      values (early_booking, cust_c, worker_w, svc, sunday, '10:30', 300);
  exception when others then denied := true; end;
  if not denied then raise exception 'a booking on a day off was accepted'; end if;
  insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
    values (ok_booking, cust_c, worker_w, svc, monday, '10:30', 300);
  execute 'reset role';

  -- 5. Time off added afterwards blocks the day, but the existing job can still finish.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_w)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  insert into worker_time_off (starts_on, ends_on, reason) values (monday, monday + 2, 'Family function');
  select count(*) into n from worker_time_off;
  if n <> 1 then raise exception 'the worker should see exactly their own time off'; end if;
  execute 'reset role';
  select count(*) into n from worker_blocked_times(worker_w, monday + 1);
  if n <> 48 then raise exception 'time off should block the whole day'; end if;
  update bookings set status = 'confirmed' where booking_id = ok_booking;
  -- Moving the open booking into the time off is refused.
  denied := false;
  begin
    update bookings set booking_date = monday + 1 where booking_id = ok_booking;
  exception when others then denied := true; end;
  if not denied then raise exception 'a reschedule into time off was accepted'; end if;
  -- Finishing it is not: a status change is never re-checked against hours.
  update bookings set status = 'in_progress' where booking_id = ok_booking;
  update bookings set status = 'completed' where booking_id = ok_booking;
  if (select status from bookings where booking_id = ok_booking) <> 'completed' then
    raise exception 'a status change was blocked by later time off';
  end if;

  -- 6. Another worker cannot see or touch these rows.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_o)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  select count(*) into n from worker_weekly_hours;
  if n <> 0 then raise exception 'another worker can read these hours'; end if;
  delete from worker_time_off where worker_id = worker_w;
  execute 'reset role';
  select count(*) into n from worker_time_off where worker_id = worker_w;
  if n <> 1 then raise exception 'another worker deleted this time off'; end if;

  raise notice 'worker availability: ok';
end $$;

rollback;
