# Kaylo Developer Guide

## 1. First-time setup

```bash
git clone https://github.com/KayloLabs/kaylo-app.git
cd kaylo-app
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK=true
```

`USE_MOCK=true` runs the app with sample data. To connect to the real
database, see BACKEND.md.

## 2. Daily workflow

1. `git checkout main` and `git pull`
2. `git checkout -b feat/short-task-name` (never work directly on main)
3. Write your code
4. Run `flutter analyze` and `flutter test` until both pass
5. Commit in small steps: `git commit -m "feat(booking): add date picker"`
6. `git push -u origin feat/short-task-name` and open a Pull Request
7. CI runs automatically. A green check and one review are required to merge

## 3. Where to add your code

Each feature lives in its own folder:

```
lib/features/<feature>/
  presentation/screens/   screens
  presentation/widgets/   widgets used only by this feature
  application/            Riverpod providers and controllers
  domain/                 repository interface
  data/                   mock and Supabase repository implementations
```

Example: booking screens belong in `lib/features/booking/presentation/screens/`.
The `features/home/` folder is the reference implementation of this pattern.

## 4. Shared code

- `lib/core/` is maintained by M1. To change a shared model in
  `core/models/`, request it from M1 instead of editing directly.
- Use the shared widgets: `KayloButton`, `KayloCard`, `KayloListTile`,
  `KayloSnackbar`, `KayloLiquidGlass`.
- Call `KayloFeedback.tap()` or `KayloFeedback.press()` on interactions
  (`core/services/feedback_service.dart`) for haptics and sound.
- Take colors, spacing, and radii from `core/theme/`. Do not hardcode values.

## 5. On-screen text (localization)

All user-visible text must be localized:

1. Add the key to all four files: `lib/l10n/app_en.arb`, `app_ml.arb`,
   `app_hi.arb`, `app_ta.arb`
2. Run `flutter gen-l10n` and commit the generated files
3. Use it in code: `AppLocalizations.of(context)!.myKey`

CI rejects the PR if the generated files are out of date. Note that Tamil
and Malayalam text is longer than English; use `AutoSizeText` or `Flexible`
in fixed-size layouts and check your screen in Tamil once.

## 6. Backend access

Screens never call Supabase directly. The flow is:
screen → provider (`application/`) → interface (`domain/`) →
implementation (`data/`). Database tables, views, and policies are
documented in BACKEND.md and `supabase/`.

## 7. Ownership

| Member | Area |
|---|---|
| M1 | core, theme, models, dashboard, navigation, CI, reviews |
| M2 | authentication, login and signup, user profile data |
| M3 | services, worker list, worker details |
| M4 | booking flow, payments, bookings tab |
| M5 | messages and Care features (reminders, SOS, caregiver) |
