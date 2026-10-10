-- Kaylo-issued partner identities, admin review and strict role separation.
-- Run after 0024. Safe to rerun. No password or password hash is stored here.
begin;
create sequence if not exists kaylo_partner_id_seq maxvalue 999999;
alter table workers add column if not exists partner_id text unique;
alter table workers add column if not exists must_change_password boolean not null default true;
alter table workers drop constraint if exists workers_partner_id_format;
alter table workers add constraint workers_partner_id_format check (partner_id is null or partner_id ~ '^KP-[0-9]{6}$');
create table if not exists partner_credentials (
  worker_id uuid primary key references workers(worker_id) on delete cascade,
  issuance_id uuid not null,
  firebase_uid text not null unique,
  state text not null check(state in ('issuing','ready','delivered','failed')),
  lock_expires_at timestamptz,
  password_updated_at_ms numeric,
  issued_at timestamptz,
  delivered_at timestamptz
);
alter table partner_credentials enable row level security;
revoke all on partner_credentials from public,anon,authenticated;
grant all on partner_credentials to service_role;
insert into roles(role_name) values ('worker'),('customer') on conflict(role_name) do nothing;
-- Preserve legacy marketplace profiles and booking history. Conflicting old
-- identities are quarantined, never silently deleted or given dual access.
update persons p set account_status='suspended' where exists(select 1 from workers w where w.person_id=p.person_id)
  and exists(select 1 from customers c where c.person_id=p.person_id) and p.account_status='active';
insert into person_roles(person_id,role_id)
  select w.person_id,r.role_id from workers w cross join roles r where r.role_name='worker'
    and not exists(select 1 from customers c where c.person_id=w.person_id)
    and not exists(select 1 from person_roles pr where pr.person_id=w.person_id and pr.role_id=r.role_id)
  on conflict(person_id,role_id) do nothing;
insert into person_roles(person_id,role_id)
  select c.person_id,r.role_id from customers c cross join roles r where r.role_name='customer'
    and not exists(select 1 from workers w where w.person_id=c.person_id)
    and not exists(select 1 from person_roles pr where pr.person_id=c.person_id and pr.role_id=r.role_id)
  on conflict(person_id,role_id) do nothing;

create or replace function enforce_single_person_role()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_person uuid := new.person_id; v_role text;
begin
  perform 1 from persons where person_id=v_person for update;
  if tg_table_name='person_roles' then select role_name into v_role from roles where role_id=new.role_id;
  elsif tg_table_name='customers' then v_role:='customer'; else v_role:='worker'; end if;
  if v_role='customer' and (exists(select 1 from workers where person_id=v_person) or exists(
    select 1 from person_roles pr join roles r using(role_id) where pr.person_id=v_person and r.role_name='worker')) then
    raise exception 'PARTNER_ACCOUNT_NOT_ALLOWED'; end if;
  if v_role='worker' and (exists(select 1 from customers where person_id=v_person) or exists(
    select 1 from person_roles pr join roles r using(role_id) where pr.person_id=v_person and r.role_name='customer')) then
    raise exception 'CUSTOMER_ACCOUNT_NOT_ALLOWED'; end if;
  return new;
end $$;
drop trigger if exists customers_single_role on customers;
create trigger customers_single_role before insert or update of person_id on customers for each row execute function enforce_single_person_role();
drop trigger if exists workers_single_role on workers;
create trigger workers_single_role before insert or update of person_id on workers for each row execute function enforce_single_person_role();
drop trigger if exists person_roles_single_role on person_roles;
create trigger person_roles_single_role before insert or update on person_roles for each row execute function enforce_single_person_role();

create or replace function caller_is_partner_identity()
returns boolean language sql stable as $$
  select coalesce(auth.jwt()->>'kaylo_role'='worker',false)
    or lower(coalesce(auth.jwt()->>'email','')) like '%@partners.kaylo.app';
$$;
create or replace function issued_partner_session(p_worker uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from workers w join persons p using(person_id) join partner_credentials c using(worker_id)
    where w.worker_id=p_worker and p.auth_user_id=current_auth_subject() and p.account_status='active'
      and w.partner_id=auth.jwt()->>'kaylo_partner_id' and auth.jwt()->>'kaylo_role'='worker'
      and auth.jwt()->'firebase'->>'sign_in_provider'='password'
      and c.issuance_id::text=auth.jwt()->>'kaylo_issuance_id'
      and coalesce((auth.jwt()->>'auth_time')::numeric,0)>=floor(c.password_updated_at_ms/1000)
      and c.firebase_uid=p.auth_user_id and c.state in ('ready','delivered') and c.issued_at is not null);
$$;
create or replace function current_worker_id()
returns uuid language sql stable security definer set search_path=public as $$
  select w.worker_id from workers w join persons p using(person_id)
    where p.auth_user_id=current_auth_subject() and issued_partner_session(w.worker_id)
      and not w.must_change_password and w.verification_status='verified';
$$;
create or replace function current_person_id()
returns uuid language sql stable security definer set search_path=public as $$
  select p.person_id from persons p where p.auth_user_id=current_auth_subject() and p.account_status='active'
    and case when exists(select 1 from workers w where w.person_id=p.person_id)
      then exists(select 1 from workers w where w.person_id=p.person_id and w.worker_id=current_worker_id())
      else not caller_is_partner_identity() end;
$$;
create or replace function current_customer_id()
returns uuid language sql stable security definer set search_path=public as $$
  select c.customer_id from customers c where c.person_id=current_person_id()
    and not exists(select 1 from person_roles pr join roles r using(role_id) where pr.person_id=c.person_id and r.role_name='worker');
$$;
-- Closed legacy paths: account creation only goes through reviewed applications.
revoke all on function register_worker(jsonb) from public,anon,authenticated;
drop policy if exists "workers create self" on workers;
drop policy if exists "workers update self" on workers;
revoke insert,update,delete on workers from public,anon,authenticated;
revoke insert,update,delete on worker_services from public,anon,authenticated;
-- A customer must not create a reserved identity before an admin links it.
drop policy if exists "self insert" on persons;
create policy "self insert" on persons for insert to anon,authenticated
  with check(auth_user_id=current_auth_subject() and not caller_is_partner_identity()
    and lower(coalesce(email,'')) not like '%@partners.kaylo.app' and account_status='active');
revoke update on persons from public,anon,authenticated;
grant update(full_name,phone_number,email,profile_photo,date_of_birth,gender,language,updated_at) on persons to anon,authenticated;
revoke insert,update,delete on person_roles from public,anon,authenticated;

create or replace function ensure_customer_profile()
returns void language plpgsql security definer set search_path=public as $$
declare me uuid;
begin
  select person_id into me from persons where auth_user_id=current_auth_subject() for update;
  if caller_is_partner_identity() or exists(select 1 from workers where person_id=me)
    or exists(select 1 from person_roles pr join roles r using(role_id) where pr.person_id=me and r.role_name='worker') then
    raise exception 'PARTNER_ACCOUNT_NOT_ALLOWED'; end if;
  if me is null or me is distinct from current_person_id() then raise exception 'SIGN_IN_REQUIRED'; end if;
  insert into person_roles(person_id,role_id) select me,role_id from roles where role_name='customer'
    on conflict(person_id,role_id) do nothing;
  insert into customers(person_id) values(me) on conflict(person_id) do nothing;
end $$;
revoke all on function ensure_customer_profile() from public;
grant execute on function ensure_customer_profile() to anon,authenticated;

create or replace function partner_login_state()
returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object('partner_id',w.partner_id,'person_id',p.person_id,'worker_id',w.worker_id,
    'must_change_password',w.must_change_password,'verification_status',w.verification_status)
  from workers w join persons p using(person_id) where p.auth_user_id=current_auth_subject()
    and issued_partner_session(w.worker_id);
$$;
revoke all on function partner_login_state() from public;
grant execute on function partner_login_state() to anon,authenticated;

create or replace function approve_worker_application(p_application_id uuid,p_note text default null)
returns uuid language plpgsql security definer set search_path=public as $$
declare a worker_applications; pid uuid; wid uuid; svc text;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found then raise exception 'APPLICATION_NOT_FOUND'; end if;
  if a.status not in ('submitted','under_review') then raise exception 'APPLICATION_ALREADY_REVIEWED'; end if;
  if (select count(*) from worker_application_documents d join storage.objects o
    on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=p_application_id)<>5 then
    raise exception 'ALL_DOCUMENTS_REQUIRED'; end if;
  if exists(select 1 from persons where canonical_partner_phone(phone_number)=a.phone
      or lower(email)=lower(a.details->>'email')) then raise exception 'IDENTITY_ALREADY_IN_USE'; end if;
  insert into persons(full_name,phone_number,email,profile_photo)
    values(trim(a.details->>'full_name'),a.phone,lower(a.details->>'email'),
      (select storage_path from worker_application_documents where application_id=p_application_id and doc_type='photo')) returning person_id into pid;
  insert into workers(person_id,experience_years,travel_radius_km,bio,verification_status,is_available,partner_id)
    values(pid,(a.details->>'experience_years')::int,(a.details->>'travel_radius_km')::numeric,
      a.details->>'profession','verified',false,'KP-'||lpad(nextval('kaylo_partner_id_seq')::text,6,'0')) returning worker_id into wid;
  insert into person_roles(person_id,role_id) select pid,role_id from roles where role_name='worker';
  for svc in select jsonb_array_elements_text(a.details->'services') loop
    insert into worker_services(worker_id,service_id,experience_years)
      values(wid,svc::uuid,(a.details->>'experience_years')::int) on conflict(worker_id,service_id) do nothing;
  end loop;
  insert into locations(person_id,district,is_default,nickname) values(pid,a.details->>'district',true,'Work area');
  insert into worker_payout_accounts(worker_id,upi_id,bank_account)
    values(wid,nullif(a.details->>'upi_id',''),case when a.details ? 'bank_account' then (a.details->'bank_account')::text end);
  -- Calling approval is the admin's explicit attestation that all five supplied
  -- documents were reviewed. Record that decision, not invented check methods.
  insert into worker_documents(worker_id,doc_type,storage_path,status,note,reviewed_at)
    select wid,doc_type,storage_path,'verified',
      coalesce(nullif(trim(p_note),''),'Application documents reviewed by Kaylo.'),now()
    from worker_application_documents where application_id=p_application_id;
  update worker_applications set status='approved',worker_id=wid,reviewed_at=now(),review_note=p_note,
    upload_expires_at=now() where application_id=p_application_id;
  return wid;
end $$;
create or replace function reject_worker_application(p_application_id uuid,p_note text default null)
returns void language plpgsql security definer set search_path=public as $$
begin
  perform 1 from worker_applications where application_id=p_application_id for update;
  update worker_applications set status='rejected',reviewed_at=now(),review_note=p_note,upload_expires_at=now()
    where application_id=p_application_id and status in ('submitted','under_review');
  if not found then raise exception 'APPLICATION_ALREADY_REVIEWED'; end if;
end $$;
revoke all on function approve_worker_application(uuid,text),reject_worker_application(uuid,text) from public,anon,authenticated;
grant execute on function approve_worker_application(uuid,text),reject_worker_application(uuid,text) to service_role;

-- One issuance lease at a time, including support resets. The worker loses
-- private access before Firebase is touched. Retries after a failure rotate
-- the password again; no plaintext credential is persisted for retries.
create or replace function begin_partner_credential_issue(p_worker_id uuid,p_reset boolean default false)
returns jsonb language plpgsql security definer set search_path=public as $$
declare w workers; p persons; c partner_credentials; op uuid:=gen_random_uuid(); uid text;
begin
  select * into w from workers where worker_id=p_worker_id for update;
  if not found or w.verification_status<>'verified' or not exists(select 1 from worker_applications
    where worker_id=p_worker_id and status='approved') then raise exception 'APPROVED_APPLICATION_REQUIRED'; end if;
  select * into p from persons where person_id=w.person_id;
  if p.account_status<>'active' then raise exception 'ACCOUNT_NOT_ACTIVE'; end if;
  select * into c from partner_credentials where worker_id=p_worker_id;
  if c.state in ('issuing','ready') and c.lock_expires_at>now() then raise exception 'ISSUANCE_IN_PROGRESS'; end if;
  if c.state='delivered' and not p_reset then
    return jsonb_build_object('already_issued',true,'partner_id',w.partner_id); end if;
  uid:='kaylo_partner_'||replace(p_worker_id::text,'-','');
  if p.auth_user_id is not null and p.auth_user_id<>uid then raise exception 'IDENTITY_ALREADY_LINKED'; end if;
  update workers set must_change_password=true,is_available=false where worker_id=p_worker_id;
  insert into partner_credentials(worker_id,issuance_id,firebase_uid,state,lock_expires_at)
    values(p_worker_id,op,uid,'issuing',now()+interval '10 minutes')
    on conflict(worker_id) do update set issuance_id=op,state='issuing',password_updated_at_ms=null,
      issued_at=null,delivered_at=null,lock_expires_at=excluded.lock_expires_at;
  return jsonb_build_object('issuance_id',op,'worker_id',w.worker_id,'firebase_uid',uid,
    'partner_id',w.partner_id,'email',p.email,'phone',p.phone_number,'name',p.full_name);
end $$;
create or replace function finish_partner_credential_issue(p_worker_id uuid,p_issuance_id uuid,p_password_updated_at_ms numeric)
returns void language plpgsql security definer set search_path=public as $$
declare c partner_credentials;
begin
  select * into c from partner_credentials where worker_id=p_worker_id for update;
  if not found or c.issuance_id<>p_issuance_id or c.state<>'issuing' or c.lock_expires_at<now()
    or p_password_updated_at_ms is null or p_password_updated_at_ms<=0 then raise exception 'INVALID_ISSUANCE'; end if;
  update persons set auth_user_id=c.firebase_uid where person_id=(select person_id from workers where worker_id=p_worker_id);
  update partner_credentials set state='ready',issued_at=now(),password_updated_at_ms=p_password_updated_at_ms
    where worker_id=p_worker_id;
end $$;
create or replace function mark_password_changed(p_worker_id uuid,p_issuance_id uuid,p_password_updated_at_ms numeric)
returns void language plpgsql security definer set search_path=public as $$
declare c partner_credentials;
begin
  select * into c from partner_credentials where worker_id=p_worker_id for update;
  if not found or c.issuance_id<>p_issuance_id or c.state not in ('ready','delivered')
    or c.password_updated_at_ms is null or p_password_updated_at_ms is null
    or p_password_updated_at_ms<=c.password_updated_at_ms then raise exception 'PASSWORD_CHANGE_NOT_VERIFIED'; end if;
  update workers set must_change_password=false where worker_id=p_worker_id;
end $$;
revoke all on function begin_partner_credential_issue(uuid,boolean),finish_partner_credential_issue(uuid,uuid,numeric),
  mark_password_changed(uuid,uuid,numeric) from public,anon,authenticated;
grant execute on function begin_partner_credential_issue(uuid,boolean),finish_partner_credential_issue(uuid,uuid,numeric),
  mark_password_changed(uuid,uuid,numeric) to service_role;

-- Application evidence stays admin-managed after approval. The old worker
-- upload path can no longer replace the supplied identity documents.
drop policy if exists "submit own documents" on worker_documents;
drop policy if exists "replace own pending documents" on worker_documents;
revoke insert,update,delete on worker_documents from anon,authenticated;
drop policy if exists "workers upload own documents" on storage.objects;
drop policy if exists "workers replace own documents" on storage.objects;
-- Approved workers may read their application evidence, with their current issued session.
drop policy if exists "workers read application documents" on storage.objects;
create policy "workers read application documents" on storage.objects for select to anon,authenticated
  using(bucket_id='worker-documents' and exists(select 1 from worker_documents d
    where d.worker_id=current_worker_id() and d.storage_path=name));

-- Preserve deletion retries without letting a gated session delete Firebase alone.
create or replace function delete_current_kaylo_account()
returns text language plpgsql security definer set search_path=public as $$
declare uid text:=current_auth_subject(); pid uuid:=current_person_id();
begin
  if uid is null then raise exception 'Sign in first'; end if;
  -- A password/review gate returning NULL is not evidence the person was deleted.
  if pid is null and (exists(select 1 from persons where auth_user_id=uid)
    or not exists(select 1 from account_deletion_requests where auth_subject=uid)) then
    raise exception 'ACCOUNT_ACCESS_REQUIRED'; end if;
  if coalesce((auth.jwt()->>'auth_time')::bigint,0) < extract(epoch from now()-interval '30 minutes') then
    raise exception 'Please sign out and sign in again before deleting your account';
  end if;
  if exists(select 1 from bookings b where (b.customer_id=current_customer_id() or b.worker_id=current_worker_id()) and (b.status in ('confirmed','in_progress') or (b.status='pending' and exists(select 1 from payments p where p.booking_id=b.booking_id and p.payment_status='success')))) then
    raise exception 'Complete or cancel active bookings before deleting your account. Contact kayloapp@gmail.com for unresolved payments.';
  end if;
  insert into account_deletion_requests(auth_subject) values(uid) on conflict do nothing;
  delete from email_otps where email in (select email from persons where person_id=pid);
  delete from persons where person_id=pid;
  return uid;
end $$;

notify pgrst, 'reload schema';
commit;
