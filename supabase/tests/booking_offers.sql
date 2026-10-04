-- Run after migration 0015 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic accounts, providers, bookings and payments are created.
-- No payment gateway, email, invitation or external service is called.
begin;

do $$
declare
  owner_person uuid := gen_random_uuid();
  other_person uuid := gen_random_uuid();
  care_person uuid := gen_random_uuid();
  owner_customer uuid := gen_random_uuid();
  other_customer uuid := gen_random_uuid();
  care_customer uuid := gen_random_uuid();
  owner_uid text := 'offer_test_owner_' || gen_random_uuid();
  other_uid text := 'offer_test_other_' || gen_random_uuid();
  care_uid text := 'offer_test_care_' || gen_random_uuid();
  category_id_test uuid := gen_random_uuid();
  service_id_test uuid := gen_random_uuid();
  first_booking uuid := gen_random_uuid();
  second_booking uuid := gen_random_uuid();
  third_booking uuid := gen_random_uuid();
  minimum_booking uuid := gen_random_uuid();
  null_price_booking uuid := gen_random_uuid();
  caregiver_booking uuid := gen_random_uuid();
  doctor_booking uuid := gen_random_uuid();
  caregiver_test text := 'offer_test_cg_' || gen_random_uuid();
  doctor_test text := 'offer_test_doc_' || gen_random_uuid();
  care_address uuid := gen_random_uuid();
  other_address uuid := gen_random_uuid();
  payment_test uuid := gen_random_uuid();
  result jsonb;
  offer jsonb;
  denied boolean;
  db_role text;
begin
  insert into persons(person_id, auth_user_id, full_name) values
    (owner_person, owner_uid, 'Offer regression owner'),
    (other_person, other_uid, 'Offer regression other'),
    (care_person, care_uid, 'Offer regression Care');
  insert into customers(customer_id, person_id) values
    (owner_customer, owner_person), (other_customer, other_person),
    (care_customer, care_person);
  insert into service_categories(category_id, category_name, slug) values
    (category_id_test, 'Offer regression ' || category_id_test, 'offer-test-' || category_id_test);
  insert into services(service_id, category_id, service_name, base_price) values
    (service_id_test, category_id_test, 'Offer regression service', 799),
    (gen_random_uuid(), category_id_test, 'Doctor Offer Regression', 800),
    (gen_random_uuid(), category_id_test, 'Caregiver Offer Regression', 400);

  -- The RPCs accept both Firebase's anon route and authenticated sessions.
  foreach db_role in array array['anon', 'authenticated'] loop
    if not has_function_privilege(db_role, 'kaylo_available_offers(uuid)', 'EXECUTE')
       or not has_function_privilege(db_role, 'kaylo_apply_booking_offer(uuid,text)', 'EXECUTE')
       or not has_function_privilege(db_role, 'create_care_checkout(uuid,text,jsonb)', 'EXECUTE') then
      raise exception 'Required checkout RPC is unavailable to %', db_role;
    end if;
  end loop;

  perform set_config('request.jwt.claims', jsonb_build_object('sub', owner_uid)::text, true);
  execute 'set local role anon';
  select value into offer from jsonb_array_elements(kaylo_available_offers())
    where value->>'code' = 'FIRST100';
  if (offer->>'eligible')::boolean is not true then
    raise exception 'New account did not unlock FIRST100';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers())
    where value->>'code' = 'NEXT75';
  if (offer->>'eligible')::boolean is not false then
    raise exception 'NEXT75 unlocked before any confirmed booking';
  end if;
  execute 'reset role';

  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(first_booking, owner_customer, service_id_test, current_date + 1, '09:00', 799);
  execute 'set local role anon';
  result := kaylo_apply_booking_offer(first_booking, ' first100 ');
  if (result->>'estimated_cost')::numeric is distinct from 699
     or (result->>'subtotal_amount')::numeric is distinct from 799
     or (result->>'discount_amount')::numeric is distinct from 100
     or result->>'offer_code' is distinct from 'FIRST100' then
    raise exception 'First booking discount/subtotal was not persisted correctly: %', result;
  end if;
  result := kaylo_apply_booking_offer(first_booking, 'FIRST100');
  if (result->>'estimated_cost')::numeric is distinct from 699 then
    raise exception 'Retry applied the first discount twice';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers())
    where value->>'code' = 'NEXT75';
  if (offer->>'eligible')::boolean is not false then
    raise exception 'A pending booking unlocked NEXT75';
  end if;
  execute 'reset role';

  -- A second account cannot modify the first account's already-discounted row.
  perform set_config('request.jwt.claims', jsonb_build_object('sub', other_uid)::text, true);
  execute 'set local role authenticated';
  denied := false;
  begin
    perform kaylo_apply_booking_offer(first_booking, 'FIRST100');
  exception when raise_exception then
    if sqlerrm <> 'Booking not found' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'Another account modified a booking'; end if;
  execute 'reset role';

  -- FIRST100 minimum is evaluated on the booking subtotal.
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(minimum_booking, other_customer, service_id_test, current_date + 1, '09:00', 498);
  denied := false;
  begin
    perform kaylo_apply_booking_offer(minimum_booking, 'FIRST100');
  exception when raise_exception then
    if sqlerrm not like '%minimum amount%' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'A below-minimum booking received FIRST100'; end if;
  if not exists(select 1 from bookings where booking_id = minimum_booking
    and estimated_cost = 498 and discount_amount = 0 and offer_code is null) then
    raise exception 'Rejected offer changed the booking';
  end if;
  update bookings set estimated_cost = 499 where booking_id = minimum_booking;
  result := kaylo_apply_booking_offer(minimum_booking, 'FIRST100');
  if (result->>'estimated_cost')::numeric is distinct from 399 then
    raise exception 'The exact minimum amount was not accepted';
  end if;

  -- A missing quote must fail validation, not return a NULL discounted total.
  update bookings set status = 'cancelled' where booking_id = minimum_booking;
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(null_price_booking, other_customer, service_id_test, current_date + 1, '09:00', null);
  denied := false;
  begin
    perform kaylo_apply_booking_offer(null_price_booking, 'FIRST100');
  exception when raise_exception then
    if sqlerrm not like '%minimum amount%' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'An unquoted booking accepted a discount'; end if;

  perform set_config('request.jwt.claims', jsonb_build_object('sub', owner_uid)::text, true);
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(second_booking, owner_customer, service_id_test, current_date + 2, '09:00', 1600);
  denied := false;
  begin
    perform kaylo_apply_booking_offer(second_booking, 'FIRST100');
  exception when raise_exception then
    if sqlerrm <> 'For your first booking only' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'A second booking reused FIRST100'; end if;
  result := kaylo_apply_booking_offer(second_booking, 'KAYLO150');
  if (result->>'estimated_cost')::numeric is distinct from 1450 then
    raise exception 'The large-booking discount was not applied';
  end if;

  -- Confirmation unlocks the reward; changing coupon never stacks discounts.
  update bookings set status = 'confirmed' where booking_id = first_booking;
  select value into offer from jsonb_array_elements(kaylo_available_offers(second_booking))
    where value->>'code' = 'NEXT75';
  if (offer->>'eligible')::boolean is not true then
    raise exception 'Confirmation did not unlock NEXT75';
  end if;
  result := kaylo_apply_booking_offer(second_booking, 'NEXT75');
  if (result->>'estimated_cost')::numeric is distinct from 1525
     or (result->>'subtotal_amount')::numeric is distinct from 1600
     or (result->>'discount_amount')::numeric is distinct from 75 then
    raise exception 'Changing the offer stacked discounts: %', result;
  end if;
  result := kaylo_apply_booking_offer(second_booking, 'NEXT75');
  if (result->>'estimated_cost')::numeric is distinct from 1525 then
    raise exception 'NEXT75 retry was not idempotent';
  end if;
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(third_booking, owner_customer, service_id_test, current_date + 3, '09:00', 1000);
  denied := false;
  begin
    perform kaylo_apply_booking_offer(third_booking, 'NEXT75');
  exception when raise_exception then
    if sqlerrm <> 'Reward used' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'NEXT75 was redeemed more than once'; end if;
  insert into payments(booking_id, amount, payment_method, payment_status)
    values(second_booking, 1525, 'offer-regression', 'pending');
  denied := false;
  begin
    perform kaylo_apply_booking_offer(second_booking, 'KAYLO150');
  exception when raise_exception then
    if sqlerrm not like 'This checkout has already started.%' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'An active payment had its amount changed'; end if;

  -- Existing Care payment confirmation and cancellation remain intact.
  insert into caregivers(id, name, hourly_rate) values(caregiver_test, 'Offer test caregiver', 400);
  insert into doctors(id, name, specialty, consultation_fee)
    values(doctor_test, 'Offer test doctor', 'Regression only', 800);
  insert into locations(location_id, person_id, house_name, district, latitude, longitude) values
    (care_address, care_person, 'Care test address', 'Kannur', 11.8745, 75.3704),
    (other_address, other_person, 'Other test address', 'Kochi', 9.9312, 76.2673);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', care_uid)::text, true);
  execute 'set local role anon';
  denied := false;
  begin
    perform create_care_checkout(gen_random_uuid(), 'caregiver', jsonb_build_object(
      'location_id', other_address, 'provider_id', caregiver_test,
      'date', current_date + 1, 'time', '09:00', 'time_slot', '09:00 AM',
      'hours', 2, 'care_type', 'elderlyCare'));
  exception when raise_exception then
    if sqlerrm <> 'Choose an address saved to your account' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'Care accepted another account address'; end if;
  perform create_care_checkout(caregiver_booking, 'caregiver', jsonb_build_object(
    'location_id', care_address, 'provider_id', caregiver_test,
    'date', current_date + 1, 'time', '09:00', 'time_slot', '09:00 AM',
    'hours', 2, 'care_type', 'elderlyCare', 'notes', 'Synthetic visit note'));
  if create_care_checkout(caregiver_booking, 'caregiver', '{}'::jsonb) <> caregiver_booking then
    raise exception 'Care checkout retry created a different booking';
  end if;
  result := kaylo_apply_booking_offer(caregiver_booking, 'FIRST100');
  if (result->>'estimated_cost')::numeric is distinct from 700 then
    raise exception 'Care offer did not use the provider fee';
  end if;
  execute 'reset role';
  if not exists(select 1 from bookings where booking_id = caregiver_booking
    and status = 'pending' and location_id = care_address
    and notes like '%Synthetic visit note%') then
    raise exception 'Care address/notes were not retained, or payment was bypassed';
  end if;
  if not exists(select 1 from caregiver_bookings where booking_id = caregiver_booking
    and total_amount = 700 and status = 'pending') then
    raise exception 'Linked caregiver booking lost its discount or pending state';
  end if;
  insert into payments(payment_id, booking_id, amount, payment_method, payment_status)
    values(payment_test, caregiver_booking, 700, 'offer-regression', 'pending');
  update payments set payment_status = 'success' where payment_id = payment_test;
  if not exists(select 1 from bookings where booking_id = caregiver_booking and status = 'confirmed')
     or not exists(select 1 from caregiver_bookings where booking_id = caregiver_booking and status = 'confirmed') then
    raise exception 'Paid caregiver booking did not confirm';
  end if;
  update bookings set status = 'cancelled' where booking_id = caregiver_booking;
  if not exists(select 1 from caregiver_bookings where booking_id = caregiver_booking and status = 'cancelled') then
    raise exception 'Care cancellation stopped synchronizing';
  end if;
  perform create_care_checkout(doctor_booking, 'doctor', jsonb_build_object(
    'location_id', care_address, 'provider_id', doctor_test,
    'date', current_date + 2, 'time', '10:00', 'time_slot', '10:00 AM',
    'consultation_type', 'homeVisit', 'patient_name', 'Regression patient'));
  if not exists(select 1 from doctor_appointments where booking_id = doctor_booking and status = 'pending')
     or not exists(select 1 from bookings where booking_id = doctor_booking and location_id = care_address and estimated_cost = 800) then
    raise exception 'Doctor checkout behavior changed unexpectedly';
  end if;

  -- Granting anon execute never authorizes an unsigned request.
  perform set_config('request.jwt.claims', '{}', true);
  execute 'set local role anon';
  denied := false;
  begin
    perform kaylo_available_offers();
  exception when raise_exception then
    if sqlerrm <> 'Sign in to see your offers' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'Unsigned request can read account offers'; end if;
  denied := false;
  begin
    perform kaylo_apply_booking_offer(first_booking, 'FIRST100');
  exception when raise_exception then
    if sqlerrm <> 'Sign in to apply an offer' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'Unsigned request can apply an offer'; end if;
  execute 'reset role';
  raise notice 'Booking offer and Care regressions passed; rolling back fixtures.';
end $$;

rollback;
