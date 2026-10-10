-- Kaylo admin review, correction history, certificates and durable email delivery.
-- Run after 0026. Safe to rerun. All admin operations require an active actor.
begin;

create table if not exists admin_users (
  firebase_uid text primary key check(length(firebase_uid) between 1 and 128),
  email text not null,
  role text not null check(role in ('reviewer','admin')),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
-- The name is intentionally explicit in SQL and matches the edge admin registry.
alter table worker_applications add column if not exists version integer not null default 1 check(version>0);
alter table worker_applications add column if not exists correction_version integer;
alter table worker_applications add column if not exists correction_expires_at timestamptz;
alter table worker_applications drop constraint if exists worker_applications_status_check;
alter table worker_applications add constraint worker_applications_status_check
  check(status in ('submitted','under_review','changes_requested','approved','rejected'));
drop index if exists worker_applications_open_phone;
create unique index worker_applications_open_phone on worker_applications(phone)
  where status in ('submitted','under_review','changes_requested','approved');
create index if not exists worker_applications_review_queue on worker_applications(status,submitted_at desc);

create table if not exists worker_application_audit (
  event_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references worker_applications(application_id),
  application_version integer not null,
  action text not null,
  actor_uid text,
  actor_email text,
  actor_role text,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index if not exists worker_application_audit_timeline on worker_application_audit(application_id,created_at,event_id);
create table if not exists worker_application_corrections (
  application_id uuid not null references worker_applications(application_id),
  request_version integer not null,
  doc_type text not null check(doc_type in ('photo','aadhaar_front','aadhaar_back','police_certificate','selfie')),
  note text not null,
  requested_at timestamptz not null default now(),
  requested_by text not null,
  received_at timestamptz,
  storage_path text,
  primary key(application_id,request_version,doc_type)
);
create table if not exists worker_application_document_history (
  history_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references worker_applications(application_id),
  application_version integer not null,
  doc_type text not null,
  storage_path text not null,
  content_type text not null,
  byte_size integer not null,
  uploaded_at timestamptz not null,
  recorded_at timestamptz not null default now(),
  unique(application_id,doc_type,storage_path)
);
create index if not exists worker_application_document_history_lookup
  on worker_application_document_history(application_id,doc_type,recorded_at);
create table if not exists partner_certificates (
  certificate_id uuid primary key default gen_random_uuid(),
  certificate_number text not null unique default ('KC-'||to_char(now(),'YYYY')||'-'||upper(encode(gen_random_bytes(6),'hex'))),
  application_id uuid not null unique references worker_applications(application_id),
  worker_id uuid not null unique references workers(worker_id),
  application_version integer not null,
  issued_at timestamptz not null default now(),
  issued_by text not null,
  checked_document_types text[] not null,
  snapshot jsonb not null
);
create table if not exists application_mail_outbox (
  mail_id uuid primary key default gen_random_uuid(),
  application_id uuid not null references worker_applications(application_id),
  application_version integer not null,
  kind text not null check(kind in ('submitted','approved','rejected','changes_requested')),
  recipient_email text not null,
  template_data jsonb not null,
  status text not null default 'pending' check(status in ('pending','sending','sent','failed')),
  attempts integer not null default 0,
  last_error text,
  claim_id uuid,
  lease_until timestamptz,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  unique(application_id,application_version,kind)
);
create index if not exists application_mail_outbox_delivery on application_mail_outbox(status,created_at);
create index if not exists application_mail_outbox_application on application_mail_outbox(application_id,created_at desc);

alter table admin_users enable row level security;
alter table worker_application_audit enable row level security;
alter table worker_application_corrections enable row level security;
alter table worker_application_document_history enable row level security;
alter table partner_certificates enable row level security;
alter table application_mail_outbox enable row level security;
revoke all on admin_users,worker_application_audit,worker_application_corrections,
  worker_application_document_history,partner_certificates,application_mail_outbox from public,anon,authenticated;
grant all on admin_users,worker_application_audit,worker_application_corrections,
  worker_application_document_history,partner_certificates,application_mail_outbox to service_role;

-- Service clients may append, but cannot rewrite or truncate immutable evidence.
revoke update,delete,truncate on worker_application_audit,worker_application_document_history,partner_certificates from service_role;

create or replace function require_application_admin(p_actor_uid text,p_write_decision boolean default false)
returns admin_users language plpgsql stable security definer set search_path=public as $$
declare actor admin_users;
begin
  select * into actor from admin_users where firebase_uid=p_actor_uid and is_active;
  if not found then raise exception 'ADMIN_ACCESS_REQUIRED'; end if;
  if p_write_decision and actor.role<>'admin' then raise exception 'ADMIN_DECISION_REQUIRED'; end if;
  return actor;
end $$;
revoke all on function require_application_admin(text,boolean) from public,anon,authenticated;
grant execute on function require_application_admin(text,boolean) to service_role;

create or replace function immutable_application_record()
returns trigger language plpgsql as $$
begin raise exception 'IMMUTABLE_APPLICATION_RECORD'; end $$;
drop trigger if exists worker_application_audit_immutable on worker_application_audit;
create trigger worker_application_audit_immutable before update or delete on worker_application_audit
  for each row execute function immutable_application_record();
drop trigger if exists worker_application_history_immutable on worker_application_document_history;
create trigger worker_application_history_immutable before update or delete on worker_application_document_history
  for each row execute function immutable_application_record();
drop trigger if exists partner_certificates_immutable on partner_certificates;
create trigger partner_certificates_immutable before update or delete on partner_certificates
  for each row execute function immutable_application_record();

-- Retain existing evidence before enabling history on subsequent replacements.
insert into worker_application_document_history(application_id,application_version,doc_type,storage_path,content_type,byte_size,uploaded_at)
  select d.application_id,a.version,d.doc_type,d.storage_path,d.content_type,d.byte_size,d.submitted_at
  from worker_application_documents d join worker_applications a using(application_id)
  on conflict(application_id,doc_type,storage_path) do nothing;
create or replace function audit_worker_application_document()
returns trigger language plpgsql security definer set search_path=public as $$
declare v integer;
begin
  if tg_op='UPDATE' and new.storage_path=old.storage_path and new.content_type=old.content_type and new.byte_size=old.byte_size then return new;end if;
  update worker_applications set version=version+1 where application_id=new.application_id returning version into v;
  insert into worker_application_document_history(application_id,application_version,doc_type,storage_path,content_type,byte_size,uploaded_at)
    values(new.application_id,v,new.doc_type,new.storage_path,new.content_type,new.byte_size,new.submitted_at)
    on conflict(application_id,doc_type,storage_path) do nothing;
  insert into worker_application_audit(application_id,application_version,action,data)
    values(new.application_id,v,case when tg_op='INSERT' then 'document_uploaded' else 'document_replaced' end,
      jsonb_build_object('doc_type',new.doc_type,'storage_path',new.storage_path,
        'previous_path',case when tg_op='UPDATE' then old.storage_path else null end));
  return new;
end $$;
drop trigger if exists worker_application_document_audit on worker_application_documents;
create trigger worker_application_document_audit after insert or update on worker_application_documents
  for each row execute function audit_worker_application_document();

create or replace function queue_application_mail(p_application_id uuid,p_version integer,p_kind text,p_recipient text,p_data jsonb)
returns uuid language plpgsql security definer set search_path=public as $$
declare id uuid;
begin
  insert into application_mail_outbox(application_id,application_version,kind,recipient_email,template_data)
    values(p_application_id,p_version,p_kind,p_recipient,p_data)
    on conflict(application_id,application_version,kind) do nothing;
  select mail_id into id from application_mail_outbox where application_id=p_application_id
    and application_version=p_version and kind=p_kind;
  return id;
end $$;
revoke all on function queue_application_mail(uuid,integer,text,text,jsonb) from public,anon,authenticated;
grant execute on function queue_application_mail(uuid,integer,text,text,jsonb) to service_role;

create or replace function queue_completed_application_review()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.status='under_review' and old.status is distinct from new.status
    and (select count(*) from worker_application_documents d join storage.objects o
      on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=new.application_id)=5 then
    perform queue_application_mail(new.application_id,new.version,'submitted','kayloapp@gmail.com',
      jsonb_build_object('reference',new.reference,'application_id',new.application_id,'version',new.version));
  end if;
  -- Migration 0026 compatibility: a completed old-sender acknowledgement must
  -- not cause the newer outbox to deliver the same initial alert again.
  if new.admin_notified_at is not null and old.admin_notified_at is distinct from new.admin_notified_at then
    update application_mail_outbox set status='sent',sent_at=new.admin_notified_at,claim_id=null,lease_until=null,last_error=null
      where mail_id=(select mail_id from application_mail_outbox where application_id=new.application_id
        and kind='submitted' order by application_version desc limit 1) and status<>'sent';
  end if;
  return new;
end $$;
drop trigger if exists worker_application_review_mail on worker_applications;
create trigger worker_application_review_mail after update of status,admin_notified_at on worker_applications
  for each row execute function queue_completed_application_review();

create or replace function get_application_for_correction(p_application_id uuid,p_version integer)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a worker_applications;
begin
  select * into a from worker_applications where application_id=p_application_id;
  if not found or a.correction_version is distinct from p_version then raise exception 'CORRECTION_LINK_INVALID';end if;
  if a.correction_expires_at is null or a.correction_expires_at<=now() then raise exception 'CORRECTION_LINK_EXPIRED';end if;
  return jsonb_build_object('application_id',a.application_id,'reference',a.reference,'version',a.correction_version,
    'correction_version',a.correction_version,'application_version',a.version,'status',a.status,
    'completed',a.status<>'changes_requested','expires_at',a.correction_expires_at,
    'requested_documents',coalesce((select jsonb_agg(jsonb_build_object('doc_type',c.doc_type,'note',c.note,
      'received',c.received_at is not null) order by c.doc_type) from worker_application_corrections c
      where c.application_id=a.application_id and c.request_version=p_version),'[]'::jsonb));
end $$;
revoke all on function get_application_for_correction(uuid,integer) from public,anon,authenticated;
grant execute on function get_application_for_correction(uuid,integer) to service_role;

create or replace function record_application_correction(p_application_id uuid,p_version integer,p_doc_type text,
  p_path text,p_content_type text,p_byte_size integer)
returns jsonb language plpgsql security definer set search_path=public as $$
declare a worker_applications; v integer;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found or a.status<>'changes_requested' or a.correction_version is distinct from p_version
    then raise exception 'CORRECTION_NOT_ALLOWED';end if;
  if a.correction_expires_at<=now() then raise exception 'CORRECTION_LINK_EXPIRED';end if;
  if not exists(select 1 from worker_application_corrections where application_id=p_application_id
    and request_version=p_version and doc_type=p_doc_type) then raise exception 'DOCUMENT_NOT_REQUESTED';end if;
  if p_path not like 'applications/'||p_application_id::text||'/corrections/'||p_version::text||'/'||p_doc_type||'/%'
    or p_path like '%..%' then raise exception 'INVALID_DOCUMENT_PATH';end if;
  if p_content_type not in ('image/jpeg','image/png','application/pdf') or p_byte_size not between 1 and 10485760
    or (p_doc_type in ('photo','selfie') and p_content_type='application/pdf') then raise exception 'INVALID_DOCUMENT';end if;
  if not exists(select 1 from storage.objects where bucket_id='worker-documents' and name=p_path) then raise exception 'DOCUMENT_NOT_UPLOADED';end if;
  insert into worker_application_documents(application_id,doc_type,storage_path,content_type,byte_size)
    values(p_application_id,p_doc_type,p_path,p_content_type,p_byte_size)
    on conflict(application_id,doc_type) do update set storage_path=excluded.storage_path,
      content_type=excluded.content_type,byte_size=excluded.byte_size,submitted_at=now();
  update worker_application_corrections set received_at=now(),storage_path=p_path
    where application_id=p_application_id and request_version=p_version and doc_type=p_doc_type;
  select version into v from worker_applications where application_id=p_application_id;
  insert into worker_application_audit(application_id,application_version,action,data)
    values(p_application_id,v,'correction_received',jsonb_build_object('request_version',p_version,'doc_type',p_doc_type));
  if not exists(select 1 from worker_application_corrections where application_id=p_application_id and request_version=p_version and received_at is null)
    and (select count(*) from worker_application_documents d join storage.objects o
      on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=p_application_id)=5 then
    update worker_applications set status='under_review',version=version+1,review_note=null
      where application_id=p_application_id returning version into v;
    insert into worker_application_audit(application_id,application_version,action,data)
      values(p_application_id,v,'corrections_completed',jsonb_build_object('request_version',p_version));
  end if;
  return get_application_for_correction(p_application_id,p_version);
end $$;
revoke all on function record_application_correction(uuid,integer,text,text,text,integer) from public,anon,authenticated;
grant execute on function record_application_correction(uuid,integer,text,text,text,integer) to service_role;

create or replace function admin_review_application(p_actor_uid text,p_application_id uuid,p_expected_version integer,
  p_action text,p_note text default null,p_document_types text[] default '{}')
returns jsonb language plpgsql security definer set search_path=public as $$
declare actor admin_users; a worker_applications; next_version integer; docs text[];
  required_docs constant text[]:=array['aadhaar_back','aadhaar_front','photo','police_certificate','selfie'];
  wid uuid; cert uuid; cert_number text; snap jsonb; doc text;
begin
  if p_action not in ('approve','reject','request_changes') then raise exception 'INVALID_REVIEW_ACTION';end if;
  actor:=require_application_admin(p_actor_uid,p_action in ('approve','reject'));
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found then raise exception 'APPLICATION_NOT_FOUND';end if;
  if a.version is distinct from p_expected_version then raise exception 'APPLICATION_VERSION_CONFLICT';end if;
  if a.status in ('approved','rejected') then raise exception 'APPLICATION_ALREADY_REVIEWED';end if;
  if length(coalesce(p_note,''))>4000 then raise exception 'REVIEW_NOTE_TOO_LONG';end if;
  select coalesce(array_agg(distinct x order by x),'{}') into docs from unnest(coalesce(p_document_types,'{}')) x;
  if not docs<@required_docs then raise exception 'INVALID_DOCUMENT_TYPES';end if;
  next_version:=a.version+1;
  if p_action='approve' then
    if a.status<>'under_review' then raise exception 'APPLICATION_NOT_READY';end if;
    if docs is distinct from required_docs then raise exception 'ALL_DOCUMENT_CHECKS_REQUIRED';end if;
    wid:=approve_worker_application(p_application_id,p_note);
    update worker_applications set version=next_version where application_id=p_application_id;
    cert:=gen_random_uuid();cert_number:='KC-'||to_char(now(),'YYYY')||'-'||upper(encode(gen_random_bytes(6),'hex'));
    snap:=jsonb_build_object('certificate_number',cert_number,'partner_id',(select partner_id from workers where worker_id=wid),
      'full_name',a.details->>'full_name','profession',a.details->>'profession','district',a.details->>'district',
      'services',(select coalesce(jsonb_agg(jsonb_build_object('service_id',s.service_id,'service_name',s.service_name) order by s.service_name),'[]'::jsonb)
        from worker_services ws join services s using(service_id) where ws.worker_id=wid),
      'approved_at',now(),'checked_document_types',to_jsonb(docs),'review_scope','Application and supplied documents reviewed by Kaylo.');
    insert into partner_certificates(certificate_id,certificate_number,application_id,worker_id,application_version,issued_by,checked_document_types,snapshot)
      values(cert,cert_number,p_application_id,wid,next_version,p_actor_uid,docs,snap);
    perform queue_application_mail(p_application_id,next_version,'approved',a.details->>'email',
      jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',next_version,
        'worker_id',wid,'partner_id',(select partner_id from workers where worker_id=wid),'certificate_id',cert));
  elsif p_action='reject' then
    if length(trim(coalesce(p_note,'')))=0 then raise exception 'REVIEW_REASON_REQUIRED';end if;
    update worker_applications set status='rejected',reviewed_at=now(),review_note=p_note,
      version=next_version,upload_expires_at=now(),correction_expires_at=now() where application_id=p_application_id;
    perform queue_application_mail(p_application_id,next_version,'rejected',a.details->>'email',
      jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',next_version,'note',p_note));
  else
    if a.status not in ('submitted','under_review','changes_requested') then raise exception 'APPLICATION_NOT_READY';end if;
    if length(trim(coalesce(p_note,'')))=0 then raise exception 'REVIEW_REASON_REQUIRED';end if;
    if cardinality(docs)=0 then raise exception 'REQUESTED_DOCUMENTS_REQUIRED';end if;
    -- If reviewing an incomplete application, request every still-missing file.
    foreach doc in array required_docs loop
      if not exists(select 1 from worker_application_documents d join storage.objects o
        on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=p_application_id and d.doc_type=doc)
        and not doc=any(docs) then raise exception 'MISSING_DOCUMENT_MUST_BE_REQUESTED';end if;
    end loop;
    insert into worker_application_corrections(application_id,request_version,doc_type,note,requested_by)
      select p_application_id,next_version,x,p_note,p_actor_uid from unnest(docs) x;
    update worker_applications set status='changes_requested',version=next_version,correction_version=next_version,
      correction_expires_at=now()+interval '7 days',upload_expires_at=now(),review_note=p_note
      where application_id=p_application_id;
    perform queue_application_mail(p_application_id,next_version,'changes_requested',a.details->>'email',
      jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',next_version,
        'correction_version',next_version,'expires_at',now()+interval '7 days','note',p_note,'requested_documents',to_jsonb(docs)));
  end if;
  insert into worker_application_audit(application_id,application_version,action,actor_uid,actor_email,actor_role,data)
    values(p_application_id,next_version,p_action,p_actor_uid,actor.email,actor.role,
      jsonb_build_object('previous_status',a.status,'note',p_note,'document_types',to_jsonb(docs),'certificate_id',cert));
  select * into a from worker_applications where application_id=p_application_id;
  return jsonb_build_object('application_id',a.application_id,'reference',a.reference,'status',a.status,'version',a.version,
    'worker_id',a.worker_id,'certificate_id',cert,'correction_version',a.correction_version);
end $$;
revoke all on function admin_review_application(text,uuid,integer,text,text,text[]) from public,anon,authenticated;
grant execute on function admin_review_application(text,uuid,integer,text,text,text[]) to service_role;

create or replace function application_mail_is_current(p_mail_id uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from application_mail_outbox m join worker_applications a using(application_id)
    where m.mail_id=p_mail_id and case m.kind
      when 'submitted' then a.status='under_review'
        and (select count(*) from worker_application_documents d join storage.objects o
          on o.bucket_id='worker-documents' and o.name=d.storage_path where d.application_id=a.application_id)=5
        and not exists(select 1 from application_mail_outbox newer
        where newer.application_id=m.application_id and newer.kind='submitted' and newer.application_version>m.application_version)
      when 'changes_requested' then a.status='changes_requested' and a.correction_version=m.application_version
        and a.correction_expires_at>now()
      when 'approved' then a.status='approved' and a.version=m.application_version
      when 'rejected' then a.status='rejected' and a.version=m.application_version
      else false end);
$$;
revoke all on function application_mail_is_current(uuid) from public,anon,authenticated;
grant execute on function application_mail_is_current(uuid) to service_role;

create or replace function claim_application_mail(p_mail_id uuid default null)
returns jsonb language plpgsql security definer set search_path=public as $$
declare m application_mail_outbox; claim uuid:=gen_random_uuid();
begin
  select * into m from application_mail_outbox x where (p_mail_id is null or x.mail_id=p_mail_id)
    and (x.status in ('pending','failed') or (x.status='sending' and x.lease_until<now()))
    and application_mail_is_current(x.mail_id)
    order by x.created_at,x.mail_id for update skip locked limit 1;
  if not found then return null;end if;
  update application_mail_outbox set status='sending',claim_id=claim,lease_until=now()+interval '5 minutes',
    attempts=attempts+1,last_error=null where mail_id=m.mail_id returning * into m;
  return jsonb_build_object('mail_id',m.mail_id,'claim_id',claim,'application_id',m.application_id,
    'application_version',m.application_version,'kind',m.kind,'recipient_email',m.recipient_email,
    'template_data',m.template_data,'attempts',m.attempts);
end $$;
create or replace function finish_application_mail(p_mail_id uuid,p_claim_id uuid,p_sent boolean,p_error text default null)
returns boolean language plpgsql security definer set search_path=public as $$
declare m application_mail_outbox;
begin
  update application_mail_outbox set status=case when p_sent is true then 'sent' else 'failed' end,
    sent_at=case when p_sent is true then now() else null end,claim_id=null,lease_until=null,
    last_error=case when p_sent is true then null else left(coalesce(p_error,'DELIVERY_FAILED'),512) end
    where mail_id=p_mail_id and claim_id=p_claim_id and p_claim_id is not null and status='sending'
    returning * into m;
  if not found then return false;end if;
  if p_sent is true and m.kind='submitted' then
    update worker_applications set admin_notified_at=now() where application_id=m.application_id;
  end if;
  insert into worker_application_audit(application_id,application_version,action,data)
    values(m.application_id,m.application_version,case when p_sent is true then 'email_sent' else 'email_failed' end,
      jsonb_build_object('mail_id',m.mail_id,'kind',m.kind,'attempt',m.attempts,'error',m.last_error));
  return true;
end $$;
revoke all on function claim_application_mail(uuid),finish_application_mail(uuid,uuid,boolean,text) from public,anon,authenticated;
grant execute on function claim_application_mail(uuid),finish_application_mail(uuid,uuid,boolean,text) to service_role;

create or replace function admin_application_list(p_actor_uid text,p_status text default null,p_page integer default 1,
  p_page_size integer default 25,p_search text default null)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb; count_all integer; page_n integer:=greatest(coalesce(p_page,1),1);
  size_n integer:=greatest(1,least(coalesce(p_page_size,25),100)); search_n text:=nullif(trim(left(coalesce(p_search,''),120)),'');
begin
  perform require_application_admin(p_actor_uid,false);
  if p_status is not null and p_status not in ('submitted','under_review','changes_requested','approved','rejected') then raise exception 'INVALID_APPLICATION_STATUS';end if;
  select count(*) into count_all from worker_applications a where (p_status is null or a.status=p_status)
    and (search_n is null or a.reference ilike '%'||search_n||'%' or a.details->>'full_name' ilike '%'||search_n||'%'
      or a.details->>'email' ilike '%'||search_n||'%');
  select coalesce(jsonb_agg(to_jsonb(x) order by x.submitted_at desc,x.application_id),'[]'::jsonb) into result from (
    select a.application_id,a.reference,a.status,a.version,a.submitted_at,a.reviewed_at,
      a.details->>'full_name' as full_name,a.details->>'profession' as profession,a.details->>'district' as district,
      (select count(*) from worker_application_documents d where d.application_id=a.application_id) as documents_received,
      (select m.status from application_mail_outbox m where m.application_id=a.application_id order by m.application_version desc,m.created_at desc,m.mail_id desc limit 1) as delivery_status
    from worker_applications a where (p_status is null or a.status=p_status)
      and (search_n is null or a.reference ilike '%'||search_n||'%' or a.details->>'full_name' ilike '%'||search_n||'%'
        or a.details->>'email' ilike '%'||search_n||'%')
    order by a.submitted_at desc,a.application_id limit size_n offset ((page_n::bigint-1)*size_n)
  ) x;
  return jsonb_build_object('applications',result,'total',count_all,'page',page_n,'page_size',size_n);
end $$;

create or replace function admin_application_certificate(p_actor_uid text,p_application_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare cert jsonb;
begin
  perform require_application_admin(p_actor_uid,false);
  select to_jsonb(c) into cert from partner_certificates c join worker_applications a using(application_id)
    where c.application_id=p_application_id and a.status='approved';
  return cert;
end $$;

create or replace function admin_application_detail(p_actor_uid text,p_application_id uuid)
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare a worker_applications;
begin
  perform require_application_admin(p_actor_uid,false);
  select * into a from worker_applications where application_id=p_application_id;
  if not found then raise exception 'APPLICATION_NOT_FOUND';end if;
  return jsonb_build_object('application',jsonb_build_object('application_id',a.application_id,'reference',a.reference,
    'status',a.status,'version',a.version,'details',a.details,'phone',a.phone,'submitted_at',a.submitted_at,
    'reviewed_at',a.reviewed_at,'review_note',a.review_note,'worker_id',a.worker_id,'correction_version',a.correction_version,
    'correction_expires_at',a.correction_expires_at),
    'documents',coalesce((select jsonb_agg(jsonb_build_object('doc_type',d.doc_type,'storage_path',d.storage_path,
      'content_type',d.content_type,'byte_size',d.byte_size,'submitted_at',d.submitted_at,
      'history',coalesce((select jsonb_agg(to_jsonb(h) order by h.recorded_at,h.history_id)
        from worker_application_document_history h where h.application_id=d.application_id and h.doc_type=d.doc_type),'[]'::jsonb),
      'corrections',coalesce((select jsonb_agg(to_jsonb(c) order by c.request_version)
        from worker_application_corrections c where c.application_id=d.application_id and c.doc_type=d.doc_type),'[]'::jsonb)) order by d.doc_type)
      from worker_application_documents d where d.application_id=p_application_id),'[]'::jsonb),
    'audit',coalesce((select jsonb_agg(to_jsonb(e) order by e.created_at,e.event_id) from worker_application_audit e
      where e.application_id=p_application_id),'[]'::jsonb),
    'deliveries',coalesce((select jsonb_agg(jsonb_build_object('mail_id',m.mail_id,'application_version',m.application_version,
      'kind',m.kind,'recipient_email',m.recipient_email,'status',m.status,'is_current',application_mail_is_current(m.mail_id),'attempts',m.attempts,'last_error',m.last_error,
      'created_at',m.created_at,'sent_at',m.sent_at) order by m.application_version desc,m.created_at desc,m.mail_id desc)
      from application_mail_outbox m where m.application_id=p_application_id),'[]'::jsonb),
    'certificate',admin_application_certificate(p_actor_uid,p_application_id));
end $$;
revoke all on function admin_application_list(text,text,integer,integer,text),admin_application_detail(text,uuid),
  admin_application_certificate(text,uuid) from public,anon,authenticated;
grant execute on function admin_application_list(text,text,integer,integer,text),admin_application_detail(text,uuid),
  admin_application_certificate(text,uuid) to service_role;

insert into application_mail_outbox(application_id,application_version,kind,recipient_email,template_data,status,sent_at)
  select a.application_id,a.version,'submitted','kayloapp@gmail.com',
    jsonb_build_object('reference',a.reference,'application_id',a.application_id,'version',a.version),
    case when a.admin_notified_at is null then 'pending' else 'sent' end,a.admin_notified_at
  from worker_applications a where a.status='under_review'
    and (select count(*) from worker_application_documents d where d.application_id=a.application_id)=5
    and not exists(select 1 from application_mail_outbox m where m.application_id=a.application_id and m.kind='submitted')
  on conflict(application_id,application_version,kind) do nothing;

-- Open correction requests also reserve their phone number.
create or replace function submit_worker_application(p_details jsonb)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare
  v_phone text := canonical_partner_phone(p_details->>'phone');
  v_email text := lower(trim(coalesce(p_details->>'email','')));
  v_token text := p_details->>'client_request_token';
  v_app worker_applications;
  svc text;
  v_bank jsonb := p_details->'bank_account';
begin
  if jsonb_typeof(p_details) is distinct from 'object' or octet_length(p_details::text)>16384 then
    raise exception 'INVALID_APPLICATION'; end if;
  if length(trim(coalesce(p_details->>'full_name',''))) not between 2 and 120 then raise exception 'INVALID_NAME'; end if;
  if v_phone !~ '^\+[1-9][0-9]{7,14}$' then raise exception 'INVALID_PHONE'; end if;
  if length(v_email)>254 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
     or v_email like '%@partners.kaylo.app' then raise exception 'INVALID_EMAIL'; end if;
  if p_details->'consent' is distinct from 'true'::jsonb then raise exception 'CONSENT_REQUIRED'; end if;
  if length(trim(coalesce(p_details->>'profession',''))) not between 2 and 120
     or length(trim(coalesce(p_details->>'district',''))) not between 2 and 100 then raise exception 'INVALID_SERVICE_AREA'; end if;
  if coalesce(p_details->>'experience_years','') !~ '^[0-9]{1,2}$'
     or (p_details->>'experience_years')::int not between 0 and 70 then raise exception 'INVALID_EXPERIENCE'; end if;
  if coalesce(p_details->>'travel_radius_km','') !~ '^[0-9]{1,3}(\.[0-9]{1,2})?$'
     or (p_details->>'travel_radius_km')::numeric not between 1 and 100 then raise exception 'INVALID_RADIUS'; end if;
  if jsonb_typeof(p_details->'services') is distinct from 'array' then raise exception 'INVALID_SERVICES'; end if;
  if jsonb_array_length(p_details->'services') not between 1 and 30 then raise exception 'INVALID_SERVICES'; end if;
  for svc in select jsonb_array_elements_text(p_details->'services') loop
    if not exists(select 1 from services where service_id::text=svc and is_active) then raise exception 'INVALID_SERVICES'; end if;
  end loop;
  if coalesce(p_details->>'upi_id','') !~ '^[A-Za-z0-9._-]{2,255}@[A-Za-z0-9.-]{2,64}$' then
    if jsonb_typeof(v_bank) is distinct from 'object'
      or coalesce(v_bank->>'account_number','') !~ '^[0-9]{6,20}$'
      or coalesce(v_bank->>'ifsc','') !~ '^[A-Z]{4}0[A-Z0-9]{6}$'
      or length(trim(coalesce(v_bank->>'account_holder',''))) not between 2 and 120
      or length(trim(coalesce(v_bank->>'bank_name',''))) not between 2 and 120 then raise exception 'INVALID_PAYOUT'; end if;
  end if;
  if coalesce(v_token,'') !~ '^[0-9a-f]{64}$' then raise exception 'INVALID_REQUEST_TOKEN'; end if;
  -- Serialize phone checks even for repeated concurrent unauthenticated submits.
  perform pg_advisory_xact_lock(hashtextextended(v_phone,2400));
  select * into v_app from worker_applications where phone=v_phone
    and upload_token_hash=encode(digest(v_token,'sha256'),'hex')
    and status in ('submitted','under_review') and upload_expires_at>now();
  if found then return jsonb_build_object('application_id',v_app.application_id,'reference',v_app.reference,
    'upload_token',v_token,'upload_expires_at',v_app.upload_expires_at,'status',v_app.status); end if;
  if exists(select 1 from worker_applications where phone=v_phone and
      (status in ('submitted','under_review','changes_requested','approved') or submitted_at>now()-interval '24 hours')) then
    raise exception 'APPLICATION_ALREADY_EXISTS'; end if;
  if exists(select 1 from persons p where
      canonical_partner_phone(p.phone_number)=v_phone or lower(p.email)=v_email) then
    raise exception 'IDENTITY_ALREADY_IN_USE'; end if;
  insert into worker_applications(phone,details,upload_token_hash)
  values(v_phone,(p_details - 'client_request_token') || jsonb_build_object('phone',v_phone,'email',v_email),encode(digest(v_token,'sha256'),'hex'))
  returning * into v_app;
  return jsonb_build_object('application_id',v_app.application_id,'reference',v_app.reference,
    'upload_token',v_token,'upload_expires_at',v_app.upload_expires_at,'status',v_app.status);
end $$;
revoke all on function submit_worker_application(jsonb) from public;
grant execute on function submit_worker_application(jsonb) to anon,authenticated;


notify pgrst, 'reload schema';
commit;
