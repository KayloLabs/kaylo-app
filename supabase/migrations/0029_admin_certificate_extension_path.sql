-- Supabase installs pgcrypto in extensions. Approval needs gen_random_bytes
-- when assigning a certificate number; public alone cannot resolve it.
begin;
alter function public.admin_review_application(text,uuid,integer,text,text,text[])
  set search_path = public, extensions;
commit;
