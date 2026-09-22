# kaylo_core

Code both Kaylo apps share below the UI layer:

- `models/`: `ServiceItem`, `Worker`, `Booking`, `AppUser`, kept in sync with the Supabase schema in `supabase/migrations`.
- `network/`: the Supabase client provider, `AppFailure` and the error mapper.
- `services/`: location (GPS plus reverse geocoding), speech, sound, storage, haptics, payments.
- `config/app_env.dart`: `USE_MOCK`, `SUPABASE_URL`, `SUPABASE_ANON_KEY` dart-defines.

Import with `package:kaylo_core/kaylo_core.dart`, or a single file such as `package:kaylo_core/models/booking.dart`.

This package must not depend on either app or on `kaylo_ui`.
