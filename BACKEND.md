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
   7. `supabase/migrations/0006_booking_customer_default.sql`
   8. `supabase/migrations/0007_catalog_home_services.sql`
   9. `supabase/migrations/0008_catalog_farm_services.sql`
   10. `supabase/migrations/0009_live_demo_readiness.sql`
   11. `supabase/migrations/0010_payments_razorpay.sql`
   12. `supabase/migrations/0011_email_otps.sql`

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
   `flutterfire configure --project=studio-1794461068-2d7dd --platforms=android,ios,web`.
   This writes `lib/firebase_options.dart`, `android/app/google-services.json`
   and `ios/Runner/GoogleService-Info.plist`; commit them. (Done for both
   apps; the project is `studio-1794461068-2d7dd`.) The CLI's iOS step
   needs the `xcodeproj` Ruby gem; without it the plist is written but not
   added to the Xcode project, so the first person building for iPhone
   drags `ios/Runner/GoogleService-Info.plist` into the Runner target in
   Xcode once.
3. Android phone auth needs the debug SHA-1 in the console: run
   `./gradlew signingReport` inside `apps/<app>/android` once and add the
   SHA1 to both Android apps.
4. Supabase dashboard: Authentication -> Sign In / Providers ->
   Third-Party Auth -> add Firebase with the project id. Then run
   migration `0005`.

Without Firebase options for a platform (desktop, or before step 2) the
apps still start: sign-in falls back to Supabase OTP and push, crash
reporting and analytics are off.

### Google sign-in

The customer app signs in with Google through Firebase: a browser
pop-up on web, the `google_sign_in` plugin on Android and iOS. The
profile row is created or completed from the Google identity (name,
email, photo) by `ProfileSync` in `features/auth/domain/profile_store.dart`.

1. Firebase console → Authentication → Sign-in method → **Google** →
   Enable, pick the support email, save. Web works from here.
2. Android: the debug SHA-1 must be on the Android app (see above), then
   re-run `flutterfire configure` in `apps/customer` so
   `google-services.json` picks up the OAuth client; the plugin reads the
   web client id from it. Alternatively pass
   `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web client id>`.
3. iOS: after step 1, re-run `flutterfire configure` and add the
   `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a URL scheme in
   `ios/Runner/Info.plist` (standard google_sign_in setup).

Apple sign-in is wired for web only (Firebase pop-up) and needs the Apple
developer configuration before it can be enabled.

## Google Maps (location picker)

The location picker (the header pill and first-run Location Setup) shows a
map under a fixed pin. Out of the box it draws OpenStreetMap tiles, which are
free and need no key. With a Google Maps key the same screens switch to
Google's map (richer tiles, lite-mode previews on Android); the steps below
are for that upgrade. The address under the pin and the town search come
from OpenStreetMap's Nominatim either way.

1. Google Cloud console, project `studio-1794461068-2d7dd` (the Firebase
   project). Enable **Maps SDK for Android**
   (`https://console.cloud.google.com/apis/library/maps-android-backend.googleapis.com?project=studio-1794461068-2d7dd`);
   for web and iOS builds also **Maps JavaScript API** and **Maps SDK for
   iOS** from the same library. Maps Platform needs a billing account on the
   project (`https://console.cloud.google.com/billing?project=studio-1794461068-2d7dd`);
   the monthly free usage covers a demo many times over.
2. Credentials (`https://console.cloud.google.com/apis/credentials?project=studio-1794461068-2d7dd`),
   **Create credentials, API key**. Restrict it to Android app `com.kaylo.app`
   with the debug SHA-1 (`cd apps/customer/android && ./gradlew signingReport`),
   iOS bundle `com.kaylo.app`, and your HTTP referrers for web.
3. Put the key in `apps/customer/android/local.properties` (gitignored, never
   committed), one line:

   ```
   GOOGLE_MAPS_API_KEY=AIza...
   ```

4. Build with the script, which reads that line and passes it to Flutter:

   ```bash
   apps/customer/tool/build_apk.sh
   ```

   The dart-define `GOOGLE_MAPS_API_KEY` is what switches the map on in the
   app; `android/app/build.gradle.kts` decodes the same define (or the
   `local.properties` line) into the manifest, and the web app injects the
   Maps script with it at runtime. Building by hand is the same flag:
   `flutter build apk --dart-define=USE_MOCK=true --dart-define=GOOGLE_MAPS_API_KEY=AIza...`.
   iOS additionally needs the line in `apps/customer/ios/Flutter/Maps.xcconfig`
   (gitignored, included by Debug/Release.xcconfig), which fills `GMSApiKey`.

Without a key nothing is missing: the map is OpenStreetMap, and GPS and town
search work the same. Widget tests run with no map engine at all
(`mapBackendProvider` overridden to `MapBackend.none` in `test_app.dart`), so
they never fetch tiles or create a platform view.

## Payments (Razorpay) and the invoice email

Online payment runs through Razorpay, verified on the server, with an
invoice emailed afterwards. The server is two Supabase Edge Functions in
`supabase/functions`; the app never holds the Razorpay secret.

- `create-order`: the app sends a booking id. The function reads the
  booking with the caller's own token (so row-level security proves it is
  theirs), takes the amount from the row, creates a Razorpay order, stores
  a pending row in `payments` and returns what Checkout needs.
- `verify-payment`: the app sends Checkout's order id, payment id and
  signature. The function checks the signature against the key secret,
  confirms the payment with Razorpay (capturing it if needed), marks the
  payment paid with an invoice number, sets the booking to confirmed (the
  notification trigger from 0009 tells the customer) and emails the invoice.

Both are deployed with JWT verification off (`supabase/config.toml`)
because sign-in is Firebase; the ownership check above replaces it.

One-time setup:

1. Run migration `0010_payments_razorpay.sql` (payments columns, invoice
   numbers).
2. [Razorpay dashboard](https://dashboard.razorpay.com/): in **Test Mode**,
   Account & Settings → API Keys → Generate key. Live mode needs business
   KYC; test mode is enough for a demo and uses Razorpay's test cards and UPI.
3. A Gmail account for sending invoices, with 2-Step Verification on and an
   [app password](https://myaccount.google.com/apppasswords). Gmail needs no
   domain of our own; Supabase functions reach it on port 465.
4. From the repo root, once (`supabase login` opens the browser):

   ```bash
   supabase login
   supabase link --project-ref jeiwfvnkxubykrzjzktm
   supabase secrets set RAZORPAY_KEY_ID=rzp_test_... RAZORPAY_KEY_SECRET=... \
     GMAIL_USER=you@gmail.com GMAIL_APP_PASSWORD=... INVOICE_FROM_NAME=Kaylo
   supabase functions deploy --use-api
   ```

   Re-run the last line after changing a function. Secrets never go in git.

Without the Razorpay secrets the functions answer `not-configured` and the
app falls back to pay-after-service; without the Gmail secrets payments
still complete and the invoice is simply not sent (`invoice_note` says so).

Every email (sign-in code, booking received, invoice) shares one Kaylo
frame: green header with the logo, white card, faded mark as a watermark on
the receipts. The images live in the public Storage bucket `assets` under
`email/` (`logo_white.png`, `logo_dark.png`, `watermark.png`), uploaded
once through the Storage API; mail clients such as Gmail need hosted images
and drop embedded ones. `booking-email` sends the "Booking received" note
for pay-after-service bookings (the app calls it after creating the
booking); paid bookings get the invoice from `verify-payment`.

Razorpay test mode: the sheet is the real one, so use test instruments.
Domestic test card 5267 3181 8797 5449 (any future expiry, any CVV; card
4111… counts as international and is refused unless international payments
are enabled). UPI: `success@razorpay`; if the UPI tab is missing, enable
UPI under Account & Settings → Payment methods in the Razorpay dashboard.

## Sign-in codes by email

Real SMS needs Firebase's paid plan, so the code goes by email instead,
while the session itself still comes from Firebase Authentication:

1. The app calls the `email-otp` Edge Function (`action: send`). It stores
   a hashed six-digit code in `email_otps` (migration 0011, server-only)
   and emails it through the Gmail account (same secrets as the invoice).
2. The app sends the code back (`action: verify`). The function checks it
   (ten-minute expiry, five attempts), finds the Firebase user with that
   email or creates one with the email marked verified, and returns a
   Firebase custom token minted with the project's service account.
3. The app signs in with `signInWithCustomToken`. From there it is an
   ordinary Firebase session: Supabase trusts the token as before, the
   profile row is created or found by uid, Google sign-in with the same
   email lands on the same account.

Secrets, in addition to the Gmail ones: `FIREBASE_SERVICE_ACCOUNT_B64`,
the service account JSON from Firebase (Project settings → Service
accounts → Generate new private key) encoded with `base64`:

```bash
supabase secrets set FIREBASE_SERVICE_ACCOUNT_B64="$(base64 -i ~/Downloads/<key>.json)"
```

The demo build (`USE_MOCK=true`) still accepts 1234 and sends nothing.


## Faculty demo: Android SOS and OTP email

The optional SIM fallback uses Android phone calls. The live app defaults to the new in-app call flow described below. Hold for three uninterrupted seconds. Kaylo asks for call and phone-state permissions, then calls the primary contact first. When the current call ends, return to Kaylo; the next call starts after three seconds on screen. Stop remaining calls cancels the queue, without ending a call already in progress. Leaving the SOS screen stops remaining calls. A saved number that cannot be dialled is skipped and counted on screen, so one mistyped contact never blocks the rest; short codes such as 112 are accepted (Android opens the dialler for emergency numbers instead of calling them directly). Duplicate phone numbers are called once. A call that never starts, for example with no SIM or in flight mode, is passed over a few seconds after returning to Kaylo. Normal SIM charges apply. The app shows attempts, which do not confirm the recipient answered, and does not claim SMS or location delivery. New SIM calls are not inserted into the legacy SOS alert history.

Sample builds start with no emergency contacts, so fictional sample numbers are never dialled. Add your demo contacts first.

Use a real Android phone with an active SIM, select a default voice SIM on dual-SIM devices, and test the permission prompts and call sequence with your demo contacts before the review. Calls do not continue automatically while Kaylo remains in the background. An OS process termination can stop the remaining queue.

No Kaylo email (sign-in code, invoice, booking received) carries a location line; the footer is just the name and the support address. The six digits of a sign-in code can be selected, or touched and held, to copy. Redeploy only `email-otp` to update outgoing mail:

```sh
supabase functions deploy email-otp --no-verify-jwt
```

For the optional browser Copy OTP button, host `apps/customer/web/copy-code.html` at a public HTTPS URL and set the `OTP_COPY_PAGE_URL` Supabase secret to that page URL. It is also included in Flutter web build output. No database migration is needed. Without the URL, the email keeps the selectable code without copy instructions. The page carries the code in the URL fragment, removes it from the address bar, and disables copying after expiry; server-side OTP verification remains authoritative. The page makes no network requests.


## Care demo update, 2 October 2026

Migrations 0012, 0013 and 0014 were applied to project `jeiwfvnkxubykrzjzktm` through the Management API. This project did not have a Supabase migration-history table. All three are safe to run again: tables, triggers and policies are only created when missing, so a rerun keeps the roles 0014 widened. `setup_all.sql` includes them for a fresh project.

Doctor and caregiver checkout now create a pending shared booking and linked care record. The server reads the provider fee. A verified successful payment confirms the linked record; cancellation/completion follows the booking. Payment methods opens secure Razorpay card checkout for pending bookings. Saved-card availability depends on Razorpay tokenisation configuration. Physical NFC card enrolment is not implemented by this gateway integration.

Prescriptions on Android use Google's document scanner for cropping, cleanup, multipage PDF output and gallery import. Bundled on-device Latin OCR produces editable text; handwriting and unsupported scripts can fail. Typed records use Android PDF rendering. Documents are private per signed-in person on the device, can be shared explicitly, and are removed through the prescription screen or account deletion. Kaylo does not sync these documents between devices; device-level backups follow Android settings. First scanner use can require a Google Play services download.

`delete-account` uses the caller's verified database identity, requires a sign-in within 30 minutes, blocks unresolved active bookings, removes account data, then deletes the Firebase identity. Its private retry record is removed after identity deletion succeeds. An identity-removal failure returns a retry instruction; it never reports a completed deletion.

In-app calls use trusted-contact invite codes and audio-only WebRTC. A user can invite up to five contacts who accept inside Kaylo. `care-call` verifies Firebase's RS256 signature, project and expiration before the database checks the caller and selects their contacts. FCM sends simultaneous invitations; these are not proof of delivery or acceptance. Recipients see a banner in the app and join the same call. Keep Kaylo open during calls. Database polling retrieves authenticated call membership and signaling; no voice is recorded.

Deployment status: `email-otp`, `verify-payment`, `delete-account`, and `care-call` deployed. The user explicitly approved the Firebase verification configuration for `care-call`. Missing and forged tokens return HTTP 401; the database also enforces contact and call-membership access.

For reliable calls across mobile networks, configure `CARE_ICE_SERVERS_JSON` with an approved TURN service's ICE servers. It is currently unset; default STUN alone cannot guarantee connectivity. Do not put relay secrets in the APK. Full-screen incoming-call UI and background audio service are not implemented. A real multi-phone call test remains necessary; no live calls or payments were made during verification.

Migration 0014 fixes empty Care connection lists for existing Firebase sessions without a `role` claim. Supabase verifies their Firebase JWT but routes database requests as `anon`. Care policies now use the same verified-subject/person and call-membership checks for both `anon` and `authenticated`. RLS remains enabled. Rolled-back tests in `supabase/tests/care_firebase_access.sql` check contact visibility and signaling for both session roles, and reject unrelated or unsigned access. No Firebase token claims or accounts were changed. See https://supabase.com/docs/guides/auth/third-party/firebase-auth for the role-claim behavior.

SOS offers Kaylo calls and Android SIM calls. The SIM flow supports manual contact entry and Android's phone-number picker, which reads only the selected contact URI without broad address-book permission. Selected details are reviewed before saving to the existing emergency-contact list. Calls proceed one at a time, primary contact first; return to Kaylo after each call to continue the queue. Chrome does not support the native contact picker or SIM calls. Native contact selection and carrier behavior still require an Android device check; no APK was rebuilt for this change.


## Booking offers and saved locations

Apply `supabase/migrations/0015_booking_offers.sql` once in the Kaylo project SQL editor before testing live offers. It adds booking subtotal and coupon fields, validates each coupon for the current customer, and saves the discounted amount before Razorpay creates its order. It also preserves Care visit notes and saved location IDs in the primary booking. Existing non-discounted bookings remain compatible.

Apply `supabase/migrations/0016_more_offers.sql` after it. 0016 replaces both offer functions, so the list below is what the live app shows once it has run. If an older migration is ever run again, run the later ones after it in order: 0015 redefines `create_care_checkout` from 0012, and 0016 redefines the offer functions from 0015. All of them are safe to repeat, and `setup_all.sql` holds the whole sequence for a fresh project.

Demo offers, all fixed amounts in rupees:

| Code | Saves | On | Who can use it |
| --- | --- | --- | --- |
| FIRST100 | 100 | 499 or more | First booking only |
| KAYLO150 | 150 | 1,499 or more | Once per account |
| KAYLO300 | 300 | 2,999 or more | Once per account |
| WEEKEND100 | 100 | 999 or more | Saturday and Sunday in India, once per account |
| WEEKDAY50 | 50 | 599 or more | Monday to Friday in India, once per account |
| HOME80 | 80 | 499 or more | Home services only, once per account |
| FARM125 | 125 | 999 or more | Farm services only, once per account |
| CARE60 | 60 | 399 or more | Care bookings only, once per account |
| NEXT75 | 75 | 799 or more | Scratch reward, after one confirmed booking |
| THANKS120 | 120 | 999 or more | Scratch reward, after three confirmed bookings |

One code per booking. Cancelled bookings release their coupon. An online checkout that was opened and never paid (a Razorpay order exists, no payment succeeded) does not use up an offer either: it no longer counts as a booking for FIRST100, and if the same code is applied to a newer booking the unpaid one gives it up and goes back to full price, which is what a later payment for it will charge. A pay-after-service booking has no payment row and counts as a real booking. One gap remains: a checkout sheet still open on another device when the code moves can be paid at the old discounted order amount.

Offer wording is translated in the app by code (`offer_copy.dart`), with the database's English as the fallback for a code the installed build does not know; `reason_code` in the response says why an offer is closed. Scratch reveal is a local animation; eligibility and redemption are checked by the database. `supabase/tests/offer_rules.sql` covers the rules above with synthetic accounts and rolls back.

`supabase/migrations/0017_realistic_prices.sql` resets the catalogue to everyday Kerala rates; run it after 0016. These are working estimates, not quoted rates, so adjust them freely. Farm work is priced per unit and the booking screen multiplies it out (ten trees, two hours or one visit to start with):

`supabase/migrations/0018_worker_payout_accounts.sql` moves `bank_account` and `upi_id` out of the public `workers` row into `worker_payout_accounts`, which only the worker it belongs to can read or write (the service role sees all). Run it after 0017; `supabase/tests/worker_payout_privacy.sql` checks it. The partner app's payout screens read and write that table, never `workers`.

`0019_cash_and_worker_stages.sql` and `0020_worker_registration.sql` are the backend for the partner app's second round. Run them after 0018, in order; `supabase/tests/cash_flow.sql` and `supabase/tests/worker_registration.sql` check them. What the apps call:

| Call | Who | Does |
| --- | --- | --- |
| `bookings.payment_mode` (`online` or `cash`) | customer app sets it when booking | a cash booking gets a pending `payments` row (`payment_method = 'cash'`) by trigger |
| `bookings.worker_stage` | read by both apps | `requested`, `accepted`, `on_the_way`, `arrived`, `in_progress`, `completed`, `cancelled`; kept in step with `status` by trigger |
| `worker_advance_booking(booking_id, stage)` | worker | moves a job one step; refuses cash jobs when `commission_due` is at the limit, and completion of a cash job before the cash is confirmed |
| `confirm_cash_collected(booking_id, amount?)` | worker | marks the cash payment paid, completes the job, adds the amount to `worker_payout_accounts.cash_in_hand` and 15% to `commission_due` |
| `settle_cash_due(reference?)` | worker | writes a `settlements` row and clears the due |
| `my_cash_position()` | worker | cash in hand, commission due, the limit and the rate (0032); zero until the first cash job |
| `kaylo_commission_rate()`, `kaylo_cash_due_limit()` | both apps | 0.15 and 2,000 |
| `submit_review(booking_id, rating, text?)` | customer | one review per completed booking, editable; the worker's average refreshes by trigger |
| `register_worker(details jsonb)` | worker | profile, services, service area, payout account in one call; sets `verification_status = under_review` |
| `worker_documents` + bucket `worker-documents` | worker | files under `<worker_id>/…`, own rows and files only |
| `review_worker(...)`, `review_worker_document(...)` | service role only | the Trust Team's verdicts; `workers.is_verified` follows `verification_status` |

Notifications: workers get `New job request`, `Booking cancelled`, `Job completed`; customers additionally get `Your worker is on the way` and `Your worker has arrived`.

`0021_worker_time_slots.sql`: a worker's slot is held by any open booking. `worker_taken_slots(worker_id, date)` lists the held times for anyone signed in (times only, no customer data), and a trigger refuses a second open booking for the same worker, day and time, including reschedules. Cancelled and completed bookings free the slot. `supabase/tests/worker_time_slots.sql` checks it.

`0022_worker_profile_rpcs.sql` is the partner app's own profile. `my_worker_profile()` returns the signed-in worker's person, worker row, services, service area, payout account and document states as one JSON object (null for someone who is not a worker). `update_worker_profile(details jsonb)` takes the same keys as `register_worker` and changes only the ones present, so a partial edit never blanks a field; it refuses an empty name, an empty service list and a radius outside 1 to 100 km. `set_worker_available(flag)` is the on-duty switch behind `workers.is_available`. `supabase/tests/worker_profile_rpcs.sql` checks all three.

`0023_worker_availability.sql` adds the worker's side of slot availability. `worker_weekly_hours` holds one row per ISO weekday (1 = Monday) with a window or `works = false` for a day off; `worker_time_off` holds date ranges. Both default `worker_id` to the caller, so the partner app inserts and upserts them directly under row-level security. A worker with no weekly rows is available at any time. `worker_taken_slots(worker, date)` now also returns every half hour outside the window, or the whole day for a day off, so the customer app greys those slots with no change on its side, and the booking trigger refuses a new or moved booking outside the hours (a status change on an existing booking is never re-checked). `supabase/tests/worker_availability.sql` checks it.

| Service | Price | Per |
| --- | --- | --- |
| Coconut Plucking | 50 | tree |
| Arecanut Harvesting | 30 | tree |
| Tree Pruning | 300 | tree |
| Plot Clearing | 300 | hour |
| Gardening | 180 | hour |
| Electrical | 250 | visit |
| Plumbing, Appliance Repair | 300 | visit |
| Carpentry | 350 | visit |
| AC Service | 550 | visit |
| House Cleaning, Painting | 600 | visit |
| Medicine Delivery | 40 | delivery |
| Doctor consultation | 250 to 600 | by speciality |
| Caregiver | 130 to 150 | hour |

The sample build's catalogue (`mock_home_repository.dart`, `mock_care_repository.dart`) carries the same figures.

The short sounds (logo chime, the five notes, coupon stamp, reward reveal) are synthesised by `apps/customer/tool/make_sounds.py` into `apps/customer/assets/`; nothing is a recording.

`supabase/tests/booking_offers.sql` contains rollback-only SQL checks using synthetic accounts. Run it after the migration; it does not keep test bookings. Customer tests cover eligible amounts, failed-payment retry totals, search relevance, saved-address switching, and booking coordinate handoff.

The worker verification screen displays the existing Kaylo verification status. There are no uploaded qualification documents, verification dates, or independent check records in the current schema; the UI does not invent them.


## Issued Kaylo Partner accounts and admin review (0024 through 0027)

Partner registration is now a public **application**, never a Firebase sign-up.
Apply `0024_worker_applications.sql`, `0025_issued_partner_identities.sql`,
`0026_worker_application_notifications.sql`, then `0027_partner_admin_review.sql`
in order after the earlier migrations. They are idempotent and appended verbatim
to `setup_all.sql`. Deploy the matching edge functions with the schema; the mobile
changes alone cannot issue credentials. No production data or Firebase configuration
is changed by committing these files. The complete operator guide, admin allowlist,
portal setup and correction workflow are in [docs/PARTNER_ADMIN.md](docs/PARTNER_ADMIN.md).

### Enable and deploy

1. In **Firebase Console > Authentication > Sign-in method**, enable **Email/Password**
   (not email-link sign-in). Keep customer Google/phone providers enabled. Partner
   users must use the password provider and server-issued worker custom claims.
2. Keep existing `FIREBASE_SERVICE_ACCOUNT_B64`, `GMAIL_USER`, `GMAIL_APP_PASSWORD`
   secrets configured. Generate a new random `KAYLO_PARTNER_ADMIN_SECRET` with at
   least 32 characters, keep it in the admin password manager, and add it under
   **Supabase > Edge Functions > Secrets**. Never put it in Flutter or source control.
   Also set `APPLICATION_CORRECTION_SECRET` to an independent random secret of at
   least 32 characters and `KAYLO_PORTAL_URL` to the HTTPS origin serving the admin
   and correction pages. The Firebase service account needs user-management
   permissions; SMTP needs a Gmail app password. No password is stored in Postgres
   or logged by these functions. External correction emails require a publicly
   accessible correction page; the current private preview is not sufficient.
3. Deploy:

   ```sh
   supabase functions deploy worker-application-documents --no-verify-jwt
   supabase functions deploy issue-partner-credentials --no-verify-jwt
   supabase functions deploy partner-password-changed --no-verify-jwt
   supabase functions deploy admin-applications --no-verify-jwt
   supabase functions deploy application-corrections --no-verify-jwt
   supabase functions deploy email-otp --no-verify-jwt
   ```

   Gateway JWT verification is disabled deliberately: application upload uses an
   expiring application bearer token; support issuance requires the admin-only
   secret; admin review verifies Firebase tokens and an active UID allowlist;
   correction uploads verify a signed, expiring application/version capability;
   password completion verifies Google's Firebase signature/project/expiry itself.
4. Optional SMS uses **Twilio**, a paid external service subject to sender and local
   messaging registration rules. Configure `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`,
   `TWILIO_FROM_NUMBER` only after setting up an eligible sender. Without these,
   credentials arrive at the applicant's required delivery **email**. Email success
   is mandatory; optional SMS failure does not invalidate successful email delivery.

### Application emails and durable delivery (0027)

Migration 0027 supersedes the 0026 upload-triggered notification sender with
`application_mail_outbox`. Keep 0026 applied for compatibility, and deploy the
updated `worker-application-documents` together with `admin-applications` and
`application-corrections`. Do not run the old and new senders concurrently.

Once all five documents exist and the application is `under_review`, the database
queues a review notice addressed to **kayloapp@gmail.com**. The existing
`GMAIL_USER` and `GMAIL_APP_PASSWORD` send it. The current outbox stores this
recipient directly; the old `WORKER_APPLICATION_REVIEW_EMAIL` environment override
is not used. The notice contains the reference and admin portal link, without
identity documents, bank details, phone numbers or passwords.

An accepted approval, rejection or correction request queues its own applicant
email in the same database transaction. Upload or review success remains valid
when email fails. The response reports `delivery.state: "pending"` rather than
pretending the saved application or decision failed. Admins inspect the delivery
history and use **Retry delivery**; the endpoint also accepts
`{"action":"retry_delivery","application_id":"APPLICATION_UUID"}` with an
allowlisted admin's Firebase bearer token.

Each current message has a five-minute delivery lease, attempt count and
`pending`/`sending`/`sent`/`failed` state. Obsolete messages are retained for history
and excluded from retry. **There is no scheduled retry worker.** Upload completion
and review actions attempt delivery immediately; an admin must retry unresolved
failures. SMTP acceptance followed by a lost database acknowledgement may cause a
duplicate email. A sent state records acceptance, not guaranteed inbox placement.
Approval retries do not reset a successfully delivered worker password; when
credentials already exist, the retry sends the certificate using that identity.
The Chrome `USE_MOCK=true` partner preview does not submit real applications.

### Applicant contract

`submit_worker_application(p_details jsonb)` is callable with the public API key
without a session. Required details: `full_name`, E.164 `phone`, delivery `email`,
`profession`, active service UUIDs in `services`, `experience_years` (0-70), `district`,
`travel_radius_km` (1-100), `consent: true`, and a UPI ID or a `bank_account` object
containing `account_number`, `account_holder`, `bank_name`, `ifsc`. Include a fresh
cryptographically random 32-byte hex `client_request_token` per application.

Response: `{application_id, reference, status, upload_token, upload_expires_at}`.
The reference is `KA-` plus 24 random uppercase hexadecimal characters. Only
SHA-256 of the token is stored; it is stripped from application details. Retrying
with the same phone and token within its 24-hour lifetime recovers the same
application after a lost response. Retrying does not edit the application.
There is one open/approved application per normalized phone; rejected applicants
must wait 24 hours after submission before reapplying. Existing person email/phone
identities cannot be repurposed as new partners.

Upload each document using multipart POST to `worker-application-documents`:
`application_id`, `upload_token`, `doc_type`, `file`. The five types are `photo`,
`aadhaar_front`, `aadhaar_back`, `police_certificate`, `selfie`. JPEG/PNG/PDF files
must be nonempty and at most 10 MiB; photo and selfie must be images. The edge
checks file signatures, an unexpired matching bearer, uploads into the private
`worker-documents/applications/<id>/<type>/<random>.<extension>` path, then records
the actual stored object under a database lock. Approved/rejected evidence cannot
be replaced. New uploads never overwrite an existing object. A raced/rejected
upload is removed. Migration 0027 retains document versions and their private
paths for review history; do not delete historical objects as routine cleanup.
The fifth recorded document changes the state to `under_review`.

`worker_application_status(p_reference)` returns **only** reference, status and
`documents_received` count (or null). References are high-entropy bearer identifiers;
there is no phone/email search or public applicant table access. If an upload token
is lost or expired, an admin can request the missing or replacement documents
through the correction workflow. A request for an incomplete application must
include every missing document. Do not expose private document links publicly.

### Review, corrections and credentials (admin only)

Use the admin portal backed by `admin-applications`; ordinary reviewers can inspect
applications and request corrections, while `admin` users can also approve,
reject and retry delivery. Firebase sign-in alone grants no access: the exact
Firebase UID must have an active `admin_users` row.

Review the submitted details and all five private documents before approval.
Select all five document checks and record what the team actually reviewed.
The versioned `admin_review_application` transaction creates the worker, issued
partner ID, immutable certificate snapshot, audit event and applicant email job.
Concurrent document changes invalidate a decision made from an older preview.
The approval email delivers temporary credentials with the PDF review certificate;
the worker must change that password before accessing the partner app.

Request corrections with a reason and specific document types. The seven-day
signed link permits replacement of only those documents and preserves old versions.
When every requested document is received, the application returns to review and
queues a fresh admin notice. **Update change request** renews an expired request
and invalidates the previous link. Rejection requires a reason and sends that
reason to the applicant. File presence alone is not identity verification, and
the certificate does not claim automated Aadhaar, police or qualification checks.

Do not use the legacy `approve_worker_application` or `reject_worker_application`
RPC directly for routine reviews after 0027: doing so bypasses the portal's actor
audit, certificate and applicant outbox workflow. The new transaction calls the
underlying approval function after its role, evidence and version checks.

### Support password reset and recovery

The server-only `issue-partner-credentials` endpoint remains available for support.
Use a trusted server REST client, with `Content-Type: application/json` and
`x-kaylo-admin-secret: <your admin secret>`. Never place this secret in the portal.

- To recover an undelivered approved identity, POST
  `{"worker_id":"APPROVED_WORKER_UUID","action":"issue"}`.
- For a forgotten password, first verify the worker's identity through support,
  then POST the same body with `"action":"reset"`. Reset closes worker access,
  rotates the Firebase password and requires another password change.
- An in-progress issuance lease lasts ten minutes and covers SMTP delivery.
  Inspect `partner_credentials.state` and wait for an active lease before retrying;
  do not run a simultaneous reset to recover an in-flight send.

The response contains the partner ID and delivery result, never a password.
Passwords are delivered to the application email and optionally phone. The
`kp-000001@partners.kaylo.app` address is a synthetic Firebase login namespace,
not an inbox. A delivered issuance returns `already_issued: true`.
An uncertain SMTP acknowledgement may require a later fresh issuance; the worker
must use the newest credentials. Firebase, SMTP and Postgres do not form one
exactly-once transaction. Prefer the portal's **Retry delivery** for its pending
approval email so certificate delivery is tracked as well.

### First-password and role boundaries

Partner sign-in maps ID to the synthesized email and calls Firebase
`signInWithEmailAndPassword`. `partner_login_state()` supplies the forced-change
flag even while private worker APIs are locked. After Firebase `updatePassword`,
refresh the ID token and POST `{}` to `partner-password-changed` using that token.
The edge verifies a password-provider worker token, retrieves Firebase's actual
`passwordUpdatedAt`, and clears the flag only if it is newer than the issued
password baseline. `mark_password_changed(worker_id, issuance_id, timestamp)` is
**service-role only**; the client cannot simply call it, overwrite the flag, or
make up a timestamp. A raced reset invalidates the old issuance ID. A fresh sign-in
may be required if Firebase expired the session during the change.

`current_worker_id()` requires an issued, verified, password-changed session with
matching admin-set role/ID claims. Old Google, phone and custom-token sessions get
no worker access, and pre-reset tokens fail the issuance timestamp and random issuance-ID claim checks,
even when reset and sign-in occur within the same second. Each admin issuance sets
`kaylo_issuance_id` in Firebase custom claims; the database and password-completion
edge require its exact match with the active `partner_credentials.issuance_id`. The
legacy `register_worker` grant and direct worker/verification writes are revoked.
`ensure_customer_profile()` atomically creates the customer role and row only for
a nonworker caller. Triggers enforce role exclusivity even on direct table writes;
reserved partner emails/custom claims cannot self-insert a customer person.
Account deletion also refuses a gated worker session: a missing accessible person
is not mistaken for a previously deleted account. A deletion retry requires the
existing deletion journal after the original person has actually been removed.
`email-otp` refuses the reserved partner domain before sending or minting tokens.

Legacy seeded marketplace workers remain visible but cannot sign in until migrated
through an approved application and issued credentials. Existing dual-role persons
are suspended rather than deleting customer rows, jobs or payment history; an
admin must reconcile them into separate identities before restoring access. A
worker's old nonissued Firebase UID is never automatically overwritten by issuance.

### Local verification

`supabase/tests/partner_admin_review.sql` covers admin/reviewer permissions,
private evidence, optimistic review versions, correction scope and expiry,
renewal with old-link refusal, immutable certificates/audits, and outbox leases,
retries and deduplication. `worker_application_notifications.sql` retains coverage
for 0026 compatibility. Migration 0027 and the complete setup bundle have been
checked both fresh and on rerun in an isolated local PostgreSQL database.

`supabase/tests/worker_applications.sql` owns a transaction and rolls back. It proves
anonymous apply/retry, private applicant data, upload existence, required documents,
immutable approval, rejected applicant exclusion, no duplicate approval, both role
boundaries, blocked legacy registration, temporary-password gates and forbidden
client flag updates. Deno tests in `_shared/partner_security_test.ts` cover admin
secret matching, file signatures, credential entropy and timestamp checks; existing
`firebase_verify_test.ts` covers signature/project/expiry verification. `worker_registration.sql` now proves the retired self-registration path stays
closed. The worker profile, availability, payout, cash-flow and slot tests create
transaction-local issued-session fixtures so they exercise the same stricter
worker access rules as the app. Those temporary fixture functions are never part
of a migration or deployment.

External service reference: Firebase's [account management API](https://firebase.google.com/docs/auth/admin/manage-users)
and [Identity Platform REST API](https://docs.cloud.google.com/identity-platform/docs/use-rest-api)
document admin-created accounts and the server-only password update timestamp.
These local checks do not send real credentials or replace a Firebase/SMTP live
smoke test after an administrator deploys and configures the backend.


### Remaining partner integration dependencies

The partner app's live jobs feed now also drives the stage, cash and settlement
actions (`worker_advance_booking`, `confirm_cash_collected`, `settle_cash_due`,
`my_cash_position`). Coordinates and the cash fields on the job model still
arrive with Abhay's and Sandeep's PRs; the live repository tolerates their
absence. Chat, alerts and reviews are live since 0030.
The partner app registers device tokens with `app = 'partner'`, handles foreground
job-request notifications, and revokes its FCM token on sign-out. Background
new-job pushes still require a trusted backend event sender. See
`apps/partner/README.md` for the payload contract and build commands.
`tools/build_release_apps.py` checks free disk and memory before sequential release
builds; a skipped build due to low disk is not a successful release test.


### Website enquiries (0028) and the approval search path (0029)

`0028_professional_application_leads.sql` is the backend for the public website's
"work with Kaylo" form. It is deliberately separate from `worker_applications`: a
lead is an enquiry, not a reviewed application. The website calls
`submit_professional_lead(jsonb)` with the publishable key; the function validates
every field, normalises the phone to `+91`, stores the row and returns only the
UUID receipt the caller supplied. Retries are insert-only, and neither `anon` nor
`authenticated` can read, change or delete a lead; the service role sees them in
the dashboard. `supabase/tests/professional_application_leads.sql` checks the
receipt, the retry, the role boundaries and every invalid input.

`0029_admin_certificate_extension_path.sql` fixes approval on Supabase, where
`pgcrypto` lives in the `extensions` schema: `admin_review_application` now
resolves `gen_random_bytes` through `public, extensions` when it assigns a
certificate number. `partner_admin_review.sql` relocates `pgcrypto` the same way
inside its transaction so the local harness matches production.

Apply 0028 and 0029 after 0027 and before 0030. Both are in `setup_all.sql`.
0028 is already applied to the live project.

### Booking chat and partner activity (0030 and 0031)

Apply `0030_booking_chat_and_partner_activity.sql`, then
`0031_chat_read_boundaries.sql` after the existing partner onboarding migrations.
Both are included in `setup_all.sql`. They use the existing Firebase-backed
person, customer and issued-worker authorization helpers.

Booking participants can open a conversation after a worker accepts the job.
Completed or cancelled conversations remain readable but cannot send messages
or typing updates. Client message IDs make retries idempotent. Private realtime
subscriptions update messages, read receipts and short-lived typing indicators;
reconnects and periodic snapshots catch up missed events.

Both apps request messages oldest first. A read receipt calls
`chat_mark_read_through` with the last displayed incoming message while the
conversation is active and scrolled to the latest messages. The server limits
the update to that snapshot and never marks the sender's own messages read.
The older `chat_mark_read` endpoint remains for existing clients.

0030 also provides the assigned-job and worker-review projections, partner
notification preferences, booking/payment alerts, and participant-only access.
Run `supabase/tests/booking_chat.sql` as the database owner after applying both
migrations. Its synthetic data, authorization checks and read-receipt tests run
inside a transaction that is rolled back.


### Job privacy, quiet self-alerts and the cash position (0032)

Apply `0032_partner_job_privacy_and_cash_position.sql` after 0031; it is in
`setup_all.sql`.

`my_partner_jobs()` now follows the job: the customer's phone, house and exact
coordinates are returned only while the booking is accepted, on the way, arrived
or in progress. A request carries the district, pincode and coordinates rounded
to two decimals (about a kilometre) so the distance estimate still works before
the worker accepts. Finished jobs keep the district and pincode only. The partner
app already treats a missing phone or address as empty.

`notify_worker_about_booking` skips updates the assigned worker made themselves,
so accepting, moving through the stages, completing or cancelling a job no longer
raises an alert on the worker's own phone. New requests, reassignments and
customer or admin changes still do. Payout alerts (`Cash collected`,
`Settlement recorded`) are receipts and stay.

`my_cash_position()` returns `cash_in_hand`, `commission_due`, `limit` and `rate`
for the signed-in worker, zero before the first cash job. `cash_flow.sql` and
`booking_chat.sql` cover all three changes.

Migration 0032 was applied to the live project on 14 October 2026. Its rollback
preflight and the `cash_flow.sql` and `booking_chat.sql` regression suites passed.
