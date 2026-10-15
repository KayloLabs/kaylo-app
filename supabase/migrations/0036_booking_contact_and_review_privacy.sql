begin;

alter table public.reviews add column if not exists hide_name boolean not null default false;
drop policy if exists "reviews are public" on public.reviews;
drop policy if exists "customers read own reviews" on public.reviews;
create policy "customers read own reviews" on public.reviews for select to anon, authenticated
  using(customer_id = public.current_customer_id());

-- Public display is a projection, never the underlying customer/booking ids.
create or replace function public.public_worker_reviews(p_worker_id uuid)
returns table(review_id uuid,worker_id uuid,rating integer,review text,created_at timestamptz,customer_name text)
language sql stable security definer set search_path='' as $$
 select r.review_id,r.worker_id,r.rating,r.review,r.created_at,
   case when r.hide_name then 'Verified customer' else p.full_name end
 from public.reviews r join public.customers c using(customer_id)
 join public.persons p on p.person_id=c.person_id
 where r.worker_id=p_worker_id order by r.created_at desc,r.review_id;
$$;
revoke all on function public.public_worker_reviews(uuid) from public;
grant execute on function public.public_worker_reviews(uuid) to anon,authenticated;

-- Preserve the old signature for older clients without resetting a privacy choice.
create or replace function public.submit_review(p_booking_id uuid,p_rating int,p_review text,p_hide_name boolean)
returns jsonb language plpgsql security definer set search_path=public as $$
declare me uuid:=current_customer_id(); b bookings%rowtype; rid uuid;
begin
 if me is null then raise exception 'Sign in first'; end if;
 if p_rating is null or p_rating not between 1 and 5 then raise exception 'Rating must be between 1 and 5'; end if;
 select * into b from bookings where booking_id=p_booking_id;
 if b.booking_id is null or b.customer_id<>me then raise exception 'This booking is not yours'; end if;
 if b.status<>'completed' or b.worker_id is null then raise exception 'Review a completed worker booking'; end if;
 insert into reviews(booking_id,customer_id,worker_id,rating,review,hide_name)
 values(p_booking_id,me,b.worker_id,p_rating,nullif(trim(coalesce(p_review,'')),''),coalesce(p_hide_name,false))
 on conflict(booking_id) do update set rating=excluded.rating,review=excluded.review,hide_name=excluded.hide_name
 returning reviews.review_id into rid;
 return jsonb_build_object('review_id',rid,'rating',p_rating);
end $$;
revoke all on function public.submit_review(uuid,int,text,boolean) from public;
grant execute on function public.submit_review(uuid,int,text,boolean) to anon,authenticated;

create or replace function public.my_worker_reviews()
returns table(review_id uuid,booking_id uuid,customer_name text,service_name text,rating integer,review text,created_at timestamptz)
language sql stable security definer set search_path='' as $$
 select r.review_id,case when r.hide_name then null::uuid else r.booking_id end,
 case when r.hide_name then 'Verified customer' else p.full_name end,s.service_name,r.rating,r.review,r.created_at
 from public.reviews r join public.bookings b using(booking_id)
 join public.customers c on c.customer_id=r.customer_id
 join public.persons p on p.person_id=c.person_id join public.services s on s.service_id=b.service_id
 where r.worker_id=public.current_worker_id() order by r.created_at desc,r.review_id;
$$;

-- Preserve the existing return signature; payment status is fetched separately.
create or replace function public.my_partner_payment_states()
returns table(booking_id uuid,payment_status text)
language sql stable security definer set search_path='' as $$
 select b.booking_id,case when exists(select 1 from public.payments p where p.booking_id=b.booking_id and p.payment_status='success') then 'success' else 'pending' end
 from public.bookings b where b.worker_id=public.current_worker_id();
$$;
revoke all on function public.my_partner_payment_states() from public;
grant execute on function public.my_partner_payment_states() to anon,authenticated;

alter table public.care_calls add column if not exists booking_id uuid references public.bookings(booking_id) on delete cascade;
create index if not exists care_calls_booking_idx on public.care_calls(booking_id,created_at desc) where booking_id is not null;
create or replace function public.start_booking_call(p_booking_id uuid)
returns uuid language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); b bookings%rowtype; cp uuid; wp uuid; cid uuid;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 select * into b from bookings where booking_id=p_booking_id for update;
 select person_id into cp from customers where customer_id=b.customer_id;
 select person_id into wp from workers where worker_id=b.worker_id;
 if b.booking_id is null or wp is null or cp is null or pid not in(cp,wp) then raise exception 'This booking is not yours'; end if;
 if b.worker_stage not in('accepted','on_the_way','arrived','in_progress') then raise exception 'Calls are available during an accepted booking'; end if;
 select c.id into cid from care_calls c where c.booking_id=p_booking_id and c.ended_at is null and c.expires_at>now()
 and not exists(select 1 from care_call_members m where m.call_id=c.id and m.status in('declined','left'))
 and (c.created_at>now()-interval '2 minutes' or not exists(select 1 from care_call_members m where m.call_id=c.id and m.status='invited'))
 order by c.created_at desc limit 1;
 if cid is not null then return cid; end if;
 update care_calls set ended_at=now() where booking_id=p_booking_id and ended_at is null;
 insert into care_calls(owner_id,booking_id) values(pid,p_booking_id) returning id into cid;
 insert into care_call_members(call_id,person_id,name,status)
 select cid,person_id,full_name,case when person_id=pid then 'joined' else 'invited' end
 from persons where person_id in(cp,wp);
 return cid;
end $$;
revoke all on function public.start_booking_call(uuid) from public;
grant execute on function public.start_booking_call(uuid) to anon,authenticated;

-- SOS must never reuse a booking room owned by the same person.
do $$
declare definition text;
begin
 select pg_get_functiondef('public.start_care_call()'::regprocedure) into definition;
 definition:=replace(definition,'where owner_id=pid and ended_at is null','where owner_id=pid and booking_id is null and ended_at is null');
 execute definition;
end $$;
notify pgrst,'reload schema';
commit;
