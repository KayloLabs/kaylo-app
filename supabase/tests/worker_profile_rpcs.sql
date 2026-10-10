-- Run after migration 0022 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic persons, workers and services are created.
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
  uid_w text := 'prof_' || gen_random_uuid();
  person_o uuid := gen_random_uuid();
  worker_o uuid := gen_random_uuid();
  uid_o text := 'prof_other_' || gen_random_uuid();
  person_c uuid := gen_random_uuid();
  uid_c text := 'prof_cust_' || gen_random_uuid();
  svc1 uuid := gen_random_uuid();
  svc2 uuid := gen_random_uuid();
  prof jsonb;
  denied boolean;
begin
  insert into persons (person_id, auth_user_id, full_name, phone_number) values
    (person_w, uid_w, 'Profile worker', '+91 90000 11111'),
    (person_o, uid_o, 'Other worker', null),
    (person_c, uid_c, 'Just a customer', null);
  insert into workers (worker_id, person_id, travel_radius_km) values (worker_w, person_w, 10), (worker_o, person_o, 5);
  insert into worker_payout_accounts (worker_id, upi_id) values (worker_o, 'other@okaxis');
  insert into services (service_id, category_id, service_name, base_price)
    select svc1, category_id, 'Profile test A ' || svc1, 300 from service_categories where slug = 'home';
  insert into services (service_id, category_id, service_name, base_price)
    select svc2, category_id, 'Profile test B ' || svc2, 300 from service_categories where slug = 'home';
  insert into worker_services (worker_id, service_id) values (worker_w, svc1);

  -- 1. The worker reads their own profile, and only their own.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_w)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  prof := my_worker_profile();
  if prof->>'worker_id' <> worker_w::text then raise exception 'profile is not mine'; end if;
  if prof->>'full_name' <> 'Profile worker' then raise exception 'name missing from profile'; end if;
  if jsonb_array_length(prof->'services') <> 1 then raise exception 'services missing from profile'; end if;
  if prof->>'upi_id' is not null then raise exception 'a payout account appeared from nowhere'; end if;
  if (prof->>'is_available')::boolean is not true then raise exception 'new worker should be available'; end if;

  -- 2. A partial edit changes only the keys given.
  prof := update_worker_profile(jsonb_build_object(
    'full_name', 'Profile worker edited', 'district', 'Kannur', 'travel_radius_km', 25,
    'services', jsonb_build_array(svc2::text), 'upi_id', 'edited@oksbi'));
  if prof->>'full_name' <> 'Profile worker edited' then raise exception 'name edit lost'; end if;
  if prof->>'district' <> 'Kannur' then raise exception 'district edit lost'; end if;
  if (prof->>'travel_radius_km')::numeric <> 25 then raise exception 'radius edit lost'; end if;
  if prof->>'upi_id' <> 'edited@oksbi' then raise exception 'UPI edit lost'; end if;
  if jsonb_array_length(prof->'services') <> 1 or prof->'services'->0->>'service_id' <> svc2::text then
    raise exception 'services were not replaced';
  end if;
  prof := update_worker_profile(jsonb_build_object('bio', 'Ten years of plumbing'));
  if prof->>'bio' <> 'Ten years of plumbing' then raise exception 'bio edit lost'; end if;
  if prof->>'upi_id' <> 'edited@oksbi' then raise exception 'an unrelated edit blanked the UPI id'; end if;
  if prof->>'full_name' <> 'Profile worker edited' then raise exception 'an unrelated edit blanked the name'; end if;

  -- 3. Bad edits are refused.
  denied := false;
  begin perform update_worker_profile(jsonb_build_object('full_name', '  ')); exception when others then denied := true; end;
  if not denied then raise exception 'an empty name was accepted'; end if;
  denied := false;
  begin perform update_worker_profile(jsonb_build_object('services', jsonb_build_array())); exception when others then denied := true; end;
  if not denied then raise exception 'an empty service list was accepted'; end if;
  denied := false;
  begin perform update_worker_profile(jsonb_build_object('travel_radius_km', 500)); exception when others then denied := true; end;
  if not denied then raise exception 'a 500 km radius was accepted'; end if;

  -- 4. The duty switch writes is_available for this worker only.
  if set_worker_available(false) then raise exception 'switch returned the wrong value'; end if;
  execute 'reset role';
  if (select is_available from workers where worker_id = worker_w) then raise exception 'is_available not written'; end if;
  if not (select is_available from workers where worker_id = worker_o) then raise exception 'the other worker was switched off'; end if;
  if (select upi_id from worker_payout_accounts where worker_id = worker_o) <> 'other@okaxis' then
    raise exception 'the other worker''s payout account changed';
  end if;

  -- 5. Someone who is not a worker gets nothing and cannot edit.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_c)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  if my_worker_profile() is not null then raise exception 'a customer got a worker profile'; end if;
  denied := false;
  begin perform update_worker_profile(jsonb_build_object('full_name', 'Hacker')); exception when others then denied := true; end;
  if not denied then raise exception 'a customer could edit a worker profile'; end if;
  denied := false;
  begin perform set_worker_available(false); exception when others then denied := true; end;
  if not denied then raise exception 'a customer could flip availability'; end if;
  execute 'reset role';

  raise notice 'worker profile rpcs: ok';
end $$;

rollback;
