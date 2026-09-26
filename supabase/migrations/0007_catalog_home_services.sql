-- ============================================================
-- Kaylo — home services added after the first seed
--
-- The catalog grew (Carpentry, Painting, AC Service, Appliance Repair)
-- but supabase/seed.sql, which a live project runs once, was not
-- updated, so the live Home Services list showed only the original
-- four. These inserts add the missing services; idempotent, so a
-- project that already has them is unaffected.
-- ============================================================

insert into services
  (service_id, category_id, service_name, description, base_price, estimated_duration_minutes, icon_path, is_popular)
values
  ('20000000-0000-4000-8000-000000000011', '10000000-0000-4000-8000-000000000001',
   'Carpentry', 'Furniture repair, assembly, and woodwork', 450, 90,
   'assets_kaylo/3d_transparent/icon_carpentry.png', false),
  ('20000000-0000-4000-8000-000000000012', '10000000-0000-4000-8000-000000000001',
   'Painting', 'Interior and exterior home painting', 800, 240,
   'assets_kaylo/3d_transparent/icon_painting.png', false),
  ('20000000-0000-4000-8000-000000000013', '10000000-0000-4000-8000-000000000001',
   'AC Service', 'AC maintenance, repair, and gas refilling', 650, 60,
   'assets_kaylo/3d_transparent/icon_ac.png', false),
  ('20000000-0000-4000-8000-000000000014', '10000000-0000-4000-8000-000000000001',
   'Appliance Repair', 'Washing machine, fridge, and TV repair', 500, 60,
   'assets_kaylo/3d_transparent/icon_appliance.png', false)
on conflict (service_id) do nothing;

-- Give the seeded workers these skills so the new services are not
-- empty: Raju does carpentry and appliance repair, Suresh handles AC
-- and painting.
insert into worker_services (worker_service_id, worker_id, service_id, experience_years, verified_skill)
values
  ('45000000-0000-4000-8000-000000000011', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000011', 6, true),
  ('45000000-0000-4000-8000-000000000012', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000014', 4, true),
  ('45000000-0000-4000-8000-000000000013', '40000000-0000-4000-8000-000000000003',
   '20000000-0000-4000-8000-000000000013', 7, true),
  ('45000000-0000-4000-8000-000000000014', '40000000-0000-4000-8000-000000000003',
   '20000000-0000-4000-8000-000000000012', 5, true)
on conflict (worker_service_id) do nothing;
