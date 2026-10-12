-- Admin review, evidence versions, correction capabilities and mail delivery.
-- Synthetic records only, no email or Firebase calls. Owns and rolls back its transaction.
begin;
-- Match Supabase even when the local harness installed pgcrypto in public.
-- Relocation and its test data are rolled back with this test transaction.
create schema if not exists extensions;
do $$
begin
  if exists(select 1 from pg_extension e join pg_namespace n on n.oid=e.extnamespace
    where e.extname='pgcrypto' and n.nspname<>'extensions') then
    alter extension pgcrypto set schema extensions;
  end if;
end $$;
set local search_path=public,extensions;
create function pg_temp.admin_test_application(p_phone text,p_email text)
returns uuid language plpgsql as $$
declare aid uuid; svc uuid; doc text; path text;
begin
  select service_id into svc from services where is_active limit 1;
  insert into worker_applications(phone,details,upload_token_hash) values(p_phone,
    jsonb_build_object('full_name','Admin Review Test','email',p_email,'phone',p_phone,'profession','Plumber',
      'services',jsonb_build_array(svc),'experience_years',4,'district','Kannur','travel_radius_km',10,
      'upi_id','adminreview@bank','consent',true),repeat('a',64)) returning application_id into aid;
  foreach doc in array array['photo','aadhaar_front','aadhaar_back','police_certificate','selfie'] loop
    path:='applications/'||aid||'/'||doc||'/'||gen_random_uuid()||'.jpg';
    insert into storage.objects(bucket_id,name) values('worker-documents',path);
    insert into worker_application_documents(application_id,doc_type,storage_path,content_type,byte_size)
      values(aid,doc,path,'image/jpeg',100);
  end loop;
  update worker_applications set status='under_review' where application_id=aid;
  return aid;
end $$;
do $$
declare aid uuid; aid2 uuid; aid3 uuid; v integer; batch integer; previous_batch integer; result jsonb; info jsonb; mail jsonb;
  cert uuid; wid uuid; path text; old_path text; denied boolean; mid uuid; claim1 uuid; claim2 uuid; doc text;
  all_docs text[]:=array['aadhaar_front','aadhaar_back','photo','police_certificate','selfie'];
begin
  insert into admin_users(firebase_uid,email,role,is_active) values
    ('admin_review_test','admin.review@example.invalid','admin',true),
    ('reviewer_test','reviewer@example.invalid','reviewer',true),
    ('inactive_admin_test','inactive@example.invalid','admin',false);
  aid:=pg_temp.admin_test_application('+919700010001','admin.review.applicant@example.invalid');
  select version into v from worker_applications where application_id=aid;
  if v<=1 then raise exception 'Initial uploads did not advance evidence version';end if;
  if (select count(*) from worker_application_document_history where application_id=aid)<>5 then raise exception 'Initial evidence history missing';end if;
  if (select count(*) from application_mail_outbox where application_id=aid and kind='submitted')<>1 then raise exception 'Complete application was not queued once';end if;
  denied:=false;begin perform admin_application_list('unknown_actor');exception when others then
    if sqlerrm='ADMIN_ACCESS_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Unknown admin can list private applications';end if;
  denied:=false;begin perform admin_application_detail('inactive_admin_test',aid);exception when others then
    if sqlerrm='ADMIN_ACCESS_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Inactive admin can inspect PII';end if;
  if jsonb_array_length(admin_application_list('reviewer_test',null,1,25,'Admin Review Test')->'applications')<1 then raise exception 'Reviewer search failed';end if;
  info:=admin_application_detail('reviewer_test',aid);
  if info->'application' ? 'upload_token_hash' or info->'application' ? 'upload_token' then raise exception 'Admin detail exposed a bearer secret';end if;
  if jsonb_array_length(info->'documents')<>5 or jsonb_array_length(info->'audit')<5 then raise exception 'Review detail incomplete';end if;
  execute 'set local role anon';
  denied:=false;begin perform admin_application_detail('admin_review_test',aid);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Anonymous actor UID spoofing succeeded';end if;
  denied:=false;begin perform get_application_for_correction(aid,v);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Anonymous correction RPC bypassed signed link';end if;
  denied:=false;begin perform 1 from admin_users;exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Admin registry public';end if;
  execute 'reset role';
  denied:=false;begin perform admin_review_application('reviewer_test',aid,v,'approve',null,all_docs);exception when others then
    if sqlerrm='ADMIN_DECISION_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Reviewer approved an application';end if;
  denied:=false;begin perform admin_review_application('reviewer_test',aid,v,'reject','Reason');exception when others then
    if sqlerrm='ADMIN_DECISION_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Reviewer rejected an application';end if;
  denied:=false;begin perform admin_review_application('admin_review_test',aid,v,'approve',null,array['photo']);exception when others then
    if sqlerrm='ALL_DOCUMENT_CHECKS_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Approval skipped actual document checklist';end if;
  -- A file changed after the admin opened its preview: the old decision must fail.
  select storage_path into old_path from worker_application_documents where application_id=aid and doc_type='photo';
  path:='applications/'||aid||'/photo/'||gen_random_uuid()||'.jpg';
  insert into storage.objects(bucket_id,name) values('worker-documents',path);
  update worker_application_documents set storage_path=path where application_id=aid and doc_type='photo';
  denied:=false;begin perform admin_review_application('admin_review_test',aid,v,'approve',null,all_docs);exception when others then
    if sqlerrm='APPLICATION_VERSION_CONFLICT' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Stale evidence preview was approved';end if;
  if not exists(select 1 from worker_application_document_history where application_id=aid and storage_path=old_path)
    or not exists(select 1 from storage.objects where bucket_id='worker-documents' and name=old_path) then raise exception 'Replaced evidence was lost';end if;
  select version into v from worker_applications where application_id=aid;
  result:=admin_review_application('reviewer_test',aid,v,'request_changes','Please provide clearer images.',array['aadhaar_front','selfie']);
  batch:=(result->>'correction_version')::integer;
  if result->>'status'<>'changes_requested' or batch is null then raise exception 'Correction request missing';end if;
  if (select upload_expires_at>now() from worker_applications where application_id=aid) then raise exception 'Original upload capability survived review';end if;
  info:=get_application_for_correction(aid,batch);
  if jsonb_array_length(info->'requested_documents')<>2 or info ? 'details' then raise exception 'Correction capability exposed or omitted fields';end if;
  select mail_id into mid from application_mail_outbox where application_id=aid and kind='submitted';
  if claim_application_mail(mid) is not null then raise exception 'Obsolete initial review email was claimed';end if;
  select mail_id into mid from application_mail_outbox where application_id=aid and kind='changes_requested';
  mail:=claim_application_mail(mid);claim1:=(mail->>'claim_id')::uuid;
  if mail->>'kind'<>'changes_requested' or claim1 is null then raise exception 'Correction mail was not claimable';end if;
  if claim_application_mail(mid) is not null then raise exception 'Active mail lease allowed another sender';end if;
  if not finish_application_mail(mid,claim1,false,'SMTP_UNAVAILABLE') then raise exception 'Mail failure not recorded';end if;
  if (select status from application_mail_outbox where mail_id=mid)<>'failed' then raise exception 'Mail failure status incorrect';end if;
  mail:=claim_application_mail(mid);claim2:=(mail->>'claim_id')::uuid;
  if claim2=claim1 or (mail->>'attempts')::int<>2 then raise exception 'Mail retry was not a new attempt';end if;
  if finish_application_mail(mid,claim1,true) then raise exception 'Stale mail sender acknowledged current attempt';end if;
  update application_mail_outbox set lease_until=now()-interval '1 second' where mail_id=mid;
  mail:=claim_application_mail(mid);claim1:=(mail->>'claim_id')::uuid;
  if claim1=claim2 or (mail->>'attempts')::int<>3 then raise exception 'Expired mail lease did not recover';end if;
  if not finish_application_mail(mid,claim1,true) or claim_application_mail(mid) is not null then raise exception 'Successful mail was not deduplicated';end if;
  denied:=false;begin perform record_application_correction(aid,batch,'photo','irrelevant','image/jpeg',100);exception when others then
    if sqlerrm='DOCUMENT_NOT_REQUESTED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Correction link can replace an unrequested document';end if;
  denied:=false;begin perform get_application_for_correction(aid,batch-1);exception when others then
    if sqlerrm='CORRECTION_LINK_INVALID' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Wrong correction request version accepted';end if;
  update worker_applications set correction_expires_at=now()-interval '1 second' where application_id=aid;
  denied:=false;begin perform get_application_for_correction(aid,batch);exception when others then
    if sqlerrm='CORRECTION_LINK_EXPIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Expired correction capability accepted';end if;
  -- Renew an expired request through the same admin flow; its old link stays fenced.
  previous_batch:=batch;
  select version into v from worker_applications where application_id=aid;
  result:=admin_review_application('reviewer_test',aid,v,'request_changes','Please use this renewed request.',array['aadhaar_front','selfie']);
  batch:=(result->>'correction_version')::integer;
  if batch<=previous_batch then raise exception 'Renewal reused an old correction capability';end if;
  if (select correction_expires_at<=now() from worker_applications where application_id=aid) then raise exception 'Renewal remained expired';end if;
  denied:=false;begin perform get_application_for_correction(aid,previous_batch);exception when others then
    if sqlerrm='CORRECTION_LINK_INVALID' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Old correction link survived request renewal';end if;
  denied:=false;begin perform record_application_correction(aid,previous_batch,'selfie','irrelevant','image/jpeg',100);exception when others then
    if sqlerrm='CORRECTION_NOT_ALLOWED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Old correction link can upload after request renewal';end if;
  if not exists(select 1 from application_mail_outbox where application_id=aid and kind='changes_requested' and application_version=batch and status='pending') then raise exception 'Renewal did not queue a fresh correction email';end if;
  foreach doc in array array['aadhaar_front','selfie'] loop
    path:='applications/'||aid||'/corrections/'||batch||'/'||doc||'/'||gen_random_uuid()||'.jpg';
    insert into storage.objects(bucket_id,name) values('worker-documents',path);
    result:=record_application_correction(aid,batch,doc,path,'image/jpeg',120);
    if (result->>'version')::int<>batch then raise exception 'Correction link changed before batch completion';end if;
  end loop;
  if result->>'status'<>'under_review' or (result->>'completed')::boolean is not true then raise exception 'Correction batch did not return to review';end if;
  select version into v from worker_applications where application_id=aid;
  if v<=batch+1 then raise exception 'Correction evidence did not increment application version';end if;
  if (select count(*) from application_mail_outbox where application_id=aid and kind='submitted')<>2 then raise exception 'Corrected application did not queue a fresh admin review alert';end if;
  result:=admin_review_application('admin_review_test',aid,v,'approve','Reviewed all five supplied documents.',all_docs);
  cert:=(result->>'certificate_id')::uuid;wid:=(result->>'worker_id')::uuid;
  if cert is null or wid is null then raise exception 'Approval did not create worker and certificate';end if;
  if (select cardinality(checked_document_types) from partner_certificates where certificate_id=cert)<>5 then raise exception 'Certificate lost review scope';end if;
  info:=admin_application_certificate('reviewer_test',aid);
  if info->'snapshot' ? 'bank_account' or info->'snapshot' ? 'email' or info->'snapshot' ? 'storage_path' then raise exception 'Certificate exposed applicant private data';end if;
  if info->'snapshot'->>'full_name'<>'Admin Review Test' then raise exception 'Certificate snapshot wrong';end if;
  if not exists(select 1 from worker_application_audit where application_id=aid and action='approve' and actor_uid='admin_review_test' and actor_role='admin') then raise exception 'Admin decision is not attributed';end if;
  denied:=false;begin perform admin_review_application('admin_review_test',aid,v,'approve',null,all_docs);exception when others then denied:=true;end;
  if not denied or (select count(*) from partner_certificates where application_id=aid)<>1 then raise exception 'Duplicate approval created a second certificate';end if;
  denied:=false;begin update partner_certificates set snapshot='{}' where certificate_id=cert;exception when others then
    if sqlerrm='IMMUTABLE_APPLICATION_RECORD' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Certificate snapshot mutable';end if;
  denied:=false;begin delete from worker_application_audit where application_id=aid;exception when others then
    if sqlerrm='IMMUTABLE_APPLICATION_RECORD' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Audit history mutable';end if;
  denied:=false;begin update worker_application_document_history set byte_size=0 where application_id=aid;exception when others then
    if sqlerrm='IMMUTABLE_APPLICATION_RECORD' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Document history mutable';end if;
  if has_table_privilege('service_role','worker_application_audit','TRUNCATE')
    or has_table_privilege('service_role','worker_application_document_history','TRUNCATE')
    or has_table_privilege('service_role','partner_certificates','TRUNCATE') then raise exception 'Service role may truncate immutable records';end if;
  aid2:=pg_temp.admin_test_application('+919700010002','admin.reject.applicant@example.invalid');
  select version into v from worker_applications where application_id=aid2;
  denied:=false;begin perform admin_review_application('admin_review_test',aid2,v,'reject','  ');exception when others then
    if sqlerrm='REVIEW_REASON_REQUIRED' then denied:=true;else raise;end if;end;
  if not denied then raise exception 'Reasonless rejection accepted';end if;
  result:=admin_review_application('admin_review_test',aid2,v,'reject','Application cannot be approved.');
  if result->>'status'<>'rejected' or admin_application_certificate('admin_review_test',aid2) is not null then raise exception 'Rejection created an identity or certificate';end if;
  if not exists(select 1 from application_mail_outbox where application_id=aid2 and kind='rejected') then raise exception 'Rejection notice missing';end if;
  aid3:=pg_temp.admin_test_application('+919700010003','admin.compat.applicant@example.invalid');
  update worker_applications set admin_notified_at=now() where application_id=aid3;
  select mail_id into mid from application_mail_outbox where application_id=aid3 and kind='submitted';
  if (select status from application_mail_outbox where mail_id=mid)<>'sent' or claim_application_mail(mid) is not null then raise exception 'Legacy sender acknowledgement did not deduplicate outbox';end if;
  raise notice 'partner admin review, corrections, certificates and outbox: ok';
end $$;
rollback;
