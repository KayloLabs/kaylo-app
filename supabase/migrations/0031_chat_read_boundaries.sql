-- A receipt acknowledges a rendered snapshot, never messages arriving afterwards.
begin;
create or replace function public.chat_mark_read_through(p_room_id uuid,p_message_id uuid)
returns void language plpgsql security definer set search_path='' as $$
declare b public.bookings; boundary public.messages; me uuid:=public.current_person_id();
begin
  select booked.* into b from public.bookings booked join public.chat_rooms r using(booking_id)
    where r.room_id=p_room_id for share of booked;
  if me is null or not found or b.worker_id is null or b.status not in ('confirmed','in_progress','completed','cancelled')
    or not coalesce(b.customer_id=public.current_customer_id() or b.worker_id=public.current_worker_id(),false)
    then raise exception 'CHAT_ACCESS_DENIED' using errcode='42501';end if;
  select * into boundary from public.messages where message_id=p_message_id and room_id=p_room_id;
  if not found then raise exception 'CHAT_INVALID_MESSAGE' using errcode='22023';end if;
  update public.messages set read_at=clock_timestamp()
    where room_id=p_room_id and sender_id<>me and read_at is null
      and (sent_at,message_id)<=(boundary.sent_at,boundary.message_id);
end $$;
revoke all on function public.chat_mark_read_through(uuid,uuid) from public;
grant execute on function public.chat_mark_read_through(uuid,uuid) to anon,authenticated;
commit;
