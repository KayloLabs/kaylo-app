-- Payment and partner acceptance are separate decisions.
create or replace function sync_booking_stage_and_status()
returns trigger language plpgsql as $$
begin
  if tg_op = 'UPDATE' and new.worker_stage is distinct from old.worker_stage then
    new.status := case new.worker_stage
      when 'accepted' then 'confirmed'::booking_status
      when 'on_the_way' then 'confirmed'::booking_status
      when 'arrived' then 'confirmed'::booking_status
      when 'in_progress' then 'in_progress'::booking_status
      when 'completed' then 'completed'::booking_status
      when 'cancelled' then 'cancelled'::booking_status
      else new.status end;
  elsif tg_op = 'UPDATE' and new.status is distinct from old.status then
    -- Payment confirmation is not a worker's acceptance. Only the stage RPC
    -- moves an assigned request to accepted; paid requests keep waiting.
    if new.worker_id is not null and new.status = 'confirmed' then
      new.status := booking_status_for_stage(new.worker_stage);
      return new;
    end if;
    new.worker_stage := case new.status
      when 'cancelled' then 'cancelled'
      when 'completed' then 'completed'
      when 'confirmed' then case when new.worker_stage = 'requested' then 'accepted' else new.worker_stage end
      when 'in_progress' then case when new.worker_stage in ('requested', 'accepted', 'on_the_way', 'arrived')
                                   then 'in_progress' else new.worker_stage end
      else new.worker_stage end;
  end if;
  return new;
end $$;
