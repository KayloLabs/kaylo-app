-- Run after migration 0018 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic persons and workers are created. No external service is called.
begin;

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
  execute 'set local role anon';
  insert into worker_payout_accounts (worker_id, upi_id) values (worker_a, 'a@okbank');
  select count(*) into n from worker_payout_accounts;
  if n <> 1 then
    raise exception 'worker A should see exactly their own payout row, saw %', n;
  end if;

  -- 3. Worker B sees nothing of A's, and cannot write a row for A.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_b)::text, true);
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
