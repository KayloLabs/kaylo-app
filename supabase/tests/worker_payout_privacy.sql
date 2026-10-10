-- Run after migration 0018 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic persons and workers are created. No external service is called.
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
  worker_a uuid := gen_random_uuid();
  worker_b uuid := gen_random_uuid();
  uid_a text := 'payout_a_' || gen_random_uuid();
  uid_b text := 'payout_b_' || gen_random_uuid();
  n int;
  leaked boolean := false;
begin
  -- 1. The public row no longer carries payout details.
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workers'
      and column_name in ('bank_account', 'upi_id')
  ) then
    raise exception 'workers still has bank_account or upi_id';
  end if;

  insert into persons (person_id, auth_user_id, full_name) values
    (person_a, uid_a, 'Payout Worker A'), (person_b, uid_b, 'Payout Worker B');
  insert into workers (worker_id, person_id) values
    (worker_a, person_a), (worker_b, person_b);

  -- 2. Worker A writes and reads their own payout account.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_a)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  insert into worker_payout_accounts (worker_id, upi_id) values (worker_a, 'a@okbank');
  select count(*) into n from worker_payout_accounts;
  if n <> 1 then
    raise exception 'worker A should see exactly their own payout row, saw %', n;
  end if;

  -- 3. Worker B sees nothing of A's, and cannot write a row for A.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_b)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  select count(*) into n from worker_payout_accounts;
  if n <> 0 then
    raise exception 'worker B can read another worker''s payout row';
  end if;
  begin
    insert into worker_payout_accounts (worker_id, upi_id) values (worker_a, 'b@okbank');
    leaked := true;
  exception when insufficient_privilege then
    null;
  end;
  if leaked then
    raise exception 'worker B could write worker A''s payout row';
  end if;

  -- 4. The marketplace view shows no payout data.
  execute 'reset role';
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'worker_profiles'
      and column_name in ('bank_account', 'upi_id')
  ) then
    raise exception 'worker_profiles exposes payout data';
  end if;

  raise notice 'worker payout privacy: ok';
end $$;

rollback;
