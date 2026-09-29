-- Tracking has a distinct travel state between confirmation and work start.
alter type booking_status add value if not exists 'on_way' after 'confirmed';
