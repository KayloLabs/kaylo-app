-- More offers, offers tied to one kind of service, and online checkouts
-- that were opened but never paid no longer using up an offer.
-- Replaces the two offer functions from 0015. Safe to run more than once;
-- when re-applying older files, run this one after them.
begin;

-- An online checkout that was opened and never paid: a Razorpay order
-- exists for the booking, no payment succeeded. A pay-after-service
-- booking has no payment row at all, so it still counts as a booking.
create or replace function kaylo_unpaid_checkout(p_booking_id uuid, p_status booking_status)
returns boolean language sql stable security definer set search_path = public as $$
  select p_status = 'pending'
    and exists(select 1 from payments where booking_id = p_booking_id and payment_method like 'razorpay%')
    and not exists(select 1 from payments where booking_id = p_booking_id and payment_status = 'success');
$$;
-- Internal: only the offer functions below call it.
revoke all on function kaylo_unpaid_checkout(uuid, booking_status) from public, anon, authenticated;

-- Every offer with whether this customer can use it. `reason_code` lets the
-- app explain in the customer's language; `reason` is the English fallback.
-- `category` is a service_categories slug, or null for any booking.
create or replace function kaylo_available_offers(p_exclude_booking uuid default null)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  cid uuid := current_customer_id();
  rs text := chr(8377); -- the rupee sign, kept out of the source text
  booked int; settled int; used text[]; dow int;
begin
  if cid is null then raise exception 'Sign in to see your offers'; end if;
  select count(*),
         count(*) filter (where b.status in ('confirmed', 'in_progress', 'completed')),
         coalesce(array_agg(b.offer_code) filter (where b.offer_code is not null), '{}')
    into booked, settled, used
    from bookings b
   where b.customer_id = cid and b.status <> 'cancelled'
     and (p_exclude_booking is null or b.booking_id <> p_exclude_booking)
     and not kaylo_unpaid_checkout(b.booking_id, b.status);
  dow := extract(isodow from now() at time zone 'Asia/Kolkata');
  return (
    select jsonb_agg(jsonb_build_object(
        'code', o.code, 'title', o.title, 'description', o.description,
        'discount', o.discount, 'minimum', o.minimum, 'category', o.category,
        'scratch', o.scratch, 'eligible', o.why is null, 'reason_code', o.why,
        'reason', case o.why
          when 'first_only' then 'For your first booking only'
          when 'used' then 'Already used'
          when 'reward_used' then 'Reward used'
          when 'weekend_only' then 'Available on weekends'
          when 'weekday_only' then 'Available Monday to Friday'
          when 'needs_confirmed' then 'Unlocks after your first confirmed booking'
          when 'needs_three' then 'Unlocks after three confirmed bookings'
        end) order by o.pos)
    from (values
      (1, 'FIRST100', 'Your first one is special',
        rs || '100 off your first booking of ' || rs || '499 or more.',
        100, 499, null::text, false,
        case when booked > 0 then 'first_only' end),
      (2, 'KAYLO150', 'A little help with bigger jobs',
        rs || '150 off a booking of ' || rs || '1,499 or more. Once per account.',
        150, 1499, null, false,
        case when 'KAYLO150' = any(used) then 'used' end),
      (3, 'WEEKEND100', 'A weekend well spent',
        rs || '100 off ' || rs || '999 or more on Saturdays and Sundays. Once per account.',
        100, 999, null, false,
        case when 'WEEKEND100' = any(used) then 'used' when dow not in (6, 7) then 'weekend_only' end),
      (4, 'WEEKDAY50', 'A midweek lift',
        rs || '50 off ' || rs || '599 or more, Monday to Friday. Once per account.',
        50, 599, null, false,
        case when 'WEEKDAY50' = any(used) then 'used' when dow in (6, 7) then 'weekday_only' end),
      (5, 'HOME80', 'Home, sorted',
        rs || '80 off a home service of ' || rs || '499 or more. Once per account.',
        80, 499, 'home', false,
        case when 'HOME80' = any(used) then 'used' end),
      (6, 'FARM125', 'For the land that feeds us',
        rs || '125 off a farm service of ' || rs || '999 or more. Once per account.',
        125, 999, 'farm', false,
        case when 'FARM125' = any(used) then 'used' end),
      (7, 'CARE60', 'Care, made a little lighter',
        rs || '60 off a Care booking of ' || rs || '399 or more. Once per account.',
        60, 399, 'care', false,
        case when 'CARE60' = any(used) then 'used' end),
      (8, 'KAYLO300', 'For the really big days',
        rs || '300 off a booking of ' || rs || '2,999 or more. Once per account.',
        300, 2999, null, false,
        case when 'KAYLO300' = any(used) then 'used' end),
      (9, 'NEXT75', 'Something for next time',
        rs || '75 off your next booking of ' || rs || '799 or more. Unlocks after a confirmed booking.',
        75, 799, null, true,
        case when 'NEXT75' = any(used) then 'reward_used' when settled < 1 then 'needs_confirmed' end),
      (10, 'THANKS120', 'Three bookings in. Thank you.',
        rs || '120 off a booking of ' || rs || '999 or more. Unlocks after three confirmed bookings.',
        120, 999, null, true,
        case when 'THANKS120' = any(used) then 'reward_used' when settled < 3 then 'needs_three' end)
    ) as o(pos, code, title, description, discount, minimum, category, scratch, why)
  );
end $$;

create or replace function kaylo_apply_booking_offer(p_booking_id uuid, p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  cid uuid := current_customer_id(); b bookings%rowtype; offer jsonb;
  base numeric; amount numeric; kind text;
begin
  if cid is null then raise exception 'Sign in to apply an offer'; end if;
  -- One customer cannot redeem the same offer on simultaneous checkouts.
  perform 1 from customers where customer_id = cid for update;
  select * into b from bookings where booking_id = p_booking_id and customer_id = cid for update;
  if not found then raise exception 'Booking not found'; end if;
  p_code := upper(trim(p_code));
  if b.status = 'cancelled' then raise exception 'This booking was cancelled'; end if;
  if b.offer_code = p_code and b.discount_amount > 0 then return to_jsonb(b); end if;
  if b.status <> 'pending' or exists(select 1 from payments where booking_id = b.booking_id and payment_status in ('pending', 'success')) then
    raise exception 'This checkout has already started. Keep its current offer or start a new booking.';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers(b.booking_id)) where value->>'code' = p_code;
  if offer is null then raise exception 'That coupon code is not available'; end if;
  if not (offer->>'eligible')::boolean then raise exception '%', offer->>'reason'; end if;
  if offer->>'category' is not null then
    select c.slug into kind from services s join service_categories c on c.category_id = s.category_id
     where s.service_id = b.service_id;
    if kind is distinct from offer->>'category' then
      raise exception 'This offer is for % bookings only', offer->>'category';
    end if;
  end if;
  base := coalesce(b.subtotal_amount, b.estimated_cost);
  amount := (offer->>'discount')::numeric;
  if base is null or base < (offer->>'minimum')::numeric or base <= amount then
    raise exception 'The booking does not meet the minimum amount for this offer';
  end if;
  -- The same code may still sit on a checkout this customer opened and never
  -- paid. That booking gives it up here, so it cannot be paid later at the
  -- discount: a new payment order always reads the current total.
  with released as (
    update bookings o
       set estimated_cost = coalesce(o.subtotal_amount, o.estimated_cost), discount_amount = 0, offer_code = null
     where o.customer_id = cid and o.booking_id <> b.booking_id and o.offer_code = p_code
       and kaylo_unpaid_checkout(o.booking_id, o.status)
    returning o.booking_id, o.estimated_cost)
  update caregiver_bookings c set total_amount = r.estimated_cost from released r where c.booking_id = r.booking_id;
  update bookings set subtotal_amount = base, discount_amount = amount, offer_code = p_code, estimated_cost = base - amount
    where booking_id = b.booking_id returning * into b;
  update caregiver_bookings set total_amount = b.estimated_cost where booking_id = b.booking_id;
  return to_jsonb(b);
end $$;

revoke all on function kaylo_available_offers(uuid) from public;
revoke all on function kaylo_apply_booking_offer(uuid, text) from public;
-- Firebase sessions may use anon; both functions still require a verified customer.
grant execute on function kaylo_available_offers(uuid) to anon, authenticated;
grant execute on function kaylo_apply_booking_offer(uuid, text) to anon, authenticated;
notify pgrst, 'reload schema';
commit;
