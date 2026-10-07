-- Run after migration 0020 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic persons, workers, services and documents are created.
-- No storage upload or external service is called.
begin;

do $$
declare
  person_n uuid := gen_random_uuid();
  uid_n text := 'reg_' || gen_random_uuid();
  person_o uuid := gen_random_uuid();
  worker_o uuid := gen_random_uuid();
  uid_o text := 'reg_other_' || gen_random_uuid();
  person_s uuid := gen_random_uuid();
  worker_s uuid := gen_random_uuid();
  svc1 uuid := gen_random_uuid();
  svc2 uuid := gen_random_uuid();
  wid uuid;
  n int;
  denied boolean;
  details jsonb;
begin
  insert into persons (person_id, auth_user_id, full_name) values
    (person_n, uid_n, 'Placeholder'), (person_o, uid_o, 'Other worker'), (person_s, null, 'Seeded worker');
  insert into workers (worker_id, person_id) values (worker_o, person_o);
  insert into services (service_id, category_id, service_name, base_price)
    select svc1, category_id, 'Reg test home ' || svc1, 300 from service_categories where slug = 'home';
  insert into services (service_id, category_id, service_name, base_price)
    select svc2, category_id, 'Reg test farm ' || svc2, 50 from service_categories where slug = 'farm';
  details := jsonb_build_object(
    'full_name', 'Sunil Kumar', 'services', jsonb_build_array(svc1::text, svc2::text),
    'experience_years', 7, 'hourly_rate', 250, 'district', 'Kannur', 'travel_radius_km', 12,
    'working_hours', '08:00-18:00', 'upi_id', 'sunil@okaxis');

  -- 1. Registration needs a payout account, then writes everything at once.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_n)::text, true);
  execute 'set local role anon';
  denied := false;
  begin perform register_worker(details - 'upi_id'); exception when others then denied := true; end;
  if not denied then raise exception 'registered without a payout account'; end if;
  denied := false;
  begin perform register_worker(details || '{"services": []}'); exception when others then denied := true; end;
  if not denied then raise exception 'registered without a service'; end if;
  wid := register_worker(details);

  -- 2. Own documents only.
  insert into worker_documents (worker_id, doc_type, storage_path) values
    (wid, 'aadhaar_front', wid::text || '/aadhaar_front.jpg'), (wid, 'photo', wid::text || '/photo.jpg');
  select count(*) into n from worker_documents;
  if n <> 2 then raise exception 'the worker sees % of their own documents', n; end if;
  denied := false;
  begin
    insert into worker_documents (worker_id, doc_type, storage_path) values (worker_o, 'selfie', worker_o::text || '/selfie.jpg');
    denied := false;
  exception when others then denied := true; end;
  if not denied then raise exception 'a document was filed for another worker'; end if;
  if has_function_privilege('anon', 'review_worker(uuid,text,text)', 'EXECUTE')
     or has_function_privilege('authenticated', 'review_worker(uuid,text,text)', 'EXECUTE')
     or has_function_privilege('anon', 'review_worker_document(uuid,text,text)', 'EXECUTE') then
    raise exception 'the Trust Team functions are callable from the app';
  end if;
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    execute format('insert into storage.objects (bucket_id, name) values (%L, %L)', 'worker-documents', wid::text || '/aadhaar_front.jpg');
    denied := false;
    begin
      execute format('insert into storage.objects (bucket_id, name) values (%L, %L)', 'worker-documents', worker_o::text || '/selfie.jpg');
    exception when others then denied := true; end;
    if not denied then raise exception 'uploaded into another worker''s folder'; end if;
  end if;
  execute 'reset role';

  if (select verification_status from workers where worker_id = wid) <> 'under_review' then
    raise exception 'a new registration is not under review';
  end if;
  if (select is_verified from workers where worker_id = wid) then raise exception 'a new worker is already verified'; end if;
  if (select full_name from persons where person_id = person_n) <> 'Sunil Kumar' then raise exception 'the name was not saved'; end if;
  select count(*) into n from worker_services where worker_id = wid;
  if n <> 2 then raise exception 'expected 2 services, found %', n; end if;
  if not exists (select 1 from locations where person_id = person_n and district = 'Kannur') then raise exception 'the service area was not saved'; end if;
  if (select upi_id from worker_payout_accounts where worker_id = wid) <> 'sunil@okaxis' then raise exception 'the payout account was not saved'; end if;
  if (select working_hours from workers where worker_id = wid) <> '08:00-18:00' then raise exception 'working hours not saved'; end if;

  -- 3. Another worker sees none of it.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_o)::text, true);
  execute 'set local role anon';
  select count(*) into n from worker_documents;
  if n <> 0 then raise exception 'another worker can read these documents'; end if;
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    execute 'select count(*) from storage.objects' into n;
    if n <> 0 then raise exception 'another worker can list these files'; end if;
  end if;
  execute 'reset role';

  -- 4. The Trust Team verifies: the flag follows, documents flip, the worker is told.
  perform review_worker(wid, 'verified', 'All good');
  if not (select is_verified from workers where worker_id = wid) then raise exception 'is_verified did not follow verification_status'; end if;
  select count(*) into n from worker_documents where worker_id = wid and status = 'verified';
  if n <> 2 then raise exception 'documents were not marked verified'; end if;
  if not exists (select 1 from notifications where person_id = person_n and title = 'You are verified') then
    raise exception 'the worker was not told';
  end if;

  -- 5. Updating the registration keeps a verified worker verified, and the
  --    old flag on a seed-style insert still means verified.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_n)::text, true);
  execute 'set local role anon';
  perform register_worker(details || '{"hourly_rate": 300}');
  execute 'reset role';
  if (select verification_status from workers where worker_id = wid) <> 'verified' then raise exception 'an update dropped the verification'; end if;
  if (select hourly_rate from workers where worker_id = wid) <> 300 then raise exception 'the update did not apply'; end if;
  insert into workers (worker_id, person_id, is_verified) values (worker_s, person_s, true);
  if (select verification_status from workers where worker_id = worker_s) <> 'verified' then raise exception 'seed-style is_verified was lost'; end if;

  raise notice 'worker registration: ok';
end $$;

rollback;
