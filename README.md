<div align="center">

# KayloLabs

### Building the future of trusted local services.

**Coming Soon.**

<br>

<sub>

Kaylo • カイロ • 카일로 • 凯洛 • कैलो • কেলো • કેલો • ਕੈਲੋ • କେଲୋ • கெய்லோ • కైలో • ಕೈಲೋ • കൈലോ • كايلو • Кайло • Κάιλο

</sub>
<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/kaylo_logo_dark.png">
  <img src="packages/kaylo_ui/assets/kaylo_transparent.png" alt="Kaylo" width="600">
</picture>

</div>

## Repository layout

One repository, two apps, shared packages (a pub workspace):

```
apps/
  customer/   the Kaylo app customers use to book home, farm and care services
  partner/    the app workers use to receive and complete those bookings
packages/
  kaylo_core/ models, Supabase access, device services (shared)
  kaylo_ui/   theme and widgets (shared)
supabase/     the one schema both apps talk to: migrations and seed
tools/        asset-processing scripts
```

Each app ships as its own store listing with its own bundle id and version; they share code through the packages, so a booking looks the same on both sides and one migration folder owns the database.

## Working in the repo

```bash
flutter pub get                       # once, at the root: resolves the whole workspace
cd apps/customer && flutter run --dart-define=USE_MOCK=true
cd apps/partner  && flutter run --dart-define=USE_MOCK=true
```

Add `--dart-define=GOOGLE_MAPS_API_KEY=...` to show the map in the location
picker; without it the map area is a placeholder (setup in
[BACKEND.md](BACKEND.md), Google Maps).

Analyze and test from inside the member you changed (`flutter analyze`, `flutter test`); CI does the same for every member. Backend setup is in [BACKEND.md](BACKEND.md), team conventions in [CONTRIBUTING.md](CONTRIBUTING.md).
