-- Prices a customer in Kerala would recognise. Farm work is booked per
-- tree or per hour, so the earlier figures (1,000 for one coconut tree)
-- made an ordinary booking cost many times what it should. Existing
-- bookings keep the amount they were made at. Safe to run more than once.
begin;

-- Per tree: coconut, arecanut, pruning. Per hour: plot clearing, gardening.
-- Everything else is one visit.
update services s set base_price = v.price
  from (values
    ('Coconut Plucking', 50), ('Arecanut Harvesting', 30), ('Tree Pruning', 300),
    ('Plot Clearing', 300), ('Gardening', 180),
    ('Electrical', 250), ('Plumbing', 300), ('Appliance Repair', 300), ('Carpentry', 350),
    ('AC Service', 550), ('House Cleaning', 600), ('Painting', 600),
    ('Medicine Delivery', 40), ('Doctor Appointment', 300), ('Caregiver Visit', 300)
  ) as v(name, price)
 where s.service_name = v.name;

-- A consultation, by speciality.
update doctors d set consultation_fee = v.fee
  from (values ('doc1', 300), ('doc2', 600), ('doc3', 500), ('doc4', 400), ('doc5', 250)) as v(id, fee)
 where d.id = v.id;

-- A caregiver, per hour.
update caregivers c set hourly_rate = v.rate
  from (values ('cg1', 150), ('cg2', 150), ('cg3', 130)) as v(id, rate)
 where c.id = v.id;

commit;
