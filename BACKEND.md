# Kaylo Backend (Supabase / PostgreSQL)

The backend implements the team ERD as a Postgres schema on Supabase, with
row-level security on every table and read-optimized views for the app.

## Layout

```text
supabase/
├── migrations/
│   ├── 0001_initial_schema.sql   # tables, enums, indexes, triggers, views
│   ├── 0002_rls_policies.sql     # RLS enablement + policies + auth helpers
│   └── 0003_care_contacts_and_logs.sql  # emergency contacts, dose logs, SOS columns
└── seed.sql                      # roles, categories, services, demo workers
```

The Flutter side selects its data source at compile time
(`packages/kaylo_core/lib/config/app_env.dart`, shared by both apps):

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
   4. `supabase/migrations/0003_care_contacts_and_logs.sql`
   5. `supabase/migrations/0004_care_doctors_caregivers.sql`
   6. `supabase/migrations/0005_firebase_auth_and_device_tokens.sql`

   A project that already ran the earlier steps only needs the new
   migrations (each is also appended to `setup_all.sql` for fresh
   projects). 0004 adds the `doctors`, `caregivers` and
   `doctor_appointments` tables the Care doctor and caregiver screens
   read, seeded with the same directory the mock mode shows.
3. Grab the project URL and anon key from **Settings → API**.
4. Run the app:

```bash
cd apps/customer && flutter run -d chrome --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

(The same defines work for `apps/partner`.)

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

## Firebase (auth, push, crashes, analytics)

Firebase provides the platform services; the data stays in Supabase.

- **Authentication**: phone OTP through Firebase. Supabase accepts the
  Firebase ID token as a third-party JWT, so the schema and every RLS
  policy keep working. Migration `0005` makes `persons.auth_user_id`
  hold the Firebase uid and switches the helpers to the token subject.
- **Cloud Messaging**: each signed-in device registers its token in
  `device_tokens` (`person_id`, `platform`, `app`), ready for a booking
  webhook to push to.
- **Crashlytics** and **Analytics**: wired in `FirebaseBootstrap`
  (`packages/kaylo_core`); screen views come from a router observer.

One-time setup:

1. Firebase console: create the project, enable Phone sign-in (add test
   numbers with fixed codes for demos), register the six apps (customer
   and partner, each Android `com.kaylo.app` / `com.kaylo.partner`, iOS
   and web).
2. `firebase login`, then in each app directory
   `flutterfire configure --project=<firebase-project-id> --platforms=android,ios,web`.
   This writes `lib/firebase_options.dart`, `android/app/google-services.json`
   and `ios/Runner/GoogleService-Info.plist`; commit them.
3. Android phone auth needs the debug SHA-1 in the console: run
   `./gradlew signingReport` inside `apps/<app>/android` once and add the
   SHA1 to both Android apps.
4. Supabase dashboard: Authentication -> Sign In / Providers ->
   Third-Party Auth -> add Firebase with the project id. Then run
   migration `0005`.

Without Firebase options for a platform (desktop, or before step 2) the
apps still start: sign-in falls back to Supabase OTP and push, crash
reporting and analytics are off.
