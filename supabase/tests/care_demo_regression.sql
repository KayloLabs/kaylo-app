-- Run in a transaction with ROLLBACK. Uses synthetic accounts only.
do $$
declare
  owner uuid:=gen_random_uuid(); contact uuid:=gen_random_uuid(); stranger uuid:=gen_random_uuid();
  outsider_uid text:='kaylo_test_'||gen_random_uuid();
  uid text:='kaylo_test_'||gen_random_uuid(); cuid text:='kaylo_test_'||gen_random_uuid();
  booking uuid; room uuid; code text; count_rows int; failed boolean;
begin
  insert into persons(person_id,auth_user_id,full_name) values(owner,uid,'Test owner'),(contact,cuid,'Test contact'),(stranger,outsider_uid,'Unrelated test user');
  insert into customers(person_id) values(owner),(contact),(stranger);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','auth_time',extract(epoch from now())::bigint)::text,true);
  booking:=create_care_checkout(gen_random_uuid(),'doctor',jsonb_build_object('provider_id',(select id from doctors where is_active limit 1),'date',(current_date+1)::text,'time','09:00','time_slot','09:00 AM','consultation_type','homeVisit','patient_name','Test patient'));
  if not exists(select 1 from doctor_appointments where booking_id=booking and status='pending') then raise exception 'Unpaid appointment was confirmed'; end if;
  if create_care_checkout(booking,'doctor','{}'::jsonb)<>booking then raise exception 'Retry created another booking'; end if;
  insert into payments(booking_id,amount,payment_method,payment_status) values(booking,500,'test','success');
  if not exists(select 1 from doctor_appointments where booking_id=booking and status='confirmed') then raise exception 'Paid care appointment was not confirmed'; end if;
  update bookings set status='confirmed' where booking_id=booking;
  failed:=false;
  begin perform delete_current_kaylo_account(); exception when others then failed:=true; end;
  if not failed then raise exception 'Account with active booking was deleted'; end if;
  code:=care_invite_code();
  perform set_config('request.jwt.claims',jsonb_build_object('sub',cuid,'role','authenticated','auth_time',extract(epoch from now())::bigint)::text,true);
  perform accept_care_invite(code);
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','auth_time',extract(epoch from now())::bigint)::text,true);
  room:=start_care_call();
  select count(*) into count_rows from care_call_members where call_id=room;
  if count_rows<>2 then raise exception 'Wrong call participants'; end if;
  if start_care_call()<>room then raise exception 'Duplicate SOS call'; end if;
  execute 'set local role authenticated';
  select count(*) into count_rows from care_call_members where call_id=room;
  if count_rows<>2 then raise exception 'Member cannot read their call'; end if;
  perform set_config('request.jwt.claims',jsonb_build_object('sub',outsider_uid,'role','authenticated','auth_time',extract(epoch from now())::bigint)::text,true);
  select count(*) into count_rows from care_call_members where call_id=room;
  if count_rows<>0 then raise exception 'An outsider can read call membership'; end if;
  failed:=false;
  begin
    insert into care_call_signals(call_id,sender_id,target_id,payload) values(room,stranger,owner,'{"type":"offer"}');
  exception when insufficient_privilege then failed:=true; end;
  if not failed then raise exception 'An outsider can inject call signals'; end if;
  execute 'reset role';

  perform set_config('request.jwt.claims',jsonb_build_object('sub',cuid,'role','authenticated','auth_time',extract(epoch from now())::bigint)::text,true);
  perform respond_care_call(room,'joined');
  failed:=false;
  begin perform respond_care_call(room,'end'); exception when others then failed:=true; end;
  if not failed then raise exception 'A contact ended another owner call'; end if;
  perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','auth_time',extract(epoch from now())::bigint)::text,true);
  perform respond_care_call(room,'end');
  update bookings set status='cancelled' where booking_id=booking;
  if not exists(select 1 from doctor_appointments where booking_id=booking and status='cancelled') then raise exception 'Care cancellation was not synchronized'; end if;
  perform delete_current_kaylo_account();
  if exists(select 1 from persons where person_id=owner) or exists(select 1 from doctor_appointments where booking_id=booking) then raise exception 'Account deletion left private records'; end if;
  if not exists(select 1 from persons where person_id=contact) then raise exception 'Account deletion removed another person'; end if;
end $$;
