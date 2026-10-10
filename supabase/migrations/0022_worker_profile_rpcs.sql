-- The partner app's own profile, in three calls.
--
-- my_worker_profile() returns everything the profile screen shows for the
-- signed-in worker in one round trip: the person, the worker row, the
-- services offered, the service area, the payout account and the state of
-- each submitted document. update_worker_profile(details) changes only the
-- keys it is given, the same shape register_worker takes, so a partial edit
-- never blanks a field. set_worker_available(flag) is the on-duty switch:
-- false hides the worker from new bookings without touching anything else.
-- All three run as the owner and find the worker through the Firebase
-- subject, so a worker can never read or change another worker's row.
-- Safe to run more than once.
begin;

create or replace function my_worker_profile()
returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'worker_id', w.worker_id,
    'person_id', p.person_id,
    'full_name', p.full_name,
    'phone_number', p.phone_number,
    'email', p.email,
    'profile_photo', p.profile_photo,
    'experience_years', w.experience_years,
    'hourly_rate', w.hourly_rate,
    'travel_radius_km', w.travel_radius_km,
    'bio', w.bio,
    'is_verified', w.is_verified,
    'verification_status', w.verification_status,
    'is_available', w.is_available,
    'average_rating', w.average_rating,
    'total_jobs', w.total_jobs,
    'reviews_count', (select count(*) from reviews r where r.worker_id = w.worker_id),
    'joined_date', w.joined_date,
    'working_hours', w.working_hours,
    'district', (select l.district from locations l
                 where l.person_id = p.person_id
                 order by l.is_default desc, l.created_at limit 1),
    'services', coalesce((
      select jsonb_agg(jsonb_build_object('service_id', s.service_id, 'service_name', s.service_name)
                       order by s.service_name)
      from worker_services ws join services s on s.service_id = ws.service_id
      where ws.worker_id = w.worker_id), '[]'::jsonb),
    'upi_id', pa.upi_id,
    'bank_account', pa.bank_account,
    'documents', coalesce((
      select jsonb_agg(jsonb_build_object('doc_type', d.doc_type, 'status', d.status) order by d.doc_type)
      from worker_documents d where d.worker_id = w.worker_id), '[]'::jsonb)
  )
  from workers w
  join persons p on p.person_id = w.person_id
  left join worker_payout_accounts pa on pa.worker_id = w.worker_id
  where w.worker_id = current_worker_id();
$$;
revoke all on function my_worker_profile() from public;
grant execute on function my_worker_profile() to anon, authenticated;

-- details: any of { full_name, photo_path, bio, experience_years, hourly_rate,
--   travel_radius_km, working_hours, district, services: [service_id, ...],
--   upi_id, bank_account }. Keys that are absent stay as they are.
create or replace function update_worker_profile(p_details jsonb)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  wid uuid := current_worker_id();
  me uuid := current_person_id();
  svc text;
begin
  if me is null then raise exception 'Sign in first'; end if;
  if wid is null then raise exception 'Register as a worker first'; end if;

  if p_details ? 'full_name' then
    if coalesce(trim(p_details->>'full_name'), '') = '' then
      raise exception 'Name is required';
    end if;
    update persons set full_name = trim(p_details->>'full_name') where person_id = me;
  end if;
  if p_details ? 'photo_path' and coalesce(p_details->>'photo_path', '') <> '' then
    update persons set profile_photo = p_details->>'photo_path' where person_id = me;
  end if;

  if p_details ? 'travel_radius_km' then
    if (p_details->>'travel_radius_km')::numeric not between 1 and 100 then
      raise exception 'Travel radius must be between 1 and 100 km';
    end if;
  end if;
  update workers set
    bio = case when p_details ? 'bio' then nullif(trim(p_details->>'bio'), '') else bio end,
    experience_years = case when p_details ? 'experience_years'
                            then coalesce((p_details->>'experience_years')::int, experience_years)
                            else experience_years end,
    hourly_rate = case when p_details ? 'hourly_rate' then (p_details->>'hourly_rate')::numeric else hourly_rate end,
    travel_radius_km = case when p_details ? 'travel_radius_km'
                            then (p_details->>'travel_radius_km')::numeric else travel_radius_km end,
    working_hours = case when p_details ? 'working_hours'
                         then nullif(trim(p_details->>'working_hours'), '') else working_hours end
    where worker_id = wid;

  if p_details ? 'services' then
    if jsonb_typeof(p_details->'services') is distinct from 'array'
       or jsonb_array_length(p_details->'services') = 0 then
      raise exception 'Choose at least one service';
    end if;
    delete from worker_services where worker_id = wid
      and service_id not in (select jsonb_array_elements_text(p_details->'services')::uuid);
    for svc in select jsonb_array_elements_text(p_details->'services') loop
      insert into worker_services (worker_id, service_id, experience_years)
      values (wid, svc::uuid, (select experience_years from workers where worker_id = wid))
      on conflict (worker_id, service_id) do nothing;
    end loop;
  end if;

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

  if p_details ? 'upi_id' or p_details ? 'bank_account' then
    insert into worker_payout_accounts (worker_id, upi_id, bank_account)
    values (wid, nullif(trim(coalesce(p_details->>'upi_id', '')), ''),
                 nullif(trim(coalesce(p_details->>'bank_account', '')), ''))
    on conflict (worker_id) do update
      set upi_id = case when p_details ? 'upi_id' then excluded.upi_id else worker_payout_accounts.upi_id end,
          bank_account = case when p_details ? 'bank_account'
                              then excluded.bank_account else worker_payout_accounts.bank_account end,
          updated_at = now();
  end if;

  return my_worker_profile();
end $$;
revoke all on function update_worker_profile(jsonb) from public;
grant execute on function update_worker_profile(jsonb) to anon, authenticated;

create or replace function set_worker_available(p_available boolean)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  wid uuid := current_worker_id();
begin
  if wid is null then raise exception 'Register as a worker first'; end if;
  update workers set is_available = coalesce(p_available, true) where worker_id = wid;
  return coalesce(p_available, true);
end $$;
revoke all on function set_worker_available(boolean) from public;
grant execute on function set_worker_available(boolean) to anon, authenticated;

notify pgrst, 'reload schema';
commit;
