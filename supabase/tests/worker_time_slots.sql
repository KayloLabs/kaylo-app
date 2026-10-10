-- Run after migration 0021 as the migration/database owner.
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
  person_a uuid := gen_random_uuid();
  person_b uuid := gen_random_uuid();
  person_w uuid := gen_random_uuid();
  cust_a uuid := gen_random_uuid();
  cust_b uuid := gen_random_uuid();
  worker uuid := gen_random_uuid();
  uid_a text := 'slots_a_' || gen_random_uuid();
  uid_b text := 'slots_b_' || gen_random_uuid();
  svc uuid := gen_random_uuid();
  first_booking uuid := gen_random_uuid();
  second_booking uuid := gen_random_uuid();
  other_time uuid := gen_random_uuid();
  day date := current_date + 2;
  n int;
  denied boolean;
begin
  insert into persons (person_id, auth_user_id, full_name) values
    (person_a, uid_a, 'Slots customer A'), (person_b, uid_b, 'Slots customer B'), (person_w, null, 'Slots worker');
  insert into customers (customer_id, person_id) values (cust_a, person_a), (cust_b, person_b);
  insert into workers (worker_id, person_id) values (worker, person_w);
  insert into services (service_id, category_id, service_name, base_price)
    select svc, category_id, 'Slots test ' || svc, 300 from service_categories where slug = 'home';

  -- 1. Customer A holds 08:00; the function lists it for anyone.
  insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
    values (first_booking, cust_a, worker, svc, day, '08:00', 300);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_b)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  select count(*) into n from worker_taken_slots(worker, day) t where t = '08:00';
  if n <> 1 then raise exception 'customer B cannot see that 08:00 is taken'; end if;
  select count(*) into n from bookings where booking_id = first_booking;
  if n <> 0 then raise exception 'customer B can read customer A''s booking row'; end if;

  -- 2. Customer B cannot take the same slot, but another time is fine.
  denied := false;
  begin
    insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
      values (second_booking, cust_b, worker, svc, day, '08:00', 300);
  exception when others then denied := true; end;
  if not denied then raise exception 'two customers got the same worker at the same time'; end if;
  insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
    values (other_time, cust_b, worker, svc, day, '10:30', 300);

  -- 3. Rescheduling into a held slot is refused too.
  denied := false;
  begin
    update bookings set booking_time = '08:00' where booking_id = other_time;
  exception when others then denied := true; end;
  if not denied then raise exception 'a reschedule landed on a held slot'; end if;
  execute 'reset role';

  -- 4. Cancelling frees the slot.
  update bookings set status = 'cancelled' where booking_id = first_booking;
  select count(*) into n from worker_taken_slots(worker, day) t where t = '08:00';
  if n <> 0 then raise exception 'a cancelled booking still holds its slot'; end if;
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_b)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  update bookings set booking_time = '08:00' where booking_id = other_time;
  execute 'reset role';
  if (select booking_time from bookings where booking_id = other_time) <> '08:00' then
    raise exception 'the freed slot could not be taken';
  end if;

  raise notice 'worker time slots: ok';
end $$;

rollback;
