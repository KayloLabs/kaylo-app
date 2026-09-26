-- ============================================================
-- Kaylo — bookings default to the signed-in customer
--
-- bookings.customer_id references customers.customer_id, which is not
-- the person_id the app carries as the user id. Rather than have the
-- client look the customer up, the column now defaults to the caller's
-- customer, resolved from the verified JWT the same way the RLS
-- policies do. The app then omits customer_id on insert and relies on
-- row-level security to scope reads, so a Firebase uid or a person_id
-- can never land in this column again.
-- ============================================================

alter table bookings
  alter column customer_id set default current_customer_id();

-- Locations are inserted with the person_id already, but a default
-- keeps them correct if a client ever omits it, matching the pattern.
alter table locations
  alter column person_id set default current_person_id();
