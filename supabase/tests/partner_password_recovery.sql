-- Transactional checks against the existing schema. All mutations roll back.
begin;
do $$
declare
  chosen record; result jsonb; other_result jsonb;
  hash text:=repeat('a',64);
begin
  if has_function_privilege('anon','public.claim_partner_password_reset(text,text,text)','execute')
    or has_function_privilege('authenticated','public.claim_partner_password_reset(text,text,text)','execute') then
    raise exception 'Public role can invoke recovery lookup';
  end if;
  if has_table_privilege('anon','public.partner_password_reset_limits','select')
    or has_table_privilege('authenticated','public.partner_password_reset_limits','select') then
    raise exception 'Public role can read reset budgets';
  end if;
  delete from partner_password_reset_limits;
  select w.worker_id,w.partner_id,p.person_id,p.email,c.firebase_uid into chosen
    from workers w join persons p using(person_id) join partner_credentials c using(worker_id)
    where c.state in ('ready','delivered') and p.account_status='active' limit 1;
  if chosen.worker_id is null then raise exception 'No issued fixture available for recovery integration check'; end if;
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result->>'firebase_uid' is distinct from chosen.firebase_uid then raise exception 'Registered email lookup failed'; end if;
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result->>'limited' is distinct from 'true' then raise exception 'Cooldown failed'; end if;
  delete from partner_password_reset_limits;
  result:=claim_partner_password_reset(chosen.partner_id,'not-the-registered-mail@example.invalid',hash);
  if result<>'{}'::jsonb then raise exception 'Mismatched address disclosed an identity'; end if;
  delete from partner_password_reset_limits;
  update partner_credentials set state='failed' where worker_id=chosen.worker_id;
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result<>'{}'::jsonb then raise exception 'Failed issuance was eligible'; end if;
  update partner_credentials set state='delivered' where worker_id=chosen.worker_id;
  delete from partner_password_reset_limits;
  update persons set account_status='suspended' where person_id=chosen.person_id;
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result<>'{}'::jsonb then raise exception 'Suspended account was eligible'; end if;
  delete from partner_password_reset_limits;
  insert into partner_password_reset_limits values('account:'||chosen.partner_id,now(),now()-interval '2 minutes',3);
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result->>'limited' is distinct from 'true' then raise exception 'Hourly account budget failed'; end if;
  delete from partner_password_reset_limits;
  insert into partner_password_reset_limits values('client:'||hash,now(),now()-interval '2 minutes',10);
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result->>'limited' is distinct from 'true' then raise exception 'Client budget failed'; end if;
  delete from partner_password_reset_limits;
  insert into partner_password_reset_limits values('global',now(),now(),100);
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result->>'limited' is distinct from 'true' then raise exception 'Global budget failed'; end if;
  update partner_password_reset_limits set started_at=now()-interval '2 hours';
  result:=claim_partner_password_reset(chosen.partner_id,chosen.email,hash);
  if result ? 'limited' then raise exception 'Expired budget did not reset'; end if;
end $$;
rollback;
