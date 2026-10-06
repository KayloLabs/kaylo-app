-- Wrap in BEGIN/ROLLBACK. Synthetic users only; no actual invitations or calls.
do $$
declare
 owner uuid:=gen_random_uuid(); contact uuid:=gen_random_uuid(); outsider uuid:=gen_random_uuid();
 owner_uid text:='test_owner_'||gen_random_uuid(); contact_uid text:='test_contact_'||gen_random_uuid();
 outsider_uid text:='test_outsider_'||gen_random_uuid();
 code text; room uuid; db_role text; n integer; denied boolean;
begin
 insert into persons(person_id,auth_user_id,full_name) values
 (owner,owner_uid,'Test owner'),(contact,contact_uid,'Test contact'),(outsider,outsider_uid,'Test outsider');
 perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_uid)::text,true);
 code:=care_invite_code();
 perform set_config('request.jwt.claims',jsonb_build_object('sub',contact_uid)::text,true);
 perform accept_care_invite(code);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_uid)::text,true);
 room:=start_care_call();
 perform set_config('request.jwt.claims',jsonb_build_object('sub',contact_uid)::text,true);
 perform respond_care_call(room,'joined');
 foreach db_role in array array['anon','authenticated'] loop
  execute format('set local role %I',db_role);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',contact_uid)::text,true);
  select count(*) into n from care_connections where owner_id=owner and contact_id=contact;
  if n<>1 then raise exception 'Accepted contact hidden for %',db_role; end if;
  select count(*) into n from care_call_members where call_id=room;
  if n<>2 then raise exception 'Call members hidden for %',db_role; end if;
  insert into care_call_signals(call_id,sender_id,target_id,payload) values(room,contact,owner,'{"type":"test"}');
  perform set_config('request.jwt.claims',jsonb_build_object('sub',owner_uid)::text,true);
  select count(*) into n from care_connections where owner_id=owner;
  if n<>1 then raise exception 'Owner contact hidden for %',db_role; end if;
  select count(*) into n from care_call_signals where call_id=room;
  if n<1 then raise exception 'Call signal hidden for %',db_role; end if;
  perform set_config('request.jwt.claims',jsonb_build_object('sub',outsider_uid)::text,true);
  select count(*) into n from care_connections where owner_id=owner;
  if n<>0 then raise exception 'Unrelated account can read contacts'; end if;
  select count(*) into n from care_calls where id=room;
  if n<>0 then raise exception 'Unrelated account can read call'; end if;
  denied:=false;
  begin
   insert into care_call_signals(call_id,sender_id,target_id,payload) values(room,outsider,owner,'{}');
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Unrelated account can send call signal'; end if;
  perform set_config('request.jwt.claims','{}',true);
  select count(*) into n from care_connections;
  if n<>0 then raise exception 'Unauthenticated request can read contacts'; end if;
  select count(*) into n from care_invite_codes;
  if n<>0 then raise exception 'Unauthenticated request can read invitation codes'; end if;
  select count(*) into n from care_call_members;
  if n<>0 then raise exception 'Unauthenticated request can read call members'; end if;
  denied:=false;
  begin perform accept_care_invite(code); exception when others then denied:=true; end;
  if not denied then raise exception 'Unauthenticated request can accept invite'; end if;
  execute 'reset role';
 end loop;
end $$;
