-- Worker registration and verification.
--
-- A signed-in person registers as a worker in one call (register_worker):
-- profile, services offered, service area, payout account. Their documents
-- (photo, Aadhaar front and back, police certificate, selfie) live in the
-- private storage bucket worker-documents under <worker_id>/..., tracked in
-- worker_documents. Only the worker sees their own documents; the Trust Team
-- reviews with review_worker and review_worker_document, which only the
-- service role can call. workers.is_verified now follows
-- workers.verification_status.
-- Run after 0019. Safe to run more than once.
begin;

-- 1. verification status on the worker ------------------------------------
alter table workers add column if not exists verification_status text not null default 'unverified';
alter table workers drop constraint if exists workers_verification_status_check;
alter table workers add constraint workers_verification_status_check
  check (verification_status in ('unverified', 'under_review', 'verified', 'rejected'));
alter table workers add column if not exists working_hours text;

update workers set verification_status = 'verified'
  where is_verified and verification_status = 'unverified';

create or replace function sync_worker_verified()
returns trigger language plpgsql as $$
begin
  -- Rows written with the old flag only (seed data, dashboards) keep meaning
  -- what they say; otherwise the status is the source of truth.
  if tg_op = 'INSERT' and new.is_verified and new.verification_status = 'unverified' then
    new.verification_status := 'verified';
  end if;
  new.is_verified := (new.verification_status = 'verified');
  return new;
end $$;
drop trigger if exists workers_sync_verified on workers;
create trigger workers_sync_verified
  before insert or update of verification_status, is_verified on workers
  for each row execute function sync_worker_verified();

-- 2. documents ----------------------------------------------------------------
create table if not exists worker_documents (
  document_id uuid primary key default gen_random_uuid(),
  worker_id uuid not null references workers (worker_id) on delete cascade,
  doc_type text not null
    check (doc_type in ('photo', 'aadhaar_front', 'aadhaar_back', 'police_certificate', 'selfie')),
  storage_path text not null,
  status text not null default 'pending' check (status in ('pending', 'verified', 'rejected')),
  note text,
  submitted_at timestamptz not null default now(),
  reviewed_at timestamptz,
  unique (worker_id, doc_type)
);
alter table worker_documents enable row level security;
drop policy if exists "own documents" on worker_documents;
create policy "own documents" on worker_documents for select
  using (worker_id = current_worker_id());
drop policy if exists "submit own documents" on worker_documents;
create policy "submit own documents" on worker_documents for insert
  with check (worker_id = current_worker_id() and status = 'pending');
drop policy if exists "replace own pending documents" on worker_documents;
create policy "replace own pending documents" on worker_documents for delete
  using (worker_id = current_worker_id() and status = 'pending');
grant select, insert, delete on worker_documents to anon, authenticated;

-- 3. the private bucket, when storage is present (it is on Supabase) --------
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    insert into storage.buckets (id, name, public)
      values ('worker-documents', 'worker-documents', false)
      on conflict (id) do nothing;
    execute $p$drop policy if exists "workers upload own documents" on storage.objects$p$;
    execute $p$create policy "workers upload own documents" on storage.objects for insert
      to anon, authenticated
      with check (bucket_id = 'worker-documents'
                  and (storage.foldername(name))[1] = current_worker_id()::text)$p$;
    execute $p$drop policy if exists "workers read own documents" on storage.objects$p$;
    execute $p$create policy "workers read own documents" on storage.objects for select
      to anon, authenticated
      using (bucket_id = 'worker-documents'
             and (storage.foldername(name))[1] = current_worker_id()::text)$p$;
    execute $p$drop policy if exists "workers replace own documents" on storage.objects$p$;
    execute $p$create policy "workers replace own documents" on storage.objects for delete
      to anon, authenticated
      using (bucket_id = 'worker-documents'
             and (storage.foldername(name))[1] = current_worker_id()::text)$p$;
  end if;
end $$;

-- 4. registration in one call -----------------------------------------------
-- p_details: { full_name, photo_path?, services: [service_id, ...],
--   experience_years?, hourly_rate?, district?, travel_radius_km?,
--   working_hours?, bio?, upi_id?, bank_account? }
create or replace function register_worker(p_details jsonb)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  me uuid := current_person_id();
  wid uuid;
  svc text;
  v_upi text := nullif(trim(coalesce(p_details->>'upi_id', '')), '');
  v_bank text := nullif(trim(coalesce(p_details->>'bank_account', '')), '');
begin
  if me is null then raise exception 'Sign in first'; end if;
  if coalesce(trim(p_details->>'full_name'), '') = '' then raise exception 'Name is required'; end if;
  if jsonb_typeof(p_details->'services') is distinct from 'array'
     or jsonb_array_length(p_details->'services') = 0 then
    raise exception 'Choose at least one service';
  end if;
  if v_upi is null and v_bank is null then
    raise exception 'A UPI ID or a bank account is required';
  end if;

  update persons
    set full_name = trim(p_details->>'full_name'),
        profile_photo = coalesce(nullif(p_details->>'photo_path', ''), profile_photo)
    where person_id = me;

  insert into workers (person_id, experience_years, hourly_rate, travel_radius_km, bio, working_hours,
                       verification_status)
  values (me,
          coalesce((p_details->>'experience_years')::int, 0),
          (p_details->>'hourly_rate')::numeric,
          coalesce((p_details->>'travel_radius_km')::numeric, 10),
          nullif(p_details->>'bio', ''),
          nullif(p_details->>'working_hours', ''),
          'under_review')
  on conflict (person_id) do update
    set experience_years = excluded.experience_years,
        hourly_rate = excluded.hourly_rate,
        travel_radius_km = excluded.travel_radius_km,
        bio = excluded.bio,
        working_hours = excluded.working_hours,
        verification_status = case when workers.verification_status = 'verified'
                                   then 'verified' else 'under_review' end
  returning worker_id into wid;

  delete from worker_services where worker_id = wid;
  for svc in select jsonb_array_elements_text(p_details->'services') loop
    insert into worker_services (worker_id, service_id, experience_years)
    values (wid, svc::uuid, coalesce((p_details->>'experience_years')::int, 0))
    on conflict (worker_id, service_id) do nothing;
  end loop;

  if coalesce(p_details->>'district', '') <> '' then
    if exists (select 1 from locations where person_id = me) then
      update locations set district = p_details->>'district'
        where location_id = (
          select location_id from locations where person_id = me
          order by is_default desc, created_at limit 1);
    else
      insert into locations (person_id, district, is_default, nickname)
      values (me, p_details->>'district', true, 'Work area');
    end if;
  end if;

  insert into worker_payout_accounts (worker_id, upi_id, bank_account)
  values (wid, v_upi, v_bank)
  on conflict (worker_id) do update
    set upi_id = coalesce(excluded.upi_id, worker_payout_accounts.upi_id),
        bank_account = coalesce(excluded.bank_account, worker_payout_accounts.bank_account),
        updated_at = now();

  return wid;
end $$;

-- 5. the Trust Team's side: service role only ---------------------------------
create or replace function review_worker(p_worker_id uuid, p_status text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_status not in ('under_review', 'verified', 'rejected') then
    raise exception 'Unknown status %', p_status;
  end if;
  update workers set verification_status = p_status where worker_id = p_worker_id;
  if not found then raise exception 'No such worker'; end if;
  if p_status in ('verified', 'rejected') then
    update worker_documents
      set status = p_status, reviewed_at = now(), note = coalesce(p_note, note)
      where worker_id = p_worker_id and status = 'pending';
  end if;
  insert into notifications (person_id, title, message, type)
  select person_id,
         case p_status when 'verified' then 'You are verified'
                       when 'rejected' then 'Verification needs attention'
                       else 'Verification under review' end,
         coalesce(p_note, 'Kaylo Trust Team'), 'system'
  from workers where worker_id = p_worker_id;
end $$;

create or replace function review_worker_document(p_document_id uuid, p_status text, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if p_status not in ('pending', 'verified', 'rejected') then
    raise exception 'Unknown status %', p_status;
  end if;
  update worker_documents
    set status = p_status, reviewed_at = case when p_status = 'pending' then null else now() end,
        note = coalesce(p_note, note)
    where document_id = p_document_id;
  if not found then raise exception 'No such document'; end if;
end $$;

revoke all on function register_worker(jsonb) from public;
grant execute on function register_worker(jsonb) to anon, authenticated;
revoke all on function review_worker(uuid, text, text) from public, anon, authenticated;
revoke all on function review_worker_document(uuid, text, text) from public, anon, authenticated;
grant execute on function review_worker(uuid, text, text) to service_role;
grant execute on function review_worker_document(uuid, text, text) to service_role;

notify pgrst, 'reload schema';
commit;
