-- Run as database owner after 0028. Synthetic records; always rolls back.
begin;
do $$
declare
  request jsonb; result jsonb; invalid jsonb; invalid_cases jsonb;
  role_name text; operation text; denied boolean;
  lead_id uuid := gen_random_uuid(); second_id uuid := gen_random_uuid();
begin
  request := jsonb_build_object('id', lead_id, 'name', '  Website test  ',
    'phone', '97777 70001', 'email', 'website.test@example.invalid',
    'city', 'Kochi', 'skill', 'Plumber', 'experience', '1–3 years',
    'about', 'Enquiry test', 'consent', true, 'website', '');
  execute 'set local role anon';
  result := public.submit_professional_lead(request);
  if result <> jsonb_build_object('ok', true, 'reference', lead_id) then
    raise exception 'Submission receipt is incorrect';
  end if;
  if public.submit_professional_lead(request) <> result then
    raise exception 'Submission retry is not idempotent';
  end if;
  perform public.submit_professional_lead(request || '{"name":"Attempted overwrite"}'::jsonb);
  execute 'reset role';
  if (select name from public.professional_application_leads where id = lead_id) <> 'Website test'
    or (select phone from public.professional_application_leads where id = lead_id) <> '+919777770001'
    or (select count(*) from public.professional_application_leads where id = lead_id) <> 1 then
    raise exception 'Normalization or insert-only retry failed';
  end if;
  if (select consent_version from public.professional_application_leads where id = lead_id) <> '2026-10-02'
    or (select created_at from public.professional_application_leads where id = lead_id) <> now() then
    raise exception 'Server-owned consent metadata is incorrect';
  end if;
  execute 'set local role authenticated';
  result := public.submit_professional_lead((request - 'email' - 'about' - 'website') ||
    jsonb_build_object('id', second_id, 'phone', '+91 (97777) 70002',
      'created_at', '1900-01-01', 'consent_version', 'untrusted'));
  execute 'reset role';
  if result->>'reference' <> second_id::text or
    (select email is not null or about <> '' or consent_version <> '2026-10-02' or created_at <> now()
     from public.professional_application_leads where id = second_id) then
    raise exception 'Optional fields or server-owned metadata failed';
  end if;
  foreach role_name in array array['anon', 'authenticated'] loop
    execute format('set local role %I', role_name);
    foreach operation in array array[
      'select * from public.professional_application_leads',
      'insert into public.professional_application_leads default values',
      'update public.professional_application_leads set name = ''Changed''',
      'delete from public.professional_application_leads',
      'truncate public.professional_application_leads'
    ] loop
      denied := false;
      begin execute operation; exception when insufficient_privilege then denied := true; end;
      if not denied then raise exception 'Role % can execute %', role_name, operation; end if;
    end loop;
    execute 'reset role';
  end loop;
  invalid_cases := jsonb_build_array(
    'null'::jsonb, '[]'::jsonb, 'true'::jsonb, '{}'::jsonb,
    request || '{"id":"not-a-uuid"}'::jsonb,
    request || '{"id":"00000000-0000-1000-8000-000000000000"}'::jsonb,
    request || '{"name":null}'::jsonb,
    request || '{"name":123}'::jsonb,
    request || '{"name":"x"}'::jsonb,
    request || jsonb_build_object('name', repeat('x', 81)),
    request || '{"phone":"+12025550123"}'::jsonb,
    request || '{"phone":"1234567890"}'::jsonb,
    request || '{"email":"not-an-email"}'::jsonb,
    request || '{"email":null}'::jsonb,
    request || jsonb_build_object('email', repeat('a', 140) || '@example.com'),
    request || '{"city":"x"}'::jsonb,
    request || jsonb_build_object('city', repeat('x', 101)),
    request || '{"skill":"Unsupported"}'::jsonb,
    request || '{"experience":"100 years"}'::jsonb,
    request || '{"about":{}}'::jsonb,
    request || jsonb_build_object('about', repeat('x', 1001)),
    request || '{"consent":false}'::jsonb,
    request || '{"consent":"true"}'::jsonb,
    request - 'consent',
    request || '{"website":"https://spam.invalid"}'::jsonb,
    request || '{"website":true}'::jsonb,
    request || jsonb_build_object('unknown', repeat('x', 8193))
  );
  execute 'set local role anon';
  for invalid in select value from jsonb_array_elements(invalid_cases) loop
    denied := false;
    begin perform public.submit_professional_lead(invalid);
      exception when invalid_parameter_value then denied := true;
    end;
    if not denied then raise exception 'Invalid enquiry accepted: %', invalid; end if;
  end loop;
  denied := false;
  begin perform public.submit_professional_lead(null);
    exception when invalid_parameter_value then denied := true;
  end;
  if not denied then raise exception 'SQL null was accepted'; end if;
  execute 'reset role';
  if not (select relrowsecurity from pg_class where oid = 'public.professional_application_leads'::regclass) then
    raise exception 'Private enquiries do not have row-level security';
  end if;
end;
$$;
rollback;
