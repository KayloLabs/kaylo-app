-- Payout details leave the public worker row. workers is readable by every
-- signed-in customer (that is how the marketplace lists workers), and until
-- now that included bank_account and upi_id. They move to
-- worker_payout_accounts, which only the worker it belongs to can read or
-- write; the service role (dashboard, payouts) sees everything as usual.
-- Safe to run more than once.
begin;

create table if not exists worker_payout_accounts (
  worker_id uuid primary key references workers (worker_id) on delete cascade,
  bank_account text,
  upi_id text,
  updated_at timestamptz not null default now()
);

-- Carry over anything already stored, then drop the public columns.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'workers'
      and column_name = 'bank_account'
  ) then
    insert into worker_payout_accounts (worker_id, bank_account, upi_id)
      select worker_id, bank_account, upi_id from workers
      where bank_account is not null or upi_id is not null
    on conflict (worker_id) do update
      set bank_account = coalesce(excluded.bank_account, worker_payout_accounts.bank_account),
          upi_id = coalesce(excluded.upi_id, worker_payout_accounts.upi_id),
          updated_at = now();
    alter table workers drop column bank_account, drop column upi_id;
  end if;
end $$;

alter table worker_payout_accounts enable row level security;

drop policy if exists "own payout account" on worker_payout_accounts;
create policy "own payout account" on worker_payout_accounts
  for all
  using (worker_id = current_worker_id())
  with check (worker_id = current_worker_id());

-- Firebase sessions may use anon; the policy still requires the caller to be
-- the worker the row belongs to.
grant select, insert, update, delete on worker_payout_accounts to anon, authenticated;

notify pgrst, 'reload schema';
commit;
