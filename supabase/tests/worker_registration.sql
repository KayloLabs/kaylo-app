-- After 0025, self-registration is deliberately retired. Application coverage
-- lives in worker_applications.sql. This test prevents reopening the old path.
begin;
do $$
begin
  if has_function_privilege('anon','register_worker(jsonb)','EXECUTE')
    or has_function_privilege('authenticated','register_worker(jsonb)','EXECUTE') then
    raise exception 'Legacy self-registration is still publicly executable';
  end if;
  if has_table_privilege('anon','workers','INSERT')
    or has_table_privilege('authenticated','workers','UPDATE') then
    raise exception 'Client can create or verify a worker directly';
  end if;
  if has_function_privilege('anon','review_worker(uuid,text,text)','EXECUTE')
    or has_function_privilege('authenticated','review_worker_document(uuid,text,text)','EXECUTE') then
    raise exception 'Client can approve verification';
  end if;
  raise notice 'legacy worker self-registration closed: ok';
end $$;
rollback;
