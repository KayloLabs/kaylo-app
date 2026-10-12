-- Website enquiries are separate from reviewed partner applications.
-- Public clients can submit a validated enquiry but cannot read or change rows.
begin;
create table if not exists public.professional_application_leads (
  id uuid primary key,
  name text not null check (length(name) between 2 and 80),
  phone text not null check (phone ~ '^\+91[6-9][0-9]{9}$'),
  email text check (email is null or (length(email) <= 150 and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$')),
  city text not null check (length(city) between 2 and 100),
  skill text not null check (skill in ('Electrician','Plumber','Painter','Cleaner','Mechanic','AC technician','Appliance repair','Carpenter','Gardener','Farm services','Caregiver','Other')),
  experience text not null check (experience in ('Less than 1 year','1–3 years','3–5 years','5+ years')),
  about text not null default '' check (length(about) <= 1000),
  consent_version text not null default '2026-10-02',
  created_at timestamptz not null default now()
);
create index if not exists professional_application_leads_created_at on public.professional_application_leads(created_at desc);
alter table public.professional_application_leads enable row level security;
revoke all on public.professional_application_leads from public, anon, authenticated;
grant select, insert, update, delete on public.professional_application_leads to service_role;

create or replace function public.submit_professional_lead(input jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  field text; v_id text; v_name text; v_phone text; v_email text;
  v_city text; v_skill text; v_experience text; v_about text;
begin
  if input is null or jsonb_typeof(input) <> 'object' then
    raise exception using errcode = '22023', message = 'Please complete the application form.';
  end if;
  if octet_length(input::text) > 8192 then
    raise exception using errcode = '22023', message = 'Application is too large.';
  end if;
  foreach field in array array['id','name','phone','city','skill','experience'] loop
    if jsonb_typeof(input->field) is distinct from 'string' then
      raise exception using errcode = '22023', message = 'Please complete the application form.';
    end if;
  end loop;
  foreach field in array array['email','about','website'] loop
    if input ? field and jsonb_typeof(input->field) is distinct from 'string' then
      raise exception using errcode = '22023', message = 'Please complete the application form.';
    end if;
  end loop;
  v_id := btrim(input->>'id');
  v_name := btrim(input->>'name');
  v_phone := regexp_replace(btrim(input->>'phone'), '[[:space:]()-]', '', 'g');
  v_email := nullif(btrim(input->>'email'), '');
  v_city := btrim(input->>'city');
  v_skill := btrim(input->>'skill');
  v_experience := btrim(input->>'experience');
  v_about := coalesce(btrim(input->>'about'), '');
  if v_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    raise exception using errcode = '22023', message = 'Please refresh this page and try again.';
  end if;
  if length(v_name) not between 2 and 80 then
    raise exception using errcode = '22023', message = 'Enter your full name (2–80 characters).';
  end if;
  if length(btrim(input->>'phone')) > 24 or v_phone !~ '^(\+91)?[6-9][0-9]{9}$' then
    raise exception using errcode = '22023', message = 'Enter a valid 10-digit Indian mobile number.';
  end if;
  if v_email is not null and (length(v_email) > 150 or v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$') then
    raise exception using errcode = '22023', message = 'Enter a valid email address or leave it blank.';
  end if;
  if length(v_city) not between 2 and 100 then
    raise exception using errcode = '22023', message = 'Enter your town or city.';
  end if;
  if v_skill not in ('Electrician','Plumber','Painter','Cleaner','Mechanic','AC technician','Appliance repair','Carpenter','Gardener','Farm services','Caregiver','Other')
    or v_experience not in ('Less than 1 year','1–3 years','3–5 years','5+ years') then
    raise exception using errcode = '22023', message = 'Choose your service and experience.';
  end if;
  if length(v_about) > 1000 then
    raise exception using errcode = '22023', message = 'Keep your introduction under 1,000 characters.';
  end if;
  if input->'consent' is distinct from 'true'::jsonb then
    raise exception using errcode = '22023', message = 'Please agree to be contacted about your application.';
  end if;
  if coalesce(input->>'website', '') <> '' then
    raise exception using errcode = '22023', message = 'Unable to submit this application.';
  end if;
  if left(v_phone, 3) <> '+91' then v_phone := '+91' || v_phone; end if;
  -- Retries return only the supplied receipt, never existing personal details.
  -- A reused UUID cannot read or overwrite another submission.
  insert into public.professional_application_leads
    (id, name, phone, email, city, skill, experience, about, consent_version)
  values (v_id::uuid, v_name, v_phone, v_email, v_city, v_skill, v_experience, v_about, '2026-10-02')
  on conflict (id) do nothing;
  return jsonb_build_object('ok', true, 'reference', v_id::uuid);
end;
$$;
revoke all on function public.submit_professional_lead(jsonb) from public, anon, authenticated;
grant execute on function public.submit_professional_lead(jsonb) to anon, authenticated, service_role;
comment on table public.professional_application_leads is
  'Private website enquiries. These are not approved or document-complete Kaylo Partner applications.';
comment on function public.submit_professional_lead(jsonb) is
  'Insert-only website enquiry submission. Returns only the supplied UUID receipt, with no public row access.';
commit;
