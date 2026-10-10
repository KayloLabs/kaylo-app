-- A small durable delivery lease for completed partner application emails.
-- Run after 0025. Safe to rerun. No applicant secrets enter notification state.
begin;
alter table worker_applications add column if not exists admin_notified_at timestamptz;
alter table worker_applications add column if not exists admin_notification_claim uuid;
alter table worker_applications add column if not exists admin_notification_lease_until timestamptz;

create or replace function claim_worker_application_notification(p_application_id uuid)
returns jsonb language plpgsql security definer set search_path=public as $$
declare a worker_applications; claim uuid;
begin
  select * into a from worker_applications where application_id=p_application_id for update;
  if not found then return jsonb_build_object('state','not_required'); end if;
  if a.admin_notified_at is not null then return jsonb_build_object('state','sent'); end if;
  if a.status<>'under_review' or (select count(*) from worker_application_documents d
    join storage.objects o on o.bucket_id='worker-documents' and o.name=d.storage_path
    where d.application_id=p_application_id)<>5 then
    return jsonb_build_object('state','not_required'); end if;
  if a.admin_notification_claim is not null and a.admin_notification_lease_until>now() then
    return jsonb_build_object('state','busy'); end if;
  claim:=gen_random_uuid();
  update worker_applications set admin_notification_claim=claim,
    admin_notification_lease_until=now()+interval '5 minutes'
    where application_id=p_application_id;
  return jsonb_build_object('state','claimed','claim_id',claim,'reference',a.reference);
end $$;

create or replace function finish_worker_application_notification(
  p_application_id uuid,p_claim_id uuid,p_sent boolean)
returns boolean language plpgsql security definer set search_path=public as $$
begin
  -- The claim ID fences off a slow sender after another retry took its lease.
  update worker_applications set
    admin_notified_at=case when p_sent is true then now() else admin_notified_at end,
    admin_notification_claim=null,admin_notification_lease_until=null
    where application_id=p_application_id and admin_notification_claim=p_claim_id
      and p_claim_id is not null;
  return found;
end $$;
revoke all on function claim_worker_application_notification(uuid),
  finish_worker_application_notification(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function claim_worker_application_notification(uuid),
  finish_worker_application_notification(uuid,uuid,boolean) to service_role;

notify pgrst, 'reload schema';
commit;
