-- Demo offers approved for Kaylo. Payment orders already read estimated_cost.
-- 0016 replaces both offer functions: if this file is ever run again,
-- run 0016 after it, or the shorter offer list comes back.
begin;
alter table bookings add column if not exists subtotal_amount numeric(10,2);
alter table bookings add column if not exists discount_amount numeric(10,2) not null default 0;
alter table bookings add column if not exists offer_code text;

create or replace function kaylo_available_offers(p_exclude_booking uuid default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare
  cid uuid := current_customer_id(); first_ok boolean; reward_ok boolean;
  big_used boolean; weekend_used boolean; reward_used boolean; weekend boolean;
begin
  if cid is null then raise exception 'Sign in to see your offers'; end if;
  select not exists(select 1 from bookings where customer_id=cid and status<>'cancelled'
    and (p_exclude_booking is null or booking_id<>p_exclude_booking)) into first_ok;
  select exists(select 1 from bookings where customer_id=cid and status in ('confirmed','in_progress','completed')
    and (p_exclude_booking is null or booking_id<>p_exclude_booking)) into reward_ok;
  select coalesce(bool_or(offer_code='KAYLO150'),false),
         coalesce(bool_or(offer_code='WEEKEND100'),false), coalesce(bool_or(offer_code='NEXT75'),false)
    into big_used,weekend_used,reward_used
    from bookings where customer_id=cid and status<>'cancelled'
    and (p_exclude_booking is null or booking_id<>p_exclude_booking);
  weekend := extract(isodow from now() at time zone 'Asia/Kolkata') in (6,7);
  return jsonb_build_array(
    jsonb_build_object('code','FIRST100','title','Your first one is special',
      'description','₹100 off your first booking of ₹499 or more.',
      'discount',100,'minimum',499,'eligible',first_ok,'scratch',false,
      'reason',case when not first_ok then 'For your first booking only' end),
    jsonb_build_object('code','KAYLO150','title','A little help with bigger jobs',
      'description','₹150 off a booking of ₹1,499 or more. Once per account.',
      'discount',150,'minimum',1499,'eligible',not big_used,'scratch',false,
      'reason',case when big_used then 'Already used' end),
    jsonb_build_object('code','WEEKEND100','title','A weekend well spent',
      'description','₹100 off ₹999 or more on Saturdays and Sundays. Once per account.',
      'discount',100,'minimum',999,'eligible',weekend and not weekend_used,'scratch',false,
      'reason',case when weekend_used then 'Already used' when not weekend then 'Available on weekends' end),
    jsonb_build_object('code','NEXT75','title','Something for next time',
      'description','₹75 off your next booking of ₹799 or more. Unlocks after a confirmed booking.',
      'discount',75,'minimum',799,'eligible',reward_ok and not reward_used,'scratch',true,
      'reason',case when reward_used then 'Reward used' when not reward_ok then 'Unlocks after your first confirmed booking' end)
  );
end $$;

create or replace function kaylo_apply_booking_offer(p_booking_id uuid,p_code text)
returns jsonb language plpgsql security definer set search_path=public as $$
declare cid uuid:=current_customer_id(); b bookings%rowtype; offer jsonb; base numeric; amount numeric;
begin
  if cid is null then raise exception 'Sign in to apply an offer'; end if;
  -- One customer cannot redeem the same offer on simultaneous checkouts.
  perform 1 from customers where customer_id=cid for update;
  select * into b from bookings where booking_id=p_booking_id and customer_id=cid for update;
  if not found then raise exception 'Booking not found'; end if;
  p_code:=upper(trim(p_code));
  if b.status='cancelled' then raise exception 'This booking was cancelled'; end if;
  if b.offer_code=p_code and b.discount_amount>0 then return to_jsonb(b); end if;
  if b.status<>'pending' or exists(select 1 from payments where booking_id=b.booking_id and payment_status in ('pending','success')) then
    raise exception 'This checkout has already started. Keep its current offer or start a new booking.';
  end if;
  select value into offer from jsonb_array_elements(kaylo_available_offers(b.booking_id)) where value->>'code'=p_code;
  if offer is null then raise exception 'That coupon code is not available'; end if;
  if not (offer->>'eligible')::boolean then raise exception '%',offer->>'reason'; end if;
  base:=coalesce(b.subtotal_amount,b.estimated_cost);
  amount:=(offer->>'discount')::numeric;
  if base is null or base<(offer->>'minimum')::numeric or base<=amount then raise exception 'The booking does not meet this offer’s minimum amount'; end if;
  update bookings set subtotal_amount=base,discount_amount=amount,offer_code=p_code,estimated_cost=base-amount
    where booking_id=b.booking_id returning * into b;
  update caregiver_bookings set total_amount=b.estimated_cost where booking_id=b.booking_id;
  return to_jsonb(b);
end $$;

revoke all on function kaylo_available_offers(uuid) from public;
revoke all on function kaylo_apply_booking_offer(uuid,text) from public;
-- Firebase sessions may use anon; functions still require a verified customer's ID.
grant execute on function kaylo_available_offers(uuid) to anon,authenticated;
grant execute on function kaylo_apply_booking_offer(uuid,text) to anon,authenticated;
-- Preserve chosen addresses and map pins in the primary Care booking too.
create or replace function create_care_checkout(p_request_id uuid, p_kind text, p_details jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  cid uuid := current_customer_id(); bid uuid; sid uuid; fee numeric;
  d doctors%rowtype; c caregivers%rowtype; scheduled date; slot time; hours int; chosen_location uuid;
begin
  if cid is null then raise exception 'Sign in first'; end if;
  select booking_id into bid from bookings where booking_id=p_request_id and customer_id=cid;
  if bid is not null then return bid; end if;
  chosen_location := nullif(p_details->>'location_id','')::uuid;
  if chosen_location is not null and not exists(select 1 from locations where location_id=chosen_location and person_id=current_person_id()) then
    raise exception 'Choose an address saved to your account';
  end if;
  scheduled := (p_details->>'date')::date;
  if scheduled < current_date then raise exception 'Choose a future appointment date'; end if;
  slot := (p_details->>'time')::time;
  if p_kind='doctor' then
    select * into strict d from doctors where id=p_details->>'provider_id' and is_active;
    fee := d.consultation_fee;
    select service_id into sid from services where lower(service_name) like '%doctor%' limit 1;
  elsif p_kind='caregiver' then
    select * into strict c from caregivers where id=p_details->>'provider_id' and is_active;
    hours := (p_details->>'hours')::int;
    if hours not between 1 and 24 then raise exception 'Choose valid hours'; end if;
    fee := c.hourly_rate*hours;
    select service_id into sid from services where lower(service_name) like '%caregiver%' limit 1;
  else raise exception 'Unknown care service'; end if;
  if sid is null then raise exception 'This care service is not available for booking'; end if;
  if fee is null or fee < 1 then raise exception 'This provider has no payable fee'; end if;
  insert into bookings(booking_id,customer_id,service_id,booking_date,booking_time,status,estimated_cost,notes,location_id)
    values(p_request_id,cid,sid,scheduled,slot,'pending',fee,concat_ws(E'\n',case when p_kind='doctor' then d.name else c.name end,nullif(p_details->>'notes','')),chosen_location)
    returning booking_id into bid;
  if p_kind='doctor' then
    insert into doctor_appointments(id,booking_id,customer_id,doctor_id,doctor_name,specialty,hospital,appointment_date,time_slot,consultation_type,status,patient_name,notes)
    values(bid::text,bid,cid,d.id,d.name,d.specialty,d.hospital,((scheduled+slot) at time zone 'Asia/Kolkata'),p_details->>'time_slot',p_details->>'consultation_type','pending',p_details->>'patient_name',p_details->>'notes');
  else
    insert into caregiver_bookings(id,booking_id,customer_id,caregiver_id,caregiver_name,visit_date,start_time,hours,hourly_rate,total_amount,care_type,notes,status)
    values(bid::text,bid,cid,c.id,c.name,scheduled,p_details->>'time_slot',hours,c.hourly_rate,fee,p_details->>'care_type',p_details->>'notes','pending');
  end if;
  return bid;
end $$;

revoke all on function create_care_checkout(uuid,text,jsonb) from public;
grant execute on function create_care_checkout(uuid,text,jsonb) to anon,authenticated;
notify pgrst,'reload schema';
commit;
