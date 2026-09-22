# Kaylo Partner

The app workers use: see booking requests near them, accept or decline, update a job's status, chat with the customer, manage availability and skills, and see earnings.

It shares `kaylo_core` (models, Supabase access, device services) and `kaylo_ui` (theme and widgets) with the customer app in `apps/customer`, and talks to the same Supabase project. Worker-side row-level security already exists in `supabase/migrations/0002_rls_policies.sql` (`current_worker_id()`), so this app is a client of the existing schema.

Status: skeleton. It boots with the shared theme and a placeholder home; the jobs inbox, job detail and worker sign-in come next.

```bash
cd apps/partner
flutter run --dart-define=USE_MOCK=true
```

Bundle id `com.kaylo.kaylo_partner` (set by `flutter create --org com.kaylo`); rename before the first store upload if a shorter id is wanted.
