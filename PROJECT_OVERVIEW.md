# Kaylo: Comprehensive Project Guide

This document serves as the single source of truth for the Kaylo project. It outlines our project goals, progress, upcoming tasks for all team members, architectural decisions, and design patterns.

---

## 1. What We Are Doing (Our Aim)
We are building **Kaylo**, a comprehensive Flutter application designed to connect homeowners, farmers, and families with verified local professionals. 

Our initial target market is Kerala, and the app is built around three core pillars:
1. **Home Services:** Plumbing, electrical, cleaning, etc.
2. **Farm Services:** Harvesting, gardening, irrigation support.
3. **Kaylo Care (Senior Mode):** A dedicated, accessible mode for senior citizens offering medicine delivery, doctor appointments, emergency SOS, and a family management dashboard.

**The Two-Review Strategy:**
- **Review 1 (Foundation Demo):** A complete, working services marketplace for Home and Farm services. 
- **Review 2 (Advancements):** Launching the entire Kaylo Care ecosystem, live payments, live GPS tracking, and personalization.

---

## 2. What We Did Till Now (Review 1 Complete)
We have successfully completed the **Foundation Sprint** and the core requirements for Review 1:
- **Infrastructure:** Flutter project initialized, folder architecture (`core/` + `features/`) created, and Firebase configured.
- **Routing:** `go_router` setup with a `ShellRoute` for the bottom navigation and `routes.dart` constants.
- **State Management:** Riverpod `ProviderScope` integrated and `PROVIDERS.md` conventions established.
- **Design System:** `AppTheme`, `AppColors`, `AppTypography` created. A comprehensive UI widget kit (`KayloButton`, `KayloCard`, `KayloLiquidGlass`, etc.) is built and testable via a Widgetbook route.
- **M1 (Tech Lead) Progress:** Splash screen, Onboarding flow, and the Home Dashboard UI are implemented. Mock repositories for testing UI without backend dependency are set up.

---

## 3. Pending Work (Review 2: Advancements)
The following tasks are pending for Review 2, broken down by team member ownership:

### Member 1 (Tech Lead / Design System)
- **Care Mode:** Enable the Care mode switcher on the dashboard and route it to the Care Home tab.
- **Personalization:** Replace the static dashboard grid with personalized "Recommended Services" based on booking history, and add a live notification badge.
- **Theming:** Polish Dark Mode, implement Multilingual switching (English, Malayalam, Hindi), and build the `careTheme` (an accessible, high-contrast shell with large tap targets for seniors).

### Member 2 (Auth & Account)
- **Authentication:** Add Social Sign-in.
- **Settings:** Build out the Settings screen.
- **Care Integration:** Add the `careMode` user toggle.
- **Family Dashboard:** Build the Family Dashboard to manage relationships and linked accounts.

### Member 3 (Services & Discovery)
- **Filtering:** Implement sort/filter functionality for worker lists.
- **Profiles:** Build detailed Worker Profiles.
- **Care Integration:** Build the Doctor Appointment booking flow and Caregiver Booking flow (reusing R1 booking patterns).

### Member 4 (Booking & Payments)
- **Payments:** Integrate Razorpay for live payments.
- **Tracking:** Implement live GPS tracking for workers en route.
- **Post-Booking:** Add review submission, bookings history, and live push notifications.
- **Care Integration:** Build the Medicine Delivery flow (reusing the R1 order/payment engine).

### Member 5 (Farm & Care Lead)
- **Care Hub:** Build the Care Home dashboard (using M1's `careTheme` scaffold).
- **Features:** Implement Medicine Reminders and the Emergency SOS system.

---

## 4. File Structure & Contents
The repository is a pub workspace: two apps and the packages they share, with a **Feature-First Architecture** inside each app.

```text
apps/
├── customer/                 # The Kaylo app (customers)
│   ├── lib/main.dart         # Entry point: Supabase init, ProviderScope, device preview on web
│   ├── lib/core/             # App-only glue: router, global providers, bottom nav, localized widgets
│   ├── lib/features/         # Feature modules (see anatomy below)
│   │   ├── splash/ onboarding/ auth/ home/ workers/ booking/ farm/
│   │   ├── care/ messages/ notifications/ profile/
│   └── lib/l10n/             # .arb files for English, Malayalam, Hindi, Tamil + generated code
└── partner/                  # Kaylo Partner (workers): jobs inbox, job detail, availability, earnings

packages/
├── kaylo_core/               # Shared below the UI: models, Supabase client, AppFailure,
│                             # app_env, device services (location, speech, sound, storage, haptics)
└── kaylo_ui/                 # Shared look: AppColors, AppTypography, AppTheme (light, dark, care),
                              # the widget kit (KayloButton, KayloCard, KayloLiquidGlass, ...)

supabase/                     # One schema for both apps: migrations and seed
tools/                        # Asset-processing scripts
```

### Feature Folder Anatomy
Inside every feature folder (e.g., `apps/customer/lib/features/home/`), we follow Domain-Driven Design (DDD) principles:
- **`presentation/`**: Contains `screens/` (the UI pages) and `widgets/` (UI components specific to this feature).
- **`application/`**: Contains Riverpod controllers and StateNotifiers that manage the business logic and coordinate between the UI and repositories.
- **`domain/`**: Contains feature-specific models and the Repository interfaces (abstract classes).
- **`data/`**: Contains the concrete repository implementations (e.g., Firestore calls, Mock data).

---

## 5. Design Patterns & Styles

### State Management: Riverpod
We strictly use `flutter_riverpod` and `riverpod_annotation`.
- **Controllers:** Named `*ControllerProvider` (e.g., `dashboardControllerProvider`).
- **Logic:** Business logic lives in `Notifier` or `AsyncNotifier` classes, never in the UI.
- **Dependency Injection:** Repositories and Services are injected via Providers, allowing us to easily swap real Firestore calls with Mock repositories using the `--dart-define=USE_MOCK=true` flag.

### Routing: GoRouter
- **Declarative Navigation:** All routes are defined in `app_router.dart` and referenced via constants in `routes.dart` (e.g., `context.go(Routes.dashboard)`). No hardcoded string paths in UI files.
- **Bottom Navigation:** Managed via `StatefulShellRoute`, allowing nested navigation while keeping the bottom nav bar persistent and preserving tab state.

### UI & Styling
- **No Hardcoded Values:** All styling pulls from the Design Tokens in `core/theme/`.
  - Colors: `AppColors.brandPrimary`, `AppColors.surfaceMuted`.
  - Spacing: `AppSpacing.m`, `AppSpacing.l`.
  - Radii: `AppRadius.card`.
- **Responsive & Accessible:**
  - Components gracefully handle text scaling.
  - The upcoming `careTheme` enforces minimum `18sp` font sizes, `56x56` tap targets, and high contrast for senior users.
- **Visual Style (Glassmorphism):**
  - We use dynamic aesthetics like `KayloLiquidGlass` for cards and pills.
  - Modern typography (Poppins).
  - Smooth micro-animations (e.g., the animated bottom navigation pill).
