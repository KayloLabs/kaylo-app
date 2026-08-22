# Kaylo Backend (Supabase / PostgreSQL)

The backend implements the team ERD as a Postgres schema on Supabase, with
row-level security on every table and read-optimized views for the app.

## Layout

```text
supabase/
├── migrations/
│   ├── 0001_initial_schema.sql   # tables, enums, indexes, triggers, views
│   └── 0002_rls_policies.sql     # RLS enablement + policies + auth helpers
└── seed.sql                      # roles, categories, services, demo workers
```

The Flutter side selects its data source at compile time
(`lib/core/config/app_env.dart`):

| Run command                                        | Data source        |
|----------------------------------------------------|--------------------|
| `--dart-define=USE_MOCK=true`                      | Mock repositories  |
| no defines                                         | Mock (fallback)    |
| `--dart-define=SUPABASE_URL=… SUPABASE_ANON_KEY=…` | Live Supabase      |

Repository interfaces (`HomeRepository`, `WorkersRepository`,
`BookingsRepository`) are unchanged — `Supabase*Repository` classes in each
feature's `data/` folder implement them, so no UI code knows the difference.

## One-time setup

1. Create a free project at [supabase.com](https://supabase.com) (choose a
   region close to Kerala, e.g. `ap-south-1` Mumbai).
2. In the Supabase dashboard, open **SQL Editor** and run, in order:
   1. `supabase/migrations/0001_initial_schema.sql`
   2. `supabase/migrations/0002_rls_policies.sql`
   3. `supabase/seed.sql`
3. Grab the project URL and anon key from **Settings → API**.
4. Run the app:

```bash
flutter run -d chrome --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

(Alternatively install the Supabase CLI and use `supabase db push` — the
`supabase/` folder is already CLI-shaped.)

## Deliberate deviations from the ERD

| ERD                      | Implemented as                          | Why |
|--------------------------|------------------------------------------|-----|
| `Person.password_hash`   | `persons.auth_user_id → auth.users(id)`  | Supabase Auth owns credentials; app tables must never store password hashes. |
| `SOS` / `SOS.time`       | `sos_alerts` / `triggered_at`            | Clearer names; `time` is a SQL type name. |
| `MedicineReminder.time`  | `remind_time`                            | Same reason. |
| `Service.estimated_duration` | `estimated_duration_minutes int`     | Unambiguous unit. |
| —                        | `services.icon_path / is_popular / is_active`, `service_categories.slug` | The dashboard UI needs these. |

## Robustness built in

- **Enums** for every status column (`booking_status`, `payment_status`,
  `account_status`, `sos_status`) — invalid states are impossible to store.
- **RLS everywhere**: catalog data is public; bookings/payments/chat are
  visible only to their participants; care data only to the owning customer.
  Auth identity resolves through `current_person_id()/current_customer_id()/
  current_worker_id()` helper functions.
- **Triggers**: `persons.updated_at` auto-touches; `workers.average_rating`
  recomputes from reviews; `workers.total_jobs` bumps when a booking
  completes. Clients never write aggregates.
- **Views** (`service_catalog`, `worker_profiles`) run with
  `security_invoker`, so RLS still applies through them.
- **Constraints**: unique person↔customer/worker links, one review per
  booking, rating `CHECK (1..5)`, FK `ON DELETE` behavior chosen per table
  (cascade for owned data, `set null` where history should survive).
- **Seed mirrors the mocks**, so switching data sources changes nothing
  visually — easy A/B during reviews.

## Next steps (when auth lands — M2)

- Sign-up flow creates `persons` (with `auth_user_id = auth.uid()`) +
  `customers` rows after `supabase.auth.signUp`.
- Replace the splash's mock-mode bypass with a session check via
  `Supabase.instance.client.auth.currentSession`.
- Live GPS tracking and chat can use Supabase Realtime channels on
  `messages` — the schema is already subscribed-ready.
