-- Public partner applications, with private documents and one open application per phone.
-- Run after 0023. Safe to rerun. A submission is not an identity or worker account.
begin;

create table if not exists worker_applications (
  application_id uuid primary key default gen_random_uuid(),
  reference text not null unique default ('KA-' || upper(encode(gen_random_bytes(12), 'hex'))),
  status text not null default 'submitted' check (status in ('submitted','under_review','approved','rejected')),
  phone text not null,
  details jsonb not null,
  upload_token_hash text not null,
  upload_expires_at timestamptz not null default now() + interval '24 hours',
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  review_note text,
  worker_id uuid references workers(worker_id)
);
create unique index if not exists worker_applications_open_phone on worker_applications(phone)
  where status in ('submitted','under_review','approved');
create table if not exists worker_application_documents (
  application_id uuid not null references worker_applications(application_id) on delete cascade,
  doc_type text not null check (doc_type in ('photo','aadhaar_front','aadhaar_back','police_certificate','selfie')),
  storage_path text not null unique,
  content_type text not null check (content_type in ('image/jpeg','image/png','application/pdf')),
  byte_size integer not null check (byte_size between 1 and 10485760),
  submitted_at timestamptz not null default now(),
  primary key (application_id,doc_type)
);
alter table worker_applications enable row level security;
alter table worker_application_documents enable row level security;
revoke all on worker_applications,worker_application_documents from public,anon,authenticated;
grant all on worker_applications,worker_application_documents to service_role;

-- Normalize existing legacy formatting and Indian ten-digit numbers before
-- comparing identities. International numbers retain their country code.
create or replace function canonical_partner_phone(p_phone text)
returns text language sql immutable as $$
  select case when length(d)=10 then '+91'||d else '+'||d end
    from (select regexp_replace(coalesce(p_phone,''),'[^0-9]','','g') d) n;
$$;

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
      (status in ('submitted','under_review','approved') or submitted_at>now()-interval '24 hours')) then
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

create or replace function worker_application_status(p_reference text)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('reference',a.reference,'status',a.status,
    'documents_received',(select count(*) from worker_application_documents d where d.application_id=a.application_id))
  from worker_applications a where a.reference=upper(trim(p_reference));
$$;
revoke all on function worker_application_status(text) from public;
grant execute on function worker_application_status(text) to anon,authenticated;

-- Called only after the edge has uploaded and checked the object. The lock
-- serializes the final record with an admin review; approved evidence is immutable.
create or replace function record_worker_application_document(p_application_id uuid,p_token text,
  p_doc_type text,p_path text,p_content_type text,p_byte_size integer)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare a worker_applications;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found or a.status not in ('submitted','under_review') or a.upload_expires_at<now()
    or encode(digest(p_token,'sha256'),'hex')<>a.upload_token_hash then raise exception 'UPLOAD_NOT_ALLOWED'; end if;
  if p_path not like 'applications/'||p_application_id::text||'/'||p_doc_type||'/%'
    or p_path like '%..%' then raise exception 'INVALID_DOCUMENT_PATH'; end if;
  if not exists(select 1 from storage.objects where bucket_id='worker-documents' and name=p_path) then
    raise exception 'DOCUMENT_NOT_UPLOADED'; end if;
  -- Never replace the reviewed file at the same path. New uploads get fresh UUIDs.
  insert into worker_application_documents(application_id,doc_type,storage_path,content_type,byte_size)
    values(p_application_id,p_doc_type,p_path,p_content_type,p_byte_size)
    on conflict(application_id,doc_type) do update set storage_path=excluded.storage_path,
      content_type=excluded.content_type,byte_size=excluded.byte_size,submitted_at=now();
  if (select count(*) from worker_application_documents where application_id=p_application_id)=5 then
    update worker_applications set status='under_review' where application_id=p_application_id; end if;
end $$;
revoke all on function record_worker_application_document(uuid,text,text,text,text,integer) from public,anon,authenticated;
grant execute on function record_worker_application_document(uuid,text,text,text,text,integer) to service_role;

notify pgrst, 'reload schema';
commit;
