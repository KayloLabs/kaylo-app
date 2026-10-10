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
  person_c uuid := gen_random_uuid();
  customer uuid := gen_random_uuid();
  uid_c text := 'cash_c_' || gen_random_uuid();
  person_a uuid := gen_random_uuid();
  worker_a uuid := gen_random_uuid();
  uid_a text := 'cash_a_' || gen_random_uuid();
  person_b uuid := gen_random_uuid();
  worker_b uuid := gen_random_uuid();
  uid_b text := 'cash_b_' || gen_random_uuid();
  svc uuid := gen_random_uuid();
  cash_booking uuid := gen_random_uuid();
  online_booking uuid := gen_random_uuid();
  second_cash uuid := gen_random_uuid();
  r jsonb;
  n int;
  denied boolean;
  acct record;
begin
  insert into persons (person_id, auth_user_id, full_name) values
    (person_c, uid_c, 'Cash customer'), (person_a, uid_a, 'Cash worker A'), (person_b, uid_b, 'Cash worker B');
  insert into customers (customer_id, person_id) values (customer, person_c);
  insert into workers (worker_id, person_id) values (worker_a, person_a), (worker_b, person_b);
  insert into services (service_id, category_id, service_name, base_price)
    select svc, category_id, 'Cash test service ' || svc, 1000 from service_categories where slug = 'home';
  if not found then raise exception 'The home category is missing'; end if;

  -- 1. A cash booking carries a pending cash payment and alerts the worker.
  insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost, payment_mode)
    values (cash_booking, customer, worker_a, svc, current_date + 1, '09:00', 1000, 'cash');
  if not exists (select 1 from payments where booking_id = cash_booking
                 and payment_method = 'cash' and payment_status = 'pending' and amount = 1000) then
    raise exception 'cash booking has no pending cash payment';
  end if;
  if not exists (select 1 from notifications where person_id = person_a and title = 'New job request') then
    raise exception 'the worker was not told about the new request';
  end if;
  insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost)
    values (online_booking, customer, worker_a, svc, current_date + 1, '11:00', 1000);
  if exists (select 1 from payments where booking_id = online_booking) then
    raise exception 'an online booking got a cash payment row';
  end if;

  -- 2. Worker B cannot touch worker A's job.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_b)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  denied := false;
  begin perform worker_advance_booking(cash_booking, 'accepted'); exception when others then denied := true; end;
  if not denied then raise exception 'worker B advanced worker A''s job'; end if;

  -- 3. Worker A walks the job, in order only.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_a)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  r := worker_advance_booking(cash_booking, 'accepted');
  if (r->>'status') <> 'confirmed' then raise exception 'accepting did not confirm the booking: %', r; end if;
  denied := false;
  begin perform worker_advance_booking(cash_booking, 'in_progress'); exception when others then denied := true; end;
  if not denied then raise exception 'skipping stages was allowed'; end if;
  perform worker_advance_booking(cash_booking, 'on_the_way');
  perform worker_advance_booking(cash_booking, 'arrived');
  r := worker_advance_booking(cash_booking, 'in_progress');
  if (r->>'status') <> 'in_progress' then raise exception 'starting the job did not set in_progress'; end if;
  denied := false;
  begin perform worker_advance_booking(cash_booking, 'completed'); exception when others then denied := true; end;
  if not denied then raise exception 'a cash job completed without the cash being confirmed'; end if;
  execute 'reset role';

  -- 4. The customer heard the worker was on the way, then arrived.
  select count(*) into n from notifications
    where person_id = person_c and title in ('Your worker is on the way', 'Your worker has arrived');
  if n <> 2 then raise exception 'customer got % stage notifications, expected 2', n; end if;

  -- 5. Cash collected: payment done, job completed, ledger updated, once.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_a)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  r := confirm_cash_collected(cash_booking);
  if (r->>'amount')::numeric <> 1000 or (r->>'commission')::numeric <> 150 then
    raise exception 'wrong cash numbers: %', r;
  end if;
  denied := false;
  begin perform confirm_cash_collected(cash_booking); exception when others then denied := true; end;
  if not denied then raise exception 'cash was confirmed twice'; end if;
  execute 'reset role';
  if not exists (select 1 from payments where booking_id = cash_booking
                 and payment_status = 'success' and payment_method = 'cash' and amount = 1000) then
    raise exception 'the cash payment was not marked success';
  end if;
  if (select status from bookings where booking_id = cash_booking) <> 'completed' then
    raise exception 'the booking is not completed after the cash confirmation';
  end if;
  select cash_in_hand, commission_due into acct from worker_payout_accounts where worker_id = worker_a;
  if acct.cash_in_hand <> 1000 or acct.commission_due <> 150 then
    raise exception 'ledger wrong: cash % due %', acct.cash_in_hand, acct.commission_due;
  end if;
  if (select total_jobs from workers where worker_id = worker_a) <> 1 then
    raise exception 'total_jobs was not bumped';
  end if;
  if not exists (select 1 from notifications where person_id = person_c and title = 'Booking confirmed')
     or not exists (select 1 from notifications where person_id = person_c and title = 'Work has started')
     or not exists (select 1 from notifications where person_id = person_c and title = 'Booking completed') then
    raise exception 'the customer missed a status notification for a worker-driven change';
  end if;
  if not exists (select 1 from notifications where person_id = person_a and title = 'Job completed') then
    raise exception 'the worker was not told the job completed';
  end if;

  -- 6. At the limit, new cash jobs cannot be accepted; online ones can.
  update worker_payout_accounts set commission_due = kaylo_cash_due_limit() where worker_id = worker_a;
  insert into bookings (booking_id, customer_id, worker_id, service_id, booking_date, booking_time, estimated_cost, payment_mode)
    values (second_cash, customer, worker_a, svc, current_date + 2, '09:00', 500, 'cash');
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_a)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  denied := false;
  begin perform worker_advance_booking(second_cash, 'accepted'); exception when others then denied := true; end;
  if not denied then raise exception 'a cash job was accepted while over the limit'; end if;
  perform worker_advance_booking(online_booking, 'accepted');

  -- 7. Settling clears the due and leaves a settlement the worker can see.
  r := settle_cash_due('test');
  if (r->>'amount')::numeric <> kaylo_cash_due_limit() then raise exception 'settled the wrong amount: %', r; end if;
  select count(*) into n from settlements;
  if n <> 1 then raise exception 'the worker cannot see their settlement'; end if;
  perform worker_advance_booking(second_cash, 'accepted');
  denied := false;
  begin perform settle_cash_due(); exception when others then denied := true; end;
  if not denied then raise exception 'settled with nothing due'; end if;
  execute 'reset role';
  select cash_in_hand, commission_due into acct from worker_payout_accounts where worker_id = worker_a;
  if acct.commission_due <> 0 or acct.cash_in_hand <> 0 then raise exception 'the ledger was not cleared'; end if;

  -- 8. The customer reviews the finished job, only that one, and may edit it.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid_c)::text, true);
  perform pg_temp.use_issued_worker_fixture();
  execute 'set local role anon';
  r := submit_review(cash_booking, 4, '  Good work  ');
  denied := false;
  begin perform submit_review(online_booking, 5, null); exception when others then denied := true; end;
  if not denied then raise exception 'reviewed a booking that is not completed'; end if;
  denied := false;
  begin perform submit_review(cash_booking, 6, null); exception when others then denied := true; end;
  if not denied then raise exception 'a rating of 6 was accepted'; end if;
  r := submit_review(cash_booking, 5, null);
  execute 'reset role';
  select count(*) into n from reviews where booking_id = cash_booking;
  if n <> 1 then raise exception 'expected one review, found %', n; end if;
  if (select rating from reviews where booking_id = cash_booking) <> 5 then raise exception 'the review edit was lost'; end if;
  if (select review from reviews where booking_id = cash_booking) is not null then raise exception 'an empty edit did not clear the text'; end if;
  if (select average_rating from workers where worker_id = worker_a) <> 5 then raise exception 'average rating not refreshed'; end if;

  raise notice 'cash flow: ok';
end $$;

rollback;
