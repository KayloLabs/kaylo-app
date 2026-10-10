-- Notification delivery state only. Synthetic rows, no SMTP or external calls.
-- Owns its transaction and rolls back; run after 0026 as the database owner.
begin;
do $$
declare aid uuid:=gen_random_uuid(); result jsonb; claim1 uuid; claim2 uuid; claim3 uuid;
  doc text; path text; denied boolean;
begin
  if has_function_privilege('anon','claim_worker_application_notification(uuid)','EXECUTE')
    or has_function_privilege('authenticated','claim_worker_application_notification(uuid)','EXECUTE')
    or has_function_privilege('anon','finish_worker_application_notification(uuid,uuid,boolean)','EXECUTE')
    or has_function_privilege('authenticated','finish_worker_application_notification(uuid,uuid,boolean)','EXECUTE') then
    raise exception 'Client can claim or acknowledge admin email delivery'; end if;
  if not has_function_privilege('service_role','claim_worker_application_notification(uuid)','EXECUTE')
    or not has_function_privilege('service_role','finish_worker_application_notification(uuid,uuid,boolean)','EXECUTE') then
    raise exception 'Service role cannot deliver admin notifications'; end if;
  execute 'set local role anon';
  denied:=false;begin perform claim_worker_application_notification(aid);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Anonymous notification claim succeeded';end if;
  execute 'reset role';
  if claim_worker_application_notification(aid)->>'state' is distinct from 'not_required' then raise exception 'Missing application was claimed';end if;
  insert into worker_applications(application_id,phone,details,upload_token_hash)
    values(aid,'+919777771001','{}',repeat('a',64));
  if claim_worker_application_notification(aid)->>'state' is distinct from 'not_required' then raise exception 'Incomplete submitted application was claimed';end if;
  update worker_applications set status='under_review' where application_id=aid;
  if claim_worker_application_notification(aid)->>'state' is distinct from 'not_required' then raise exception 'Status alone bypassed document requirement';end if;
  foreach doc in array array['photo','aadhaar_front','aadhaar_back','police_certificate','selfie'] loop
    path:='applications/'||aid::text||'/'||doc||'/'||gen_random_uuid()||'.jpg';
    insert into storage.objects(bucket_id,name) values('worker-documents',path);
    insert into worker_application_documents(application_id,doc_type,storage_path,content_type,byte_size)
      values(aid,doc,path,'image/jpeg',100);
  end loop;
  -- A database document row without the underlying private object is incomplete.
  delete from storage.objects where bucket_id='worker-documents' and name=path;
  if claim_worker_application_notification(aid)->>'state' is distinct from 'not_required' then raise exception 'Missing storage object was ignored';end if;
  insert into storage.objects(bucket_id,name) values('worker-documents',path);
  result:=claim_worker_application_notification(aid);claim1:=(result->>'claim_id')::uuid;
  if result->>'state' is distinct from 'claimed' or claim1 is null or result->>'reference' is null then raise exception 'Complete application was not claimed';end if;
  if (select admin_notification_lease_until from worker_applications where application_id=aid) is distinct from now()+interval '5 minutes' then raise exception 'Wrong lease duration';end if;
  -- A competing invocation observes the lock-protected active lease.
  if claim_worker_application_notification(aid)->>'state' is distinct from 'busy' then raise exception 'Concurrent sender was not fenced';end if;
  if finish_worker_application_notification(aid,gen_random_uuid(),true) then raise exception 'Wrong claim acknowledged';end if;
  if not finish_worker_application_notification(aid,claim1,false) then raise exception 'Failed send lease was not released';end if;
  if (select admin_notified_at is not null or admin_notification_claim is not null or admin_notification_lease_until is not null from worker_applications where application_id=aid) then raise exception 'Failed send marked sent or retained lease';end if;
  result:=claim_worker_application_notification(aid);claim2:=(result->>'claim_id')::uuid;
  if result->>'state' is distinct from 'claimed' or claim2 is null or claim2=claim1 then raise exception 'Failed send cannot retry with a fresh claim';end if;
  update worker_applications set admin_notification_lease_until=now()-interval '1 second' where application_id=aid;
  result:=claim_worker_application_notification(aid);claim3:=(result->>'claim_id')::uuid;
  if result->>'state' is distinct from 'claimed' or claim3 is null or claim3=claim2 then raise exception 'Expired sender lease could not recover';end if;
  if finish_worker_application_notification(aid,claim2,true) or finish_worker_application_notification(aid,claim1,false) then raise exception 'Stale sender changed current delivery state';end if;
  if (select admin_notification_claim from worker_applications where application_id=aid) is distinct from claim3 then raise exception 'Stale acknowledgement removed current claim';end if;
  if not finish_worker_application_notification(aid,claim3,true) then raise exception 'Successful send was not acknowledged';end if;
  if (select admin_notified_at from worker_applications where application_id=aid) is null then raise exception 'Sent timestamp missing';end if;
  if claim_worker_application_notification(aid)->>'state' is distinct from 'sent' then raise exception 'Sent notification was not deduplicated';end if;
  if finish_worker_application_notification(aid,claim3,false) then raise exception 'Old failure cleared a successful send';end if;
  -- Completed review no longer needs a new-review notification.
  update worker_applications set admin_notified_at=null,status='approved' where application_id=aid;
  if claim_worker_application_notification(aid)->>'state' is distinct from 'not_required' then raise exception 'Already approved application was claimed';end if;
  update worker_applications set status='rejected' where application_id=aid;
  if claim_worker_application_notification(aid)->>'state' is distinct from 'not_required' then raise exception 'Rejected application was claimed';end if;
  raise notice 'worker application notification delivery leases: ok';
end $$;
rollback;
