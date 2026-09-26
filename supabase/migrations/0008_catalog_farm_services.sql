-- ============================================================
-- Kaylo — farm services the live project was seeded before
--
-- Tree Pruning and Plot Clearing were added to the catalog after this
-- project first ran seed.sql, so a live Farm Services list showed only
-- Coconut Plucking and Arecanut Harvesting. These inserts add them.
-- Idempotent; a project that already has them is unaffected. (They are
-- already in seed.sql for fresh projects.)
-- ============================================================

insert into services
  (service_id, category_id, service_name, description, base_price, estimated_duration_minutes, icon_path, is_popular)
values
  ('20000000-0000-4000-8000-000000000009', '10000000-0000-4000-8000-000000000002',
   'Tree Pruning', 'Overhanging branches trimmed safely near roofs and power lines', 600, 90,
   'assets_kaylo/3d_transparent/icon_garden.png', false),
  ('20000000-0000-4000-8000-000000000010', '10000000-0000-4000-8000-000000000002',
   'Plot Clearing', 'Grass and bush cleared with brush cutters', 350, 60,
   'assets_kaylo/3d_transparent/mode_farm.png', false)
on conflict (service_id) do nothing;

-- Give the seeded workers these skills so the services are not empty.
insert into worker_services (worker_service_id, worker_id, service_id, experience_years, verified_skill)
values
  ('45000000-0000-4000-8000-000000000009', '40000000-0000-4000-8000-000000000001',
   '20000000-0000-4000-8000-000000000009', 5, true),
  ('45000000-0000-4000-8000-000000000010', '40000000-0000-4000-8000-000000000003',
   '20000000-0000-4000-8000-000000000010', 6, true)
on conflict (worker_service_id) do nothing;
