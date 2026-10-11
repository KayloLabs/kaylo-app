-- Booking-scoped communication. Existing rooms/messages and notifications survive.
begin;
alter table public.messages add column if not exists client_message_id uuid;
alter table public.messages add column if not exists read_at timestamptz;
create unique index if not exists messages_client_retry on public.messages(room_id,sender_id,client_message_id) where client_message_id is not null;
create index if not exists messages_room_latest on public.messages(room_id,sent_at desc,message_id desc);
create index if not exists messages_unread_room on public.messages(room_id,sender_id) where read_at is null;
alter table public.notifications add column if not exists booking_id uuid references public.bookings(booking_id) on delete set null;
create table if not exists public.chat_typing (
  room_id uuid not null references public.chat_rooms(room_id) on delete cascade,
  person_id uuid not null references public.persons(person_id) on delete cascade,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now(),
  primary key(room_id,person_id)
);
alter table public.chat_typing enable row level security;

create or replace function public.chat_is_member(p_room_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.chat_rooms r join public.bookings b using(booking_id)
    where r.room_id=p_room_id and b.worker_id is not null
      and b.status in ('confirmed','in_progress','completed','cancelled')
      and (b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id()));
$$;
drop policy if exists "participants read rooms" on public.chat_rooms;
drop policy if exists "participants create rooms" on public.chat_rooms;
drop policy if exists "participants read messages" on public.messages;
drop policy if exists "participants send messages" on public.messages;
drop policy if exists "booking members read rooms" on public.chat_rooms;
drop policy if exists "booking members read messages" on public.messages;
drop policy if exists "booking members read typing" on public.chat_typing;
create policy "booking members read rooms" on public.chat_rooms for select to anon,authenticated using(public.chat_is_member(room_id));
create policy "booking members read messages" on public.messages for select to anon,authenticated using(public.chat_is_member(room_id));
create policy "booking members read typing" on public.chat_typing for select to anon,authenticated using(public.chat_is_member(room_id));
revoke insert,update,delete,truncate on public.chat_rooms,public.messages,public.chat_typing from public,anon,authenticated;
grant select on public.chat_rooms,public.messages,public.chat_typing to anon,authenticated;
grant all on public.chat_typing to service_role;

create or replace function public.chat_threads()
returns table(room_id uuid,booking_id uuid,other_person_id uuid,other_name text,worker_id uuid,
  service_name text,booking_status text,last_message text,last_message_at timestamptz,unread_count bigint,can_send boolean)
language sql stable security definer set search_path='' as $$
  with me as (select public.current_customer_id() customer_id,public.current_worker_id() worker_id,public.current_person_id() person_id),
  mine as (
    select r.room_id,b.booking_id,b.worker_id,b.status,b.worker_stage,s.service_name,
      case when b.customer_id=me.customer_id then wp.person_id else cp.person_id end other_person_id,
      case when b.customer_id=me.customer_id then wp.full_name else cp.full_name end other_name,me.person_id
    from public.chat_rooms r join public.bookings b using(booking_id)
    join public.customers c using(customer_id) join public.persons cp on cp.person_id=c.person_id
    join public.workers w on w.worker_id=b.worker_id join public.persons wp on wp.person_id=w.person_id
    join public.services s using(service_id) cross join me
    where me.person_id is not null and (b.customer_id=me.customer_id or b.worker_id=me.worker_id)
      and b.status in ('confirmed','in_progress','completed','cancelled')
  ), unread as (
    select m.room_id,count(*) n from public.messages m join mine on mine.room_id=m.room_id
    where m.sender_id<>mine.person_id and m.read_at is null group by m.room_id
  )
  select mine.room_id,mine.booking_id,mine.other_person_id,mine.other_name,mine.worker_id,
    mine.service_name,mine.status::text,last.message,last.sent_at,coalesce(unread.n,0),
    mine.status in ('confirmed','in_progress') and mine.worker_stage in ('accepted','on_the_way','arrived','in_progress')
  from mine left join unread on unread.room_id=mine.room_id
  left join lateral(select m.message,m.sent_at from public.messages m where m.room_id=mine.room_id order by m.sent_at desc,m.message_id desc limit 1) last on true
  order by last.sent_at desc nulls last,mine.booking_id;
$$;

create or replace function public.chat_open_booking(p_booking_id uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare b public.bookings; result jsonb;
begin
  select * into b from public.bookings where booking_id=p_booking_id for share;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  insert into public.chat_rooms(booking_id) values(p_booking_id) on conflict(booking_id) do nothing;
  select to_jsonb(t) into result from public.chat_threads() t where t.booking_id=p_booking_id;
  if result is null then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  return result;
end $$;

create or replace function public.chat_send(p_room_id uuid,p_text text,p_client_message_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare me uuid:=public.current_person_id(); b public.bookings; existing public.messages; result uuid;
begin
  if me is null or not public.chat_is_member(p_room_id) then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  if p_client_message_id is null or p_text is null or length(btrim(p_text)) not between 1 and 4000 or octet_length(p_text)>16000 then raise exception 'CHAT_INVALID_MESSAGE' using errcode='22023';end if;
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id) where r.room_id=p_room_id for share of booked;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  select * into existing from public.messages where room_id=p_room_id and sender_id=me and client_message_id=p_client_message_id;
  if found then
    if existing.message<>btrim(p_text) then raise exception 'CHAT_RETRY_MISMATCH' using errcode='22023';end if;
    return existing.message_id;
  end if;
  if b.status not in ('confirmed','in_progress') or b.worker_stage not in ('accepted','on_the_way','arrived','in_progress') then raise exception 'CHAT_READ_ONLY' using errcode='42501';end if;
  insert into public.messages(room_id,sender_id,message,client_message_id)
    values(p_room_id,me,btrim(p_text),p_client_message_id)
    on conflict(room_id,sender_id,client_message_id) where client_message_id is not null do nothing returning message_id into result;
  if result is null then
    select * into existing from public.messages where room_id=p_room_id and sender_id=me and client_message_id=p_client_message_id;
    if existing.message<>btrim(p_text) then raise exception 'CHAT_RETRY_MISMATCH' using errcode='22023';end if;
    result:=existing.message_id;
  end if;
  update public.chat_typing set expires_at=clock_timestamp(),updated_at=clock_timestamp() where room_id=p_room_id and person_id=me;
  return result;
end $$;

create or replace function public.chat_mark_read(p_room_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare b public.bookings;
begin
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id) where r.room_id=p_room_id for share of booked;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  update public.messages set read_at=clock_timestamp()
    where room_id=p_room_id and sender_id<>public.current_person_id() and read_at is null;
end $$;
create or replace function public.chat_set_typing(p_room_id uuid,p_typing boolean)
returns void language plpgsql security definer set search_path='' as $$
declare me uuid:=public.current_person_id(); active boolean; b public.bookings;
begin
  if me is null or not public.chat_is_member(p_room_id) then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id) where r.room_id=p_room_id for share of booked;
  if not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  active:=b.status in ('confirmed','in_progress') and b.worker_stage in ('accepted','on_the_way','arrived','in_progress');
  if p_typing is true and not active then raise exception 'CHAT_READ_ONLY' using errcode='42501';end if;
  insert into public.chat_typing(room_id,person_id,expires_at,updated_at)
    values(p_room_id,me,clock_timestamp()+case when p_typing is true then interval '8 seconds' else interval '0 seconds' end,clock_timestamp())
  on conflict(room_id,person_id) do update set expires_at=excluded.expires_at,updated_at=excluded.updated_at
    where p_typing is not true or public.chat_typing.updated_at<clock_timestamp()-interval '2 seconds';
end $$;
create or replace function public.clear_finished_booking_typing()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  if new.status in ('completed','cancelled') and new.status is distinct from old.status then
    update public.chat_typing set expires_at=clock_timestamp(),updated_at=clock_timestamp()
      where room_id in(select room_id from public.chat_rooms where booking_id=new.booking_id);
  end if;return new;
end $$;
drop trigger if exists bookings_clear_typing on public.bookings;
create trigger bookings_clear_typing after update of status on public.bookings for each row execute function public.clear_finished_booking_typing();

create or replace function public.my_worker_reviews()
returns table(review_id uuid,booking_id uuid,customer_name text,service_name text,rating integer,review text,created_at timestamptz)
language sql stable security definer set search_path='' as $$
  select r.review_id,r.booking_id,p.full_name,s.service_name,r.rating,r.review,r.created_at
    from public.reviews r join public.bookings b using(booking_id) join public.customers c on c.customer_id=r.customer_id
    join public.persons p on p.person_id=c.person_id join public.services s using(service_id)
    where r.worker_id=public.current_worker_id() order by r.created_at desc,r.review_id;
$$;
create or replace function public.mark_my_notifications_read(p_notification_id uuid default null)
returns void language plpgsql security definer set search_path='' as $$
begin
  if public.current_person_id() is null then raise exception 'AUTH_REQUIRED' using errcode='42501';end if;
  update public.notifications set is_read=true where person_id=public.current_person_id()
    and (p_notification_id is null or notification_id=p_notification_id) and not is_read;
end $$;
-- Marking an alert read never permits rewriting its owner or contents.
revoke update on public.notifications from public,anon,authenticated;
grant update(is_read) on public.notifications to anon,authenticated;

-- Preserve existing booking notification semantics, now with an explicit route.
create or replace function public.notify_worker_about_booking()
returns trigger language plpgsql security definer set search_path='' as $$
declare who uuid; service text; heading text;
begin
  if new.worker_id is null then return new;end if;
  if tg_op='UPDATE' and new.status is not distinct from old.status and new.worker_id is not distinct from old.worker_id and new.worker_stage is not distinct from old.worker_stage then return new;end if;
  heading:=case when tg_op='INSERT' or new.worker_id is distinct from old.worker_id then 'New job request'
    when new.status='cancelled' then 'Booking cancelled' when new.status='completed' then 'Job completed'
    when new.worker_stage='accepted' then 'Job accepted' when new.worker_stage='on_the_way' then 'On the way'
    when new.worker_stage='arrived' then 'Arrival confirmed' when new.worker_stage='in_progress' then 'Job started' else null end;
  if heading is null then return new;end if;
  select person_id into who from public.workers where worker_id=new.worker_id;
  select service_name into service from public.services where service_id=new.service_id;
  insert into public.notifications(person_id,title,message,type,booking_id)
    values(who,heading,coalesce(service,'A service')||' on '||to_char(new.booking_date,'DD Mon')||', '||to_char(new.booking_time,'HH12:MI AM')||case when new.payment_mode='cash' then ' · cash' else '' end,
      case when heading='New job request' then 'request' else 'job' end,new.booking_id);
  return new;
end $$;

revoke all on function public.chat_is_member(uuid),public.chat_threads(),public.chat_open_booking(uuid),public.chat_send(uuid,text,uuid),public.chat_mark_read(uuid),public.chat_set_typing(uuid,boolean),public.my_worker_reviews(),public.mark_my_notifications_read(uuid) from public;
grant execute on function public.chat_is_member(uuid),public.chat_threads(),public.chat_open_booking(uuid),public.chat_send(uuid,text,uuid),public.chat_mark_read(uuid),public.chat_set_typing(uuid,boolean),public.my_worker_reviews(),public.mark_my_notifications_read(uuid) to anon,authenticated;
-- Realtime postgres_changes sends rows only after evaluating table SELECT RLS.
do $$ declare t text;begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach t in array array['chat_rooms','messages','chat_typing','bookings','notifications','reviews'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
        execute format('alter publication supabase_realtime add table public.%I',t);
      end if;
    end loop;
  end if;
end $$;

-- Preferences are enforced at creation for live alerts as well as in each UI.
create table if not exists public.partner_notification_preferences (
  person_id uuid primary key references public.persons(person_id) on delete cascade,
  requests boolean not null default true, jobs boolean not null default true,
  payouts boolean not null default true, updated_at timestamptz not null default now()
);
alter table public.partner_notification_preferences enable row level security;
revoke all on public.partner_notification_preferences from public,anon,authenticated;
grant all on public.partner_notification_preferences to service_role;
create or replace function public.set_partner_notification_preferences(p_requests boolean,p_jobs boolean,p_payouts boolean)
returns void language plpgsql security definer set search_path='' as $$
begin
  if public.current_worker_id() is null or public.current_person_id() is null then raise exception 'WORKER_ACCESS_REQUIRED' using errcode='42501';end if;
  if p_requests is null or p_jobs is null or p_payouts is null then raise exception 'INVALID_PREFERENCES' using errcode='22023';end if;
  insert into public.partner_notification_preferences(person_id,requests,jobs,payouts)
    values(public.current_person_id(),p_requests,p_jobs,p_payouts)
    on conflict(person_id) do update set requests=excluded.requests,jobs=excluded.jobs,payouts=excluded.payouts,updated_at=now();
end $$;
revoke all on function public.set_partner_notification_preferences(boolean,boolean,boolean) from public;
grant execute on function public.set_partner_notification_preferences(boolean,boolean,boolean) to anon,authenticated;
create or replace function public.filter_partner_notification_preferences()
returns trigger language plpgsql security definer set search_path='' as $$
declare pref public.partner_notification_preferences;
begin
  select * into pref from public.partner_notification_preferences where person_id=new.person_id;
  if found and ((new.type='request' and not pref.requests) or (new.type in ('job','booking') and not pref.jobs) or (new.type='payout' and not pref.payouts)) then return null;end if;
  return new;
end $$;
drop trigger if exists notifications_partner_preferences on public.notifications;
create trigger notifications_partner_preferences before insert on public.notifications for each row execute function public.filter_partner_notification_preferences();
drop trigger if exists bookings_notify_worker on public.bookings;
create trigger bookings_notify_worker after insert or update of status,worker_id,worker_stage on public.bookings for each row execute function public.notify_worker_about_booking();

create or replace function public.notify_partner_payment()
returns trigger language plpgsql security definer set search_path='' as $$
declare who uuid;
begin
  if new.payment_status<>'success' or (tg_op='UPDATE' and old.payment_status='success') then return new;end if;
  select w.person_id into who from public.bookings b join public.workers w using(worker_id) where b.booking_id=new.booking_id;
  if who is not null then
    insert into public.notifications(person_id,title,message,type,booking_id) values(who,
      case when new.payment_method='cash' then 'Cash collected' else 'Payment received' end,
      'Payment recorded for your booking.','payout',new.booking_id);
  end if;return new;
end $$;
drop trigger if exists payments_notify_partner on public.payments;
create trigger payments_notify_partner after insert or update of payment_status on public.payments for each row execute function public.notify_partner_payment();
create or replace function public.notify_partner_settlement()
returns trigger language plpgsql security definer set search_path='' as $$
begin
  insert into public.notifications(person_id,title,message,type)
    select person_id,'Settlement recorded','Your cash settlement has been recorded.','payout' from public.workers where worker_id=new.worker_id;
  return new;
end $$;
drop trigger if exists settlements_notify_partner on public.settlements;
create trigger settlements_notify_partner after insert on public.settlements for each row execute function public.notify_partner_settlement();

-- Private channel authorization only permits the caller's own channel topics.
-- Actual postgres_changes row delivery is independently checked by table RLS.
do $$ begin
  if to_regclass('realtime.messages') is not null then
    execute 'drop policy if exists "kaylo private chat channel" on realtime.messages';
    execute $policy$create policy "kaylo private chat channel" on realtime.messages for select to anon,authenticated
      using (realtime.topic() like 'kaylo-chat:%' and split_part(realtime.topic(),':',2)=public.current_person_id()::text)$policy$;
  end if;
end $$;


-- A worker can navigate an alert/chat back to the real assigned booking.
create or replace function public.my_partner_jobs()
returns table(booking_id uuid,service_name text,service_icon text,customer_name text,customer_phone text,
  address text,latitude double precision,longitude double precision,scheduled_at timestamptz,
  payout numeric,customer_price numeric,payment_mode text,notes text,status text,booking_status text)
language sql stable security definer set search_path='' as $$
  select b.booking_id,s.service_name,s.icon_path,p.full_name,p.phone_number,
    concat_ws(', ',nullif(l.house_name,''),nullif(l.street,''),nullif(l.district,''),nullif(l.pincode,'')),
    l.latitude,l.longitude,(b.booking_date+b.booking_time) at time zone 'Asia/Kolkata',
    round(coalesce(b.final_cost,b.estimated_cost,0)*(1-public.kaylo_commission_rate()),2),
    coalesce(b.final_cost,b.estimated_cost,0),b.payment_mode,b.notes,b.worker_stage,b.status::text
  from public.bookings b join public.services s using(service_id) join public.customers c using(customer_id)
    join public.persons p on p.person_id=c.person_id left join public.locations l using(location_id)
  where b.worker_id=public.current_worker_id() order by b.booking_date desc,b.booking_time desc,b.booking_id;
$$;
revoke all on function public.my_partner_jobs() from public;
grant execute on function public.my_partner_jobs() to anon,authenticated;

notify pgrst,'reload schema';
commit;
