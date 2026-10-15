-- Run after migration 0019 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic accounts, a service, bookings and payments are created.
-- No payment gateway or external service is called.
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
  pc uuid:=gen_random_uuid(); pw uuid:=gen_random_uuid(); pl uuid:=gen_random_uuid();
  c uuid:=gen_random_uuid(); w uuid:=gen_random_uuid(); legacy uuid:=gen_random_uuid();
  uc text:='sync_c_'||gen_random_uuid(); uw text:='sync_w_'||gen_random_uuid();
  svc uuid:=gen_random_uuid(); b uuid:=gen_random_uuid();
  stage text; expected text; actual text; result jsonb; worker_claims text;
begin
  insert into persons(person_id,auth_user_id,full_name) values(pc,uc,'Sync customer'),(pw,uw,'Sync partner'),(pl,'sync_legacy_'||pl,'Legacy sample');
  insert into customers(customer_id,person_id) values(c,pc);
  insert into workers(worker_id,person_id,is_available,is_verified,verification_status) values(w,pw,false,true,'verified'),(legacy,pl,true,true,'verified');
  insert into services(service_id,category_id,service_name,base_price)
    select svc,category_id,'Sync test '||svc,100 from service_categories where slug='home';
  insert into worker_services(worker_id,service_id) values(w,svc);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uw)::text,true);
  perform pg_temp.use_issued_worker_fixture();
  worker_claims:=current_setting('request.jwt.claims');
  -- Availability is independent of approval: an offline issued partner is listed.
  if not exists(select 1 from worker_profiles where worker_id=w and is_bookable and not is_available) then raise exception 'Offline approved partner missing';end if;
  if exists(select 1 from worker_profiles where worker_id=legacy and is_bookable) then raise exception 'Sample worker included in booking discovery';end if;
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uc)::text,true);
  execute 'set local role anon';
  insert into bookings(booking_id,customer_id,worker_id,service_id,booking_date,booking_time,estimated_cost,payment_mode)
    values(b,c,w,svc,current_date+2,'12:00',100,'online');
  execute 'reset role';
  -- This is the status write made by verify-payment after a captured payment.
  update bookings set status='confirmed' where booking_id=b;
  if not exists(select 1 from bookings where booking_id=b and worker_stage='requested' and status='pending') then
    raise exception 'Payment accepted the job without the partner';
  end if;
  execute 'set local role anon';
  foreach stage in array array['accepted','on_the_way','arrived','in_progress','completed'] loop
    perform set_config('request.jwt.claims',worker_claims,true);
    result:=worker_advance_booking(b,stage);
    expected:=case when stage in ('accepted','on_the_way','arrived') then 'confirmed' else stage end;
    if result->>'worker_stage' <> stage or result->>'status' <> expected then raise exception 'Wrong stage RPC result: %',result;end if;
    select status into actual from my_partner_jobs() where booking_id=b;
    if actual is distinct from stage then raise exception 'Partner projection stale for %: %',stage,actual;end if;
    -- A late payment write cannot regress an already advanced job either.
    execute 'reset role';
    update bookings set status='confirmed' where booking_id=b;
    execute 'set local role anon';
    perform set_config('request.jwt.claims',jsonb_build_object('sub',uc)::text,true);
    select worker_stage into actual from bookings where booking_id=b and status::text=expected;
    if actual is distinct from stage then raise exception 'Customer projection stale for %: %',stage,actual;end if;
  end loop;
  execute 'reset role';
end $$;
rollback;
select 'PASS: all five stages agree for partner and customer; offline issued partner discoverable; sample excluded' as result;
