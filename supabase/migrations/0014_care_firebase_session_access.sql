begin;
-- Existing Firebase sessions have a verified subject but no Postgres role
-- claim, so Supabase routes them as anon. Match the person-scoped policies
-- used by Kaylo's other tables; the subject is still verified by the gateway.
-- An unsigned/public request has no person id and cannot match these rules.
alter policy own_invite on care_invite_codes to anon, authenticated;
alter policy own_connection on care_connections to anon, authenticated;
alter policy remove_connection on care_connections to anon, authenticated;
alter policy member_calls on care_calls to anon, authenticated;
alter policy member_list on care_call_members to anon, authenticated;
alter policy read_call_signal on care_call_signals to anon, authenticated;
alter policy send_call_signal on care_call_signals to anon, authenticated;
commit;
