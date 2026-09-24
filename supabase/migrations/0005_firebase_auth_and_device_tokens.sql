-- ============================================================
-- Kaylo — Firebase Authentication and push tokens
--
-- Sign-in moves to Firebase Authentication (phone OTP). Supabase keeps
-- the data: it accepts the Firebase ID token as a third-party JWT
-- (Authentication -> Third-Party Auth -> Firebase in the dashboard), so
-- every policy keeps working, with one change: Firebase user ids are
-- not UUIDs, so persons.auth_user_id becomes text and the helpers read
-- the token subject instead of auth.uid().
--
-- device_tokens holds each signed-in device's Firebase Cloud Messaging
-- token so booking updates can be pushed to customers and workers.
-- ============================================================

-- ---------- persons.auth_user_id: Supabase uuid -> Firebase uid ----------

alter table persons drop constraint if exists persons_auth_user_id_fkey;
alter table persons alter column auth_user_id type text using auth_user_id::text;

-- The subject of the verified JWT: a Firebase uid after this migration,
-- and still equal to auth.uid() for any Supabase-issued token.
create or replace function current_auth_subject()
returns text
language sql stable as $$
  select nullif(auth.jwt() ->> 'sub', '');
$$;

create or replace function current_person_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select person_id from persons where auth_user_id = current_auth_subject();
$$;

create or replace function current_customer_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select c.customer_id from customers c
  join persons p on p.person_id = c.person_id
  where p.auth_user_id = current_auth_subject();
$$;

create or replace function current_worker_id()
returns uuid
language sql stable security definer set search_path = public as $$
  select w.worker_id from workers w
  join persons p on p.person_id = w.person_id
  where p.auth_user_id = current_auth_subject();
$$;

drop policy if exists "self insert" on persons;
create policy "self insert" on persons for insert
  with check (auth_user_id = current_auth_subject());

-- ---------- push notification tokens ----------

create table device_tokens (
  token_id uuid primary key default gen_random_uuid(),
  person_id uuid not null references persons (person_id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web')),
  app text not null check (app in ('customer', 'partner')),
  updated_at timestamptz not null default now()
);

create index device_tokens_person_idx on device_tokens (person_id);

alter table device_tokens enable row level security;

create policy "own device tokens" on device_tokens for all
  using (person_id = current_person_id())
  with check (person_id = current_person_id());
