-- Trusted contacts and in-app SOS group calls.
-- Safe to run more than once.
begin;
create table if not exists care_invite_codes (
  owner_id uuid primary key references persons(person_id) on delete cascade,
  code text not null unique default replace(gen_random_uuid()::text,'-',''),
  expires_at timestamptz not null default now()+interval '7 days'
);
create table if not exists care_connections (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references persons(person_id) on delete cascade,
  contact_id uuid not null references persons(person_id) on delete cascade,
  owner_name text not null, contact_name text not null,
  unique(owner_id,contact_id), check(owner_id<>contact_id)
);
create table if not exists care_calls (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references persons(person_id) on delete cascade,
  created_at timestamptz not null default now(), expires_at timestamptz not null default now()+interval '30 minutes', ended_at timestamptz
);
create table if not exists care_call_members (
  call_id uuid not null references care_calls(id) on delete cascade,
  person_id uuid not null references persons(person_id) on delete cascade,
  name text not null, status text not null default 'invited' check(status in ('invited','joined','declined','left')),
  primary key(call_id,person_id)
);
create table if not exists care_call_signals (
  id bigint generated always as identity primary key,
  call_id uuid not null references care_calls(id) on delete cascade,
  sender_id uuid not null references persons(person_id) on delete cascade,
  target_id uuid not null references persons(person_id) on delete cascade,
  payload jsonb not null check(octet_length(payload::text)<65536),
  created_at timestamptz not null default now()
);
create index if not exists care_call_signals_recipient on care_call_signals(call_id,target_id,id);
create or replace function is_care_call_member(cid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from care_call_members where call_id=cid and person_id=current_person_id());
$$;
create or replace function active_care_call_member(cid uuid,pid uuid) returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from care_call_members m join care_calls c on c.id=m.call_id where m.call_id=cid and m.person_id=pid and m.status='joined' and c.ended_at is null and c.expires_at>now());
$$;
alter table care_invite_codes enable row level security;
alter table care_connections enable row level security;
alter table care_calls enable row level security;
alter table care_call_members enable row level security;
alter table care_call_signals enable row level security;
-- Created only when missing, so a second run keeps the roles 0014 widened.
do $$ begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_invite_codes' and policyname='own_invite') then
    create policy own_invite on care_invite_codes for select to authenticated using(owner_id=current_person_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_connections' and policyname='own_connection') then
    create policy own_connection on care_connections for select to authenticated using(owner_id=current_person_id() or contact_id=current_person_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_connections' and policyname='remove_connection') then
    create policy remove_connection on care_connections for delete to authenticated using(owner_id=current_person_id() or contact_id=current_person_id());
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_calls' and policyname='member_calls') then
    create policy member_calls on care_calls for select to authenticated using(is_care_call_member(id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_call_members' and policyname='member_list') then
    create policy member_list on care_call_members for select to authenticated using(is_care_call_member(call_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_call_signals' and policyname='read_call_signal') then
    create policy read_call_signal on care_call_signals for select to authenticated using(target_id=current_person_id() and is_care_call_member(call_id));
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='care_call_signals' and policyname='send_call_signal') then
    create policy send_call_signal on care_call_signals for insert to authenticated with check(sender_id=current_person_id() and active_care_call_member(call_id,sender_id) and active_care_call_member(call_id,target_id));
  end if;
end $$;

create or replace function care_invite_code() returns text language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); result text;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 insert into care_invite_codes(owner_id) values(pid) on conflict(owner_id) do update set code=case when care_invite_codes.expires_at<now() then replace(gen_random_uuid()::text,'-','') else care_invite_codes.code end, expires_at=now()+interval '7 days' returning code into result;
 return result;
end $$;
create or replace function accept_care_invite(p_code text) returns void language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); owner uuid;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 select owner_id into owner from care_invite_codes where code=lower(trim(p_code)) and expires_at>now();
 if owner is null or owner=pid then raise exception 'This invite is invalid or belongs to you'; end if;
 perform 1 from persons where person_id=owner for update;
 if (select count(*) from care_connections where owner_id=owner)>=5 then raise exception 'This person already has five trusted contacts'; end if;
 insert into care_connections(owner_id,contact_id,owner_name,contact_name)
 select owner,pid,(select full_name from persons where person_id=owner),(select full_name from persons where person_id=pid)
 on conflict(owner_id,contact_id) do nothing;
end $$;
create or replace function start_care_call() returns uuid language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); cid uuid;
begin
 if pid is null then raise exception 'Sign in first'; end if;
 perform 1 from persons where person_id=pid for update;
 if not exists(select 1 from care_connections where owner_id=pid) then raise exception 'Add trusted contacts in Kaylo Care first'; end if;
 select id into cid from care_calls where owner_id=pid and ended_at is null and expires_at>now() order by created_at desc limit 1;
 if cid is not null then return cid; end if;
 insert into care_calls(owner_id) values(pid) returning id into cid;
 insert into care_call_members(call_id,person_id,name,status) select cid,pid,full_name,'joined' from persons where person_id=pid;
 insert into care_call_members(call_id,person_id,name) select cid,contact_id,contact_name from care_connections where owner_id=pid;
 delete from care_call_signals where created_at<now()-interval '1 day';
 return cid;
end $$;
create or replace function respond_care_call(p_call_id uuid,p_action text) returns void language plpgsql security definer set search_path=public as $$
declare pid uuid:=current_person_id(); owner uuid;
begin
 select owner_id into owner from care_calls where id=p_call_id and ended_at is null and expires_at>now();
 if owner is null or not is_care_call_member(p_call_id) then raise exception 'This call has ended'; end if;
 if p_action='end' and pid=owner then
   update care_calls set ended_at=now() where id=p_call_id;
   update care_call_members set status='left' where call_id=p_call_id and status in ('invited','joined');
 elsif p_action in ('joined','declined','left') then
   update care_call_members set status=p_action where call_id=p_call_id and person_id=pid;
 else raise exception 'Invalid call response'; end if;
end $$;
revoke all on function care_invite_code(),accept_care_invite(text),start_care_call(),respond_care_call(uuid,text) from public;
grant execute on function care_invite_code(),accept_care_invite(text),start_care_call(),respond_care_call(uuid,text) to authenticated;
commit;
