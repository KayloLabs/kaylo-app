-- Run as database owner after 0025. Synthetic records; always rolls back.
begin;
do $$
declare a jsonb; a2 jsonb; details jsonb; token text:=repeat('ab',32); svc uuid;
  aid uuid; wid uuid; pid uuid; cpid uuid:=gen_random_uuid(); uid text; issue jsonb;
  doc text; path text; denied boolean; state jsonb; old_claims jsonb; reset_issue jsonb;
begin
  select service_id into svc from services where is_active limit 1;
  details:=jsonb_build_object('full_name','Application test','phone','+919777770001',
    'email','partner.application.test@example.invalid','profession','Plumber','services',jsonb_build_array(svc),
    'experience_years',5,'district','Kannur','travel_radius_km',15,'upi_id','app.test@bank',
    'consent',true,'client_request_token',token);
  execute 'set local role anon';
  a:=submit_worker_application(details);aid:=(a->>'application_id')::uuid;
  a2:=submit_worker_application(details);
  if a<>a2 then raise exception 'submission retry must recover same bearer/application'; end if;
  if worker_application_status(a->>'reference')->>'status'<>'submitted' then raise exception 'wrong public status'; end if;
  denied:=false;begin perform submit_worker_application(details||jsonb_build_object('client_request_token',repeat('cd',32)));
    exception when others then denied:=true;end;
  if not denied then raise exception 'duplicate open phone application accepted';end if;
  denied:=false;begin perform approve_worker_application(aid,'Unauthorized');exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'anonymous approval allowed';end if;
  denied:=false;begin perform register_worker(details);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'legacy registration remains callable';end if;
  denied:=false;begin perform 1 from worker_applications;exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'private application is readable';end if;
  execute 'reset role';
  if (select wa.details ? 'client_request_token' from worker_applications wa where wa.application_id=aid) then raise exception 'bearer token persisted in details';end if;
  denied:=false;begin perform approve_worker_application(aid);exception when others then denied:=true;end;
  if not denied then raise exception 'approval without all documents';end if;
  foreach doc in array array['photo','aadhaar_front','aadhaar_back','police_certificate','selfie'] loop
    path:='applications/'||aid::text||'/'||doc||'/'||gen_random_uuid()||'.jpg';
    denied:=false;begin perform record_worker_application_document(aid,token,doc,path,'image/jpeg',100);
      exception when others then denied:=true;end;
    if not denied then raise exception 'unuploaded object accepted';end if;
    insert into storage.objects(bucket_id,name) values('worker-documents',path);
    denied:=false;begin perform record_worker_application_document(aid,repeat('00',32),doc,path,'image/jpeg',100);
      exception when others then denied:=true;end;
    if not denied then raise exception 'wrong bearer accepted';end if;
    perform record_worker_application_document(aid,token,doc,path,'image/jpeg',100);
  end loop;
  if worker_application_status(a->>'reference')->>'status'<>'under_review' then raise exception 'complete application not under review';end if;
  wid:=approve_worker_application(aid,'Reviewed supplied application');
  select person_id into pid from workers where worker_id=wid;
  if exists(select 1 from customers where person_id=pid) then raise exception 'approved worker is also a customer';end if;
  if not exists(select 1 from person_roles pr join roles r using(role_id) where pr.person_id=pid and r.role_name='worker') then raise exception 'worker role missing';end if;
  if (select count(*) from worker_documents where worker_id=wid and status='verified' and reviewed_at is not null and note='Reviewed supplied application')<>5 then raise exception 'admin document review attestation was not recorded';end if;
  denied:=false;begin perform approve_worker_application(aid);exception when others then denied:=true;end;
  if not denied then raise exception 'application approved twice';end if;
  denied:=false;begin perform record_worker_application_document(aid,token,'selfie',path,'image/jpeg',100);exception when others then denied:=true;end;
  if not denied then raise exception 'approved evidence altered';end if;
  denied:=false;begin insert into customers(person_id) values(pid);exception when others then denied:=true;end;
  if not denied then raise exception 'worker became customer via direct insert';end if;

  issue:=begin_partner_credential_issue(wid);uid:=issue->>'firebase_uid';
  perform finish_partner_credential_issue(wid,(issue->>'issuance_id')::uuid,1000);
  denied:=false;begin perform begin_partner_credential_issue(wid,true);exception when others then denied:=true;end;
  if not denied then raise exception 'SMTP delivery lease allows concurrent reset';end if;
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'email',lower(issue->>'partner_id')||'@partners.kaylo.app',
    'auth_time',2000,'iat',2000,'kaylo_role','worker','kaylo_partner_id',issue->>'partner_id',
    'kaylo_issuance_id',issue->>'issuance_id',
    'firebase',jsonb_build_object('sign_in_provider','password'))::text,true);
  execute 'set local role anon';
  state:=partner_login_state();
  if not (state->>'must_change_password')::boolean then raise exception 'first login not gated';end if;
  if current_worker_id() is not null or my_worker_profile() is not null then raise exception 'temporary-password session reached worker data';end if;
  denied:=false;begin perform delete_current_kaylo_account();exception when others then
    if sqlerrm='ACCOUNT_ACCESS_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'gated worker can delete issued Firebase identity';end if;
  denied:=false;begin perform mark_password_changed(wid,(issue->>'issuance_id')::uuid,2000);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'client can clear password gate';end if;
  denied:=false;begin update workers set must_change_password=false where worker_id=wid;exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'direct gate overwrite allowed';end if;
  denied:=false;begin perform ensure_customer_profile();exception when others then
    if sqlerrm='PARTNER_ACCOUNT_NOT_ALLOWED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'worker acquired customer row via RPC';end if;
  execute 'reset role';
  denied:=false;begin perform mark_password_changed(wid,(issue->>'issuance_id')::uuid,1000);exception when others then denied:=true;end;
  if not denied then raise exception 'unchanged Firebase password cleared gate';end if;
  perform mark_password_changed(wid,(issue->>'issuance_id')::uuid,2000);
  execute 'set local role anon';
  if current_worker_id() is distinct from wid or my_worker_profile()->>'worker_id'<>wid::text then raise exception 'changed password cannot reach own profile';end if;
  execute 'reset role';
  -- Password timestamps are in milliseconds but JWT auth_time is in seconds.
  -- A reset in the same second must reject the old JWT even after the new gate clears.
  old_claims:=auth.jwt();
  update partner_credentials set state='delivered',lock_expires_at=null where worker_id=wid;
  reset_issue:=begin_partner_credential_issue(wid,true);
  perform finish_partner_credential_issue(wid,(reset_issue->>'issuance_id')::uuid,2000000);
  perform mark_password_changed(wid,(reset_issue->>'issuance_id')::uuid,2000001);
  execute 'set local role anon';
  if current_worker_id() is not null or partner_login_state() is not null then raise exception 'pre-reset JWT survived same-second issuance';end if;
  execute 'reset role';
  perform set_config('request.jwt.claims',(old_claims||jsonb_build_object('kaylo_issuance_id',reset_issue->>'issuance_id'))::text,true);
  execute 'set local role anon';
  if current_worker_id() is distinct from wid then raise exception 'new issuance claim cannot reach own profile';end if;
  execute 'reset role';
  -- Same UID through a customer custom token or Google provider cannot log in.
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'firebase',jsonb_build_object('sign_in_provider','custom'))::text,true);
  if current_worker_id() is not null or partner_login_state() is not null then raise exception 'non-password provider can access partner';end if;

  insert into persons(person_id,auth_user_id,full_name) values(cpid,'application_test_customer','Customer');
  perform set_config('request.jwt.claims','{"sub":"application_test_customer"}',true);
  execute 'set local role anon';perform ensure_customer_profile();
  if my_worker_profile() is not null or partner_login_state() is not null then raise exception 'customer can read private worker profile';end if;
  denied:=false;begin perform update_worker_profile('{"bio":"Hijacked"}');exception when others then denied:=true;end;
  if not denied then raise exception 'customer can edit worker profile';end if;
  denied:=false;begin insert into workers(person_id) values(cpid);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'customer can self-insert worker';end if;
  execute 'reset role';
  if not exists(select 1 from person_roles pr join roles r using(role_id) where pr.person_id=cpid and r.role_name='customer') then raise exception 'customer role missing';end if;
  denied:=false;begin insert into person_roles(person_id,role_id) select cpid,role_id from roles where role_name='worker';exception when others then denied:=true;end;
  if not denied then raise exception 'customer acquired worker role';end if;
  a2:=submit_worker_application(details||jsonb_build_object('phone','+919777770002','email','rejected.application@example.invalid','client_request_token',repeat('ef',32)));
  perform reject_worker_application((a2->>'application_id')::uuid,'Not approved');
  denied:=false;begin perform approve_worker_application((a2->>'application_id')::uuid);exception when others then denied:=true;end;
  if not denied then raise exception 'rejected application approved';end if;
  if exists(select 1 from worker_applications where application_id=(a2->>'application_id')::uuid and worker_id is not null) then raise exception 'rejected application has identity';end if;
  raise notice 'worker applications and issued identity checks: ok';
end $$;
rollback;
