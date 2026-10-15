begin;
create function pg_temp.use_issued_worker_fixture()
returns void language plpgsql security definer set search_path=public as $$
declare w workers; uid text:=current_auth_subject(); claims jsonb:=auth.jwt();
begin
  select wk.* into w from workers wk join persons p using(person_id) where p.auth_user_id=uid;
  if not found then return;end if;
  if w.partner_id is null then
    update workers set partner_id='KP-'||lpad(nextval('kaylo_partner_id_seq')::text,6,'0')
      where worker_id=w.worker_id returning * into w;
  end if;
  update workers set must_change_password=false,verification_status='verified' where worker_id=w.worker_id;
  insert into partner_credentials(worker_id,issuance_id,firebase_uid,state,password_updated_at_ms,issued_at)
    values(w.worker_id,gen_random_uuid(),uid,'delivered',1,now()) on conflict(worker_id) do nothing;
  perform set_config('request.jwt.claims',(claims||jsonb_build_object('auth_time',extract(epoch from now())::bigint,
    'kaylo_role','worker','kaylo_partner_id',w.partner_id,
    'kaylo_issuance_id',(select issuance_id from partner_credentials where worker_id=w.worker_id),'firebase',jsonb_build_object('sign_in_provider','password')))::text,true);
end $$;

do $$
declare
 pc uuid:=gen_random_uuid();pw uuid:=gen_random_uuid();px uuid:=gen_random_uuid();
 c uuid:=gen_random_uuid();w uuid:=gen_random_uuid();svc uuid:=gen_random_uuid();b uuid:=gen_random_uuid();
 uc text:='privacy_c_'||pc;uw text:='privacy_w_'||pw;ux text:='privacy_x_'||px;
 worker_claims text;cid uuid; result jsonb;blocked boolean:=false;
begin
 insert into persons(person_id,auth_user_id,full_name) values(pc,uc,'Private reviewer'),(pw,uw,'Test partner'),(px,ux,'Outsider');
 insert into customers(customer_id,person_id) values(c,pc);
 insert into workers(worker_id,person_id,is_available,is_verified,verification_status) values(w,pw,true,true,'verified');
 insert into services(service_id,category_id,service_name,base_price) select svc,category_id,'Contact test '||svc,100 from service_categories where slug='home';
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uw)::text,true);
 perform pg_temp.use_issued_worker_fixture();worker_claims:=current_setting('request.jwt.claims');
 insert into bookings(booking_id,customer_id,worker_id,service_id,booking_date,booking_time,estimated_cost,payment_mode)
 values(b,c,w,svc,current_date+3,'12:00',100,'cash');
 execute 'set local role anon';
 begin perform start_booking_call(b);exception when others then blocked:=true;end;
 if not blocked then raise exception 'Unaccepted booking allowed call';end if;
 perform worker_advance_booking(b,'accepted');
 cid:=start_booking_call(b);
 if start_booking_call(b)<>cid then raise exception 'Call retry duplicated room';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uc)::text,true);
 if start_booking_call(b)<>cid then raise exception 'Customer did not share assigned call';end if;
 if (select count(*) from care_call_members where call_id=cid)<>2 then raise exception 'Incorrect call membership';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',ux)::text,true);
 blocked:=false;
 begin perform start_booking_call(b);exception when others then blocked:=true;end;
 if not blocked then raise exception 'Outsider could start call';end if;
 if exists(select 1 from care_calls where id=cid) then raise exception 'Outsider could read call';end if;
 perform set_config('request.jwt.claims',worker_claims,true);
 perform worker_advance_booking(b,'on_the_way');perform worker_advance_booking(b,'arrived');perform worker_advance_booking(b,'in_progress');
 blocked:=false;
 begin perform worker_advance_booking(b,'completed');exception when others then blocked:=true;end;
 if not blocked then raise exception 'Cash job completed without receipt';end if;
 result:=confirm_cash_collected(b);
 if (result->>'amount')::numeric<>100 then raise exception 'Cash amount differs from customer price';end if;
 blocked:=false;
 begin perform confirm_cash_collected(b);exception when others then blocked:=true;end;
 if not blocked then raise exception 'Duplicate cash collection accepted';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uc)::text,true);
 perform submit_review(b,4,'Good work',true);
 if not exists(select 1 from reviews where booking_id=b and hide_name) then raise exception 'Privacy not persisted';end if;
 perform set_config('request.jwt.claims',worker_claims,true);
 if exists(select 1 from reviews where booking_id=b) then raise exception 'Worker can read hidden review identity';end if;
 if not exists(select 1 from my_worker_reviews() where review='Good work' and customer_name='Verified customer' and booking_id is null) then raise exception 'Partner projection leaked reviewer';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',ux)::text,true);
 if not exists(select 1 from public_worker_reviews(w) where customer_name='Verified customer' and rating=4) then raise exception 'Public review missing or unmasked';end if;
 blocked:=false;
 begin perform submit_review(b,5,'Forged',false);exception when others then blocked:=true;end;
 if not blocked then raise exception 'Outsider changed review';end if;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uc)::text,true);
 perform submit_review(b,5,'Updated',false);
 if not exists(select 1 from public_worker_reviews(w) where customer_name='Private reviewer' and rating=5) then raise exception 'Privacy choice could not be updated';end if;
 execute 'reset role';
 if (select cash_in_hand from worker_payout_accounts where worker_id=w)<>100 then raise exception 'Cash counted twice';end if;
 if (select average_rating from workers where worker_id=w)<>5 then raise exception 'Rating average stale';end if;
end $$;
select 'Booking calls, cash confirmation and review privacy checks passed' as result;
rollback;
