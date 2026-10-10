# Kaylo Partner

The worker app shares `kaylo_core` and `kaylo_ui` with the customer app. Its Android application ID is `com.kaylo.partner`.

## Sign-in and applications

Workers sign in with a Kaylo-issued partner ID and password. A temporary password must be changed before opening the rest of the app. Password recovery goes through Kaylo support at kayloapp@gmail.com.

Applicants do not need an account. The four-step form collects their details, services, payout method, consent and five private documents. Submission shows a reference number; the public status lookup returns only that reference and its status. The email address is required for credential delivery. Personal application details and documents are kept in memory during submission, not in local preferences.

See [BACKEND.md](../../BACKEND.md) for migrations 0024 and 0025, Firebase setup, deployment and the exact admin review, approval and credential-issue steps. Applying migrations alone does not enable email/password sign-in or deploy the edge functions.

## Demo

From the repository root, run `flutter pub get` once. Then:

```sh
cd apps/partner
flutter run --dart-define=USE_MOCK=true
```

Use `KP-000123` and `kaylo123`. The demo requires a new password on first sign-in. Applications and status lookups use an in-memory repository in mock mode.

Live mode uses the issued Firebase identity and Supabase worker profile, duty switch and availability. It deliberately shows an unavailable state for jobs and earnings while the shared job model PRs are still open. Mock mode retains the team's sample jobs and earnings. Live chat, alerts and reviews await the corresponding teammate screens.

Partner push registration uses `device_tokens.app = 'partner'`. A configured sender must send `type: booking_request` (or `new_job_request`) and `booking_id`. Android displays foreground job alerts using the packaged notification icon; the recipient must have granted notifications. Registering devices does not by itself send booking pushes.

## Validation and APKs

Analyze all four workspace members. Run both app suites in both time zones before pushing:

```sh
TZ=Asia/Kolkata flutter test
TZ=UTC flutter test
```

From the repository root, the release helper checks for at least 6 GiB of free disk and 6 GiB of total RAM, then builds sequentially with bounded Gradle memory:

```sh
python3 tools/build_release_apps.py both --check-only
python3 tools/build_release_apps.py both -- --dart-define=USE_MOCK=true
```

For live builds, pass your normal private `--dart-define-from-file` configuration instead. Keep configuration files and credentials out of Git. Outputs are copied to `build/releases/kaylo-partner-release.apk` and `build/releases/kaylo-customer-release.apk`. The helper does not configure store signing or remove files to make room.
