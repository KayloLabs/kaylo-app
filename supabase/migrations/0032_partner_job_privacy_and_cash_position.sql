-- Contact details follow the job. A worker sees the customer's phone, house
-- and exact position only while the booking is theirs to do; a request shows
-- the area (rounded coordinates keep the distance estimate), and a finished
-- job keeps only the area. The worker's own stage taps no longer alert them,
-- and my_cash_position() gives the partner app its live cash ledger.
begin;
create or replace function public.my_partner_jobs()
returns table(booking_id uuid,service_name text,service_icon text,customer_name text,customer_phone text,
  address text,latitude double precision,longitude double precision,scheduled_at timestamptz,
  payout numeric,customer_price numeric,payment_mode text,notes text,status text,booking_status text)
language sql stable security definer set search_path='' as $$
  select b.booking_id,s.service_name,s.icon_path,p.full_name,
    case when a.active then p.phone_number end,
    case when a.active then concat_ws(', ',nullif(l.house_name,''),nullif(l.street,''),nullif(l.district,''),nullif(l.pincode,''))
      else concat_ws(', ',nullif(l.district,''),nullif(l.pincode,'')) end,
    case when a.active then l.latitude when b.worker_stage='requested' then round(l.latitude::numeric,2)::double precision end,
    case when a.active then l.longitude when b.worker_stage='requested' then round(l.longitude::numeric,2)::double precision end,
    (b.booking_date+b.booking_time) at time zone 'Asia/Kolkata',
    round(coalesce(b.final_cost,b.estimated_cost,0)*(1-public.kaylo_commission_rate()),2),
    coalesce(b.final_cost,b.estimated_cost,0),b.payment_mode,b.notes,b.worker_stage,b.status::text
  from public.bookings b join public.services s using(service_id) join public.customers c using(customer_id)
    join public.persons p on p.person_id=c.person_id left join public.locations l using(location_id)
    cross join lateral (select b.worker_stage in ('accepted','on_the_way','arrived','in_progress') as active) a
  where b.worker_id=public.current_worker_id() order by b.booking_date desc,b.booking_time desc,b.booking_id;
$$;

-- A change the assigned worker made themselves is not news to them. Requests,
-- reassignments and customer or admin changes still alert the worker.
create or replace function public.notify_worker_about_booking()
returns trigger language plpgsql security definer set search_path='' as $$
declare who uuid; service text; heading text;
begin
  if new.worker_id is null then return new;end if;
  if tg_op='UPDATE' and new.status is not distinct from old.status and new.worker_id is not distinct from old.worker_id and new.worker_stage is not distinct from old.worker_stage then return new;end if;
  if tg_op='UPDATE' and new.worker_id is not distinct from old.worker_id and public.current_worker_id() is not distinct from new.worker_id then return new;end if;
  heading:=case when tg_op='INSERT' or new.worker_id is distinct from old.worker_id then 'New job request'
    when new.status='cancelled' then 'Booking cancelled' when new.status='completed' then 'Job completed'
    when new.worker_stage='accepted' then 'Job accepted' when new.worker_stage='on_the_way' then 'On the way'
    when new.worker_stage='arrived' then 'Arrival confirmed' when new.worker_stage='in_progress' then 'Job started' else null end;
  if heading is null then return new;end if;
  select person_id into who from public.workers where worker_id=new.worker_id;
  select service_name into service from public.services where service_id=new.service_id;
  insert into public.notifications(person_id,title,message,type,booking_id)
    values(who,heading,coalesce(service,'A service')||' on '||to_char(new.booking_date,'DD Mon')||', '||to_char(new.booking_time,'HH12:MI AM')||case when new.payment_mode='cash' then ' - cash' else '' end,
      case when heading='New job request' then 'request' else 'job' end,new.booking_id);
  return new;
end $$;

-- The worker's cash ledger, zero until the first cash job is confirmed.
create or replace function public.my_cash_position()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare me uuid:=public.current_worker_id(); acct public.worker_payout_accounts%rowtype;
begin
  if me is null then raise exception 'Sign in as a worker first';end if;
  select * into acct from public.worker_payout_accounts where worker_id=me;
  return jsonb_build_object('cash_in_hand',coalesce(acct.cash_in_hand,0),'commission_due',coalesce(acct.commission_due,0),
    'limit',public.kaylo_cash_due_limit(),'rate',public.kaylo_commission_rate());
end $$;
revoke all on function public.my_cash_position() from public;
grant execute on function public.my_cash_position() to anon,authenticated;
notify pgrst,'reload schema';
commit;
