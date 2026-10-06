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

The short sounds (logo chime, the five notes, coupon stamp, reward reveal) are synthesised by `apps/customer/tool/make_sounds.py` into `apps/customer/assets/`; nothing is a recording.

`supabase/tests/booking_offers.sql` contains rollback-only SQL checks using synthetic accounts. Run it after the migration; it does not keep test bookings. Customer tests cover eligible amounts, failed-payment retry totals, search relevance, saved-address switching, and booking coordinate handoff.

The worker verification screen displays the existing Kaylo verification status. There are no uploaded qualification documents, verification dates, or independent check records in the current schema; the UI does not invent them.
