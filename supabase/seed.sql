-- ============================================================
-- Kaylo — seed data
-- Mirrors the app's mock repositories so switching from
-- USE_MOCK to live Supabase changes nothing visually.
-- Fixed UUIDs so re-running is idempotent (on conflict do nothing).
-- ============================================================

-- ---------- Roles ----------
insert into roles (role_id, role_name) values
  ('00000000-0000-4000-8000-000000000001', 'customer'),
  ('00000000-0000-4000-8000-000000000002', 'worker'),
  ('00000000-0000-4000-8000-000000000003', 'admin')
on conflict (role_id) do nothing;

-- ---------- Categories ----------
insert into service_categories (category_id, category_name, slug, description) values
  ('10000000-0000-4000-8000-000000000001', 'Home Services', 'home', 'Plumbing, electrical, cleaning and everything for your home'),
  ('10000000-0000-4000-8000-000000000002', 'Farm Services', 'farm', 'Harvesting, gardening and irrigation support'),
  ('10000000-0000-4000-8000-000000000003', 'Kaylo Care', 'care', 'Medicine delivery, appointments and senior care')
on conflict (category_id) do nothing;

-- ---------- Services (ids 2xxx) ----------
insert into services (service_id, category_id, service_name, description, base_price, estimated_duration_minutes, icon_path, is_popular) values
  ('20000000-0000-4000-8000-000000000001', '10000000-0000-4000-8000-000000000002', 'Coconut Plucking',    'Professional coconut climbers',        1000, 60,  'assets_kaylo/3d_transparent/icon_coconut.png',  true),
  ('20000000-0000-4000-8000-000000000002', '10000000-0000-4000-8000-000000000002', 'Arecanut Harvesting', 'Expert harvesting',                    1200, 90,  'assets_kaylo/3d_transparent/icon_arecanut.png', true),
  ('20000000-0000-4000-8000-000000000003', '10000000-0000-4000-8000-000000000001', 'Gardening',           'Lawn and garden maintenance',           800, 120, 'assets_kaylo/3d_transparent/icon_garden.png',   true),
  ('20000000-0000-4000-8000-000000000004', '10000000-0000-4000-8000-000000000001', 'Plumbing',            'Expert plumbing services',              500, 60,  'assets_kaylo/3d_transparent/icon_plumb.png',    true),
  ('20000000-0000-4000-8000-000000000005', '10000000-0000-4000-8000-000000000001', 'Electrical',          'Electrical repairs and wiring',         400, 60,  'assets_kaylo/3d_transparent/icon_electric.png', true),
  ('20000000-0000-4000-8000-000000000006', '10000000-0000-4000-8000-000000000001', 'House Cleaning',      'Deep cleaning by trained staff',        600, 180, 'assets_kaylo/3d_transparent/icon_more.png',     false),
  ('20000000-0000-4000-8000-000000000007', '10000000-0000-4000-8000-000000000003', 'Medicine Delivery',   'Doorstep delivery from local pharmacies', 50, 45, 'assets_kaylo/3d_transparent/icon_more.png',     false),
  ('20000000-0000-4000-8000-000000000008', '10000000-0000-4000-8000-000000000003', 'Caregiver Visit',     'Trained caregiver home visits',        700, 120, 'assets_kaylo/3d_transparent/icon_more.png',     false)
on conflict (service_id) do nothing;

-- ---------- Demo workers (persons 3xxx, workers 4xxx, locations 5xxx) ----------
insert into persons (person_id, full_name, phone_number, language) values
  ('30000000-0000-4000-8000-000000000001', 'Raju K.',   '+91 90000 00001', 'ml'),
  ('30000000-0000-4000-8000-000000000002', 'Manoj P.',  '+91 90000 00002', 'ml'),
  ('30000000-0000-4000-8000-000000000003', 'Suresh B.', '+91 90000 00003', 'ml')
on conflict (person_id) do nothing;

insert into person_roles (person_role_id, person_id, role_id) values
  ('35000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', '00000000-0000-4000-8000-000000000002'),
  ('35000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', '00000000-0000-4000-8000-000000000002'),
  ('35000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', '00000000-0000-4000-8000-000000000002')
on conflict (person_role_id) do nothing;

insert into locations (location_id, person_id, district, state, pincode) values
  ('50000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 'Kochi',     'Kerala', '682001'),
  ('50000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', 'Ernakulam', 'Kerala', '682011'),
  ('50000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', 'Thrissur',  'Kerala', '680001')
on conflict (location_id) do nothing;

insert into workers (worker_id, person_id, experience_years, hourly_rate, is_verified, average_rating, total_jobs) values
  ('40000000-0000-4000-8000-000000000001', '30000000-0000-4000-8000-000000000001', 8, 250, true,  4.8, 120),
  ('40000000-0000-4000-8000-000000000002', '30000000-0000-4000-8000-000000000002', 5, 200, true,  4.5,  85),
  ('40000000-0000-4000-8000-000000000003', '30000000-0000-4000-8000-000000000003', 12, 300, true, 4.9, 200)
on conflict (worker_id) do nothing;

insert into worker_services (worker_service_id, worker_id, service_id, experience_years, verified_skill) values
  -- Raju: coconut plucking
  ('45000000-0000-4000-8000-000000000001', '40000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', 8, true),
  -- Manoj: coconut plucking + plumbing
  ('45000000-0000-4000-8000-000000000002', '40000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000001', 5, true),
  ('45000000-0000-4000-8000-000000000003', '40000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000004', 4, true),
  -- Suresh: electrical
  ('45000000-0000-4000-8000-000000000004', '40000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000005', 12, true)
on conflict (worker_service_id) do nothing;
