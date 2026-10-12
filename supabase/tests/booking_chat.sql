-- Database-owner regression test. Real authorization helpers, synthetic rows.
-- Every write, including notification triggers and receipts, rolls back.
begin;
do $$
declare
  customer_person uuid:=gen_random_uuid(); outsider_person uuid:=gen_random_uuid(); worker_person uuid:=gen_random_uuid();
  customer uuid; outsider uuid; worker uuid; svc uuid; booking uuid; pending uuid; room uuid; token uuid:=gen_random_uuid();
  sent_message_id uuid; issue uuid:=gen_random_uuid(); result jsonb; denied boolean; n int;
  worker_claims jsonb; customer_phone_value text:='+919'||lpad((floor(random()*100000000))::bigint::text,8,'0');
begin
  insert into persons(person_id,auth_user_id,full_name,phone_number) values(customer_person,'chat_test_customer','Chat Customer',customer_phone_value),
    (outsider_person,'chat_test_outsider','Chat Outsider',null),(worker_person,'chat_test_worker','Chat Worker',null);
  insert into customers(person_id) values(customer_person) returning customer_id into customer;
  insert into customers(person_id) values(outsider_person) returning customer_id into outsider;
  insert into workers(person_id,partner_id,verification_status,must_change_password)
    values(worker_person,'KP-998877','verified',false) returning worker_id into worker;
  insert into partner_credentials(worker_id,issuance_id,firebase_uid,state,password_updated_at_ms,issued_at)
    values(worker,issue,'chat_test_worker','delivered',1000,now());
  worker_claims:=jsonb_build_object('sub','chat_test_worker','email','kp-998877@partners.kaylo.app','kaylo_role','worker',
    'kaylo_partner_id','KP-998877','kaylo_issuance_id',issue,'auth_time',1000,'firebase',jsonb_build_object('sign_in_provider','password'));
  select service_id into svc from services limit 1;
  if svc is null then raise exception 'Test needs a seeded service';end if;
  insert into bookings(customer_id,worker_id,service_id,booking_date,booking_time,status,worker_stage)
    values(customer,worker,svc,current_date,'10:00','confirmed','accepted') returning booking_id into booking;
  insert into bookings(customer_id,worker_id,service_id,booking_date,booking_time,status,worker_stage)
    values(customer,worker,svc,current_date,'11:00','pending','requested') returning booking_id into pending;
  perform set_config('request.jwt.claims','{"sub":"chat_test_customer"}',true);
  execute 'set local role anon';
  result:=chat_open_booking(booking);room:=(result->>'room_id')::uuid;
  if (result->>'other_person_id')::uuid<>worker_person or not (result->>'can_send')::boolean then raise exception 'Wrong customer thread';end if;
  denied:=false;begin perform chat_open_booking(pending);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Pending booking opened';end if;
  sent_message_id:=chat_send(room,' Hello ',token);
  if chat_send(room,'Hello',token)<>sent_message_id then raise exception 'Retry created duplicate';end if;
  denied:=false;begin perform chat_send(room,'Different',token);exception when invalid_parameter_value then denied:=true;end;
  if not denied then raise exception 'Retry payload mismatch accepted';end if;
  denied:=false;begin perform chat_send(room,'  ',gen_random_uuid());exception when invalid_parameter_value then denied:=true;end;
  if not denied then raise exception 'Empty message accepted';end if;
  denied:=false;begin insert into messages(room_id,sender_id,message) values(room,worker_person,'Spoof');exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Direct sender spoof accepted';end if;
  denied:=false;begin update messages set read_at=now() where room_id=room;exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Sender can forge read receipts';end if;
  perform chat_mark_read_through(room,sent_message_id);
  if exists(select 1 from messages where room_id=room and read_at is not null) then raise exception 'Sender marked own message read';end if;
  perform chat_set_typing(room,true);
  execute 'reset role';
  if (select count(*) from messages where room_id=room)<>1 then raise exception 'Duplicate stored message';end if;
  if not (select expires_at>now() and expires_at<now()+interval '10 seconds' from chat_typing where room_id=room and person_id=customer_person) then raise exception 'Typing expiry invalid';end if;
  perform set_config('request.jwt.claims',worker_claims::text,true);
  execute 'set local role anon';
  if not exists(select 1 from my_partner_jobs() where booking_id=booking and customer_name='Chat Customer') then raise exception 'Live assigned-job projection missing';end if;
  if (select customer_phone from my_partner_jobs() where booking_id=booking) is distinct from customer_phone_value then raise exception 'Active job hides the customer phone';end if;
  if (select customer_phone from my_partner_jobs() where booking_id=pending) is not null then raise exception 'Requested job exposes the customer phone';end if;
  select count(*) into n from notifications where person_id=worker_person;
  perform worker_advance_booking(booking,'on_the_way');
  if (select count(*) from notifications where person_id=worker_person)<>n then raise exception 'Worker alerted about own stage change';end if;
  execute 'reset role';
  perform set_config('request.jwt.claims','{"sub":"chat_test_customer"}',true);
  update bookings set status='cancelled',worker_stage='cancelled' where booking_id=pending;
  if (select count(*) from notifications where person_id=worker_person and title='Booking cancelled')<>1 then raise exception 'Worker missed a customer cancellation';end if;
  perform set_config('request.jwt.claims',worker_claims::text,true);
  execute 'set local role anon';
  if (select customer_phone from my_partner_jobs() where booking_id=pending) is not null then raise exception 'Finished job exposes the customer phone';end if;
  select to_jsonb(t) into result from chat_threads() t where t.room_id=room;
  if result->>'last_message'<>'Hello' or (result->>'unread_count')::int<>1 or (result->>'other_person_id')::uuid<>customer_person then raise exception 'Worker aggregate incorrect';end if;
  perform chat_mark_read_through(room,sent_message_id);
  if (select unread_count from chat_threads() t where t.room_id=room)<>0 then raise exception 'Unread count not cleared';end if;
  if (select read_at from messages m where m.message_id=sent_message_id) is null then raise exception 'Read receipt missing';end if;
  -- A later arrival must remain unread when acknowledging an older snapshot.
  execute 'reset role';
  insert into messages(room_id,sender_id,message,sent_at) values
    (room,customer_person,'Later unseen message',clock_timestamp()+interval '1 second'),
    (room,worker_person,'Own message',clock_timestamp()+interval '2 seconds');
  execute 'set local role anon';
  perform chat_mark_read_through(room,sent_message_id);
  if exists(select 1 from messages where room_id=room and message_id<>sent_message_id and read_at is not null)
    then raise exception 'Acknowledged unseen or own message';end if;
  denied:=false;begin perform chat_mark_read_through(room,gen_random_uuid());exception when invalid_parameter_value then denied:=true;end;
  if not denied then raise exception 'Invalid receipt boundary accepted';end if;
  execute 'reset role';
  delete from messages where room_id=room and message_id<>sent_message_id;
  execute 'set local role anon';
  perform set_partner_notification_preferences(false,false,false);
  denied:=false;begin update notifications set title='Tampered' where person_id=worker_person;exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Notification contents editable';end if;
  execute 'reset role';
  select count(*) into n from notifications where person_id=worker_person;
  insert into notifications(person_id,title,type) values(worker_person,'Suppressed request','request'),(worker_person,'Suppressed job','job'),(worker_person,'Suppressed payout','payout');
  if (select count(*) from notifications where person_id=worker_person)<>n then raise exception 'Disabled notifications created';end if;
  insert into notifications(person_id,title,type) values(worker_person,'System alert','system');
  perform set_config('request.jwt.claims','{"sub":"chat_test_outsider"}',true);
  execute 'set local role anon';
  if exists(select 1 from messages where room_id=room) or exists(select 1 from chat_rooms where room_id=room) or exists(select 1 from chat_typing where room_id=room) then raise exception 'Nonmember reads chat data';end if;
  if exists(select 1 from chat_threads()) then raise exception 'Nonmember aggregate leaks threads';end if;
  if exists(select 1 from my_partner_jobs()) or exists(select 1 from my_worker_reviews()) then raise exception 'Nonworker received private projections';end if;
  denied:=false;begin perform chat_send(room,'Intrusion',gen_random_uuid());exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Nonmember sent message';end if;
  denied:=false;begin perform chat_mark_read_through(room,sent_message_id);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Nonmember changed receipts';end if;
  denied:=false;begin perform chat_set_typing(room,true);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Nonmember changed typing';end if;
  perform mark_my_notifications_read(null);
  execute 'reset role';
  if not exists(select 1 from notifications where person_id=worker_person and not is_read) then raise exception 'Outsider marked worker notifications';end if;
  update bookings set status='completed',worker_stage='completed' where booking_id=booking;
  if exists(select 1 from chat_typing where room_id=room and expires_at>clock_timestamp()) then raise exception 'Completed room retained typing';end if;
  insert into reviews(booking_id,customer_id,worker_id,rating,review) values(booking,customer,worker,5,'Helpful');
  perform set_config('request.jwt.claims','{}',true);
  execute 'set local role anon';
  if exists(select 1 from chat_threads()) or exists(select 1 from messages where room_id=room) then raise exception 'Unsigned caller reads chat';end if;
  execute 'reset role';
  perform set_config('request.jwt.claims',worker_claims::text,true);
  execute 'set local role anon';
  if not exists(select 1 from my_worker_reviews() where booking_id=booking and customer_name='Chat Customer' and rating=5) then raise exception 'Worker review projection missing';end if;
  if (chat_open_booking(booking)->>'can_send')::boolean then raise exception 'Completed chat writable';end if;
  denied:=false;begin perform chat_send(room,'Too late',gen_random_uuid());exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Completed booking accepted message';end if;
  denied:=false;begin perform chat_set_typing(room,true);exception when insufficient_privilege then denied:=true;end;
  if not denied then raise exception 'Completed booking accepted typing';end if;
  if (select count(*) from messages where room_id=room)<>1 then raise exception 'Completed history missing';end if;
  perform mark_my_notifications_read(null);
  if exists(select 1 from notifications where person_id=worker_person and not is_read) then raise exception 'Own notifications not marked';end if;
  execute 'reset role';
end $$;
rollback;
