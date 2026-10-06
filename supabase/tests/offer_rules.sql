-- Run after migration 0016 as the migration/database owner.
-- This file owns its transaction and always rolls back on success. A failed
-- assertion aborts the transaction; ROLLBACK it before continuing in that session.
-- Only synthetic accounts, services, bookings and payments are created.
-- No payment gateway, email or external service is called.
begin;

do $$
declare
  person uuid := gen_random_uuid();
  customer uuid := gen_random_uuid();
  uid text := 'offer_rules_' || gen_random_uuid();
  home_service uuid := gen_random_uuid();
  farm_service uuid := gen_random_uuid();
  care_service uuid := gen_random_uuid();
  abandoned uuid := gen_random_uuid();
  retry uuid := gen_random_uuid();
  third uuid := gen_random_uuid();
  farm_booking uuid := gen_random_uuid();
  farm_again uuid := gen_random_uuid();
  home_booking uuid := gen_random_uuid();
  care_booking uuid := gen_random_uuid();
  thanks_booking uuid := gen_random_uuid();
  result jsonb;
  offer jsonb;
  denied boolean;
  codes int;
  weekend boolean;
begin
  insert into persons(person_id, auth_user_id, full_name) values (person, uid, 'Offer rules owner');
  insert into customers(customer_id, person_id) values (customer, person);
  insert into services(service_id, category_id, service_name, base_price)
    select home_service, category_id, 'Offer rules home ' || home_service, 900 from service_categories where slug = 'home';
  insert into services(service_id, category_id, service_name, base_price)
    select farm_service, category_id, 'Offer rules farm ' || farm_service, 1200 from service_categories where slug = 'farm';
  insert into services(service_id, category_id, service_name, base_price)
    select care_service, category_id, 'Offer rules care ' || care_service, 500 from service_categories where slug = 'care';
  if (select count(*) from services where service_id in (home_service, farm_service, care_service)) <> 3 then
    raise exception 'The home, farm and care categories are not all present';
  end if;

  if has_function_privilege('anon', 'kaylo_unpaid_checkout(uuid,booking_status)', 'EXECUTE')
     or has_function_privilege('authenticated', 'kaylo_unpaid_checkout(uuid,booking_status)', 'EXECUTE') then
    raise exception 'The internal checkout helper is callable from the app';
  end if;

  perform set_config('request.jwt.claims', jsonb_build_object('sub', uid)::text, true);
  select count(distinct value->>'code') into codes from jsonb_array_elements(kaylo_available_offers());
  if codes <> 10 then raise exception 'Expected ten offers, found %', codes; end if;

  -- An online checkout that was opened and never paid does not use up an offer.
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(abandoned, customer, home_service, current_date + 1, '09:00', 900);
  result := kaylo_apply_booking_offer(abandoned, 'FIRST100');
  if (result->>'estimated_cost')::numeric is distinct from 800 then
    raise exception 'FIRST100 was not applied to the first checkout';
  end if;
  insert into payments(booking_id, amount, payment_method, payment_status)
    values(abandoned, 800, 'razorpay', 'pending');
  select value into offer from jsonb_array_elements(kaylo_available_offers()) where value->>'code' = 'FIRST100';
  if (offer->>'eligible')::boolean is not true then
    raise exception 'A checkout that was never paid still holds FIRST100';
  end if;
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(retry, customer, home_service, current_date + 1, '10:00', 900);
  result := kaylo_apply_booking_offer(retry, 'FIRST100');
  if (result->>'estimated_cost')::numeric is distinct from 800 then
    raise exception 'The retried booking did not get FIRST100';
  end if;
  if not exists(select 1 from bookings where booking_id = abandoned and offer_code is null
                and discount_amount = 0 and estimated_cost = 900) then
    raise exception 'The unpaid checkout kept a discount it had given up';
  end if;

  -- A pay-after-service booking has no payment row and is a real booking.
  select value into offer from jsonb_array_elements(kaylo_available_offers()) where value->>'code' = 'FIRST100';
  if (offer->>'eligible')::boolean is not false or offer->>'reason_code' <> 'first_only' then
    raise exception 'A pay-after-service booking did not count as the first booking';
  end if;
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(third, customer, home_service, current_date + 2, '09:00', 900);
  denied := false;
  begin
    perform kaylo_apply_booking_offer(third, 'FIRST100');
  exception when raise_exception then
    if sqlerrm <> 'For your first booking only' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'FIRST100 was used on a second real booking'; end if;

  -- Offers tied to one kind of service.
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(farm_booking, customer, farm_service, current_date + 3, '09:00', 1200),
          (farm_again, customer, farm_service, current_date + 4, '09:00', 1200),
          (home_booking, customer, home_service, current_date + 3, '11:00', 900),
          (care_booking, customer, care_service, current_date + 3, '13:00', 500);
  denied := false;
  begin
    perform kaylo_apply_booking_offer(farm_booking, 'HOME80');
  exception when raise_exception then
    if sqlerrm <> 'This offer is for home bookings only' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'A farm booking accepted the home offer'; end if;
  result := kaylo_apply_booking_offer(farm_booking, 'FARM125');
  if (result->>'estimated_cost')::numeric is distinct from 1075 then
    raise exception 'FARM125 was not applied to a farm booking';
  end if;
  denied := false;
  begin
    perform kaylo_apply_booking_offer(farm_again, 'FARM125');
  exception when raise_exception then
    if sqlerrm <> 'Already used' then raise; end if;
    denied := true;
  end;
  if not denied then raise exception 'FARM125 was used twice on one account'; end if;
  result := kaylo_apply_booking_offer(home_booking, 'HOME80');
  if (result->>'estimated_cost')::numeric is distinct from 820 then
    raise exception 'HOME80 was not applied to a home booking';
  end if;
  result := kaylo_apply_booking_offer(care_booking, 'CARE60');
  if (result->>'estimated_cost')::numeric is distinct from 440 then
    raise exception 'CARE60 was not applied to a Care booking';
  end if;

  -- The second scratch reward unlocks after three confirmed bookings.
  select value into offer from jsonb_array_elements(kaylo_available_offers()) where value->>'code' = 'THANKS120';
  if (offer->>'eligible')::boolean is not false or offer->>'reason_code' <> 'needs_three' then
    raise exception 'THANKS120 unlocked before three confirmed bookings';
  end if;
  update bookings set status = 'confirmed' where booking_id in (retry, farm_booking, home_booking);
  select value into offer from jsonb_array_elements(kaylo_available_offers()) where value->>'code' = 'THANKS120';
  if (offer->>'eligible')::boolean is not true or (offer->>'scratch')::boolean is not true then
    raise exception 'Three confirmed bookings did not unlock THANKS120';
  end if;
  insert into bookings(booking_id, customer_id, service_id, booking_date, booking_time, estimated_cost)
    values(thanks_booking, customer, farm_service, current_date + 5, '09:00', 1500);
  result := kaylo_apply_booking_offer(thanks_booking, 'THANKS120');
  if (result->>'estimated_cost')::numeric is distinct from 1380 then
    raise exception 'THANKS120 was not applied';
  end if;

  -- Exactly one of the two day-of-week offers is open on any given day.
  weekend := extract(isodow from now() at time zone 'Asia/Kolkata') in (6, 7);
  select value into offer from jsonb_array_elements(kaylo_available_offers()) where value->>'code' = 'WEEKEND100';
  if (offer->>'eligible')::boolean is distinct from weekend then
    raise exception 'WEEKEND100 does not follow the weekend';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers()) where value->>'code' = 'WEEKDAY50';
  if (offer->>'eligible')::boolean is distinct from (not weekend) then
    raise exception 'WEEKDAY50 does not follow the working week';
  end if;
end $$;

rollback;
