-- Self-service recovery for issued partner identities. No reset tokens stored.
begin;
create table if not exists public.partner_password_reset_limits (
  bucket text primary key,
  started_at timestamptz not null,
  last_attempt_at timestamptz not null,
  attempts integer not null check (attempts > 0)
);
create index if not exists partner_password_reset_limits_expiry
  on public.partner_password_reset_limits(started_at);
alter table public.partner_password_reset_limits enable row level security;
revoke all on public.partner_password_reset_limits from public, anon, authenticated;
grant all on public.partner_password_reset_limits to service_role;

create or replace function public.claim_partner_password_reset(
  p_partner_id text, p_email text, p_client_hash text
) returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  k text; b partner_password_reset_limits; result jsonb;
  now_at timestamptz := clock_timestamp();
  keys text[] := array['account:' || p_partner_id, 'client:' || p_client_hash, 'global'];
  cap integer;
begin
  if p_partner_id !~ '^KP-[0-9]{6}$' or p_partner_id is null
    or p_client_hash !~ '^[a-f0-9]{64}$' or p_client_hash is null
    or p_email is null or length(p_email)>254 then
    raise exception 'INVALID_REQUEST';
  end if;
  -- Take locks in a stable order so simultaneous requests share the same budget.
  foreach k in array keys loop
    perform pg_advisory_xact_lock(hashtextextended('partner-reset:' || k, 0));
  end loop;
  foreach k in array keys loop
    select * into b from partner_password_reset_limits where bucket=k;
    cap := case when k='global' then 100 when k like 'client:%' then 10 else 3 end;
    if found and b.started_at > now_at - interval '1 hour' and
      (b.attempts >= cap or (k like 'account:%' and b.last_attempt_at > now_at - interval '60 seconds')) then
      return jsonb_build_object('limited',true);
    end if;
  end loop;
  foreach k in array keys loop
    insert into partner_password_reset_limits(bucket,started_at,last_attempt_at,attempts)
    values(k,now_at,now_at,1)
    on conflict(bucket) do update set
      attempts=case when partner_password_reset_limits.started_at <= now_at-interval '1 hour' then 1 else partner_password_reset_limits.attempts+1 end,
      started_at=case when partner_password_reset_limits.started_at <= now_at-interval '1 hour' then now_at else partner_password_reset_limits.started_at end,
      last_attempt_at=now_at;
  end loop;
  delete from partner_password_reset_limits where started_at < now_at-interval '1 day';
  select jsonb_build_object('firebase_uid',c.firebase_uid,'issuance_id',c.issuance_id,
    'partner_id',w.partner_id,'email',p.email)
  into result
  from workers w join persons p on p.person_id=w.person_id
    join partner_credentials c on c.worker_id=w.worker_id
  where w.partner_id=p_partner_id and lower(trim(p.email))=lower(trim(p_email))
    and p.account_status='active' and c.state in ('ready','delivered');
  return coalesce(result,'{}'::jsonb);
end;
$$;
revoke all on function public.claim_partner_password_reset(text,text,text) from public,anon,authenticated;
grant execute on function public.claim_partner_password_reset(text,text,text) to service_role;
notify pgrst, 'reload schema';
commit;
