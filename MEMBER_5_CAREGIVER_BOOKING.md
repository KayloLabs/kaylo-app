# M5 (Sandeep): Caregiver booking, finished (mock-first)

Owner: Sandeep (`sandeep2006-c`). Branch off `main`, one PR, Nimal merges.
Everything here runs behind `USE_MOCK=true` and touches **no Supabase**.
`SupabaseCareRepository` already hands caregiver bookings to the mock
(`data/supabase_care_repository.dart`, the two methods near the bottom); M1
adds the table later and implements the interface you leave behind. Your job
is the Flutter side: make the flow complete and worth showing in the demo.

Reference apps: **Urban Company** (book a service: slot, notes, receipt, then
the booking in "Upcoming"), **Practo** (care bookings listed with a cancel).

---

## What is wrong today

Open the app with mocks, Care tab, **Book a Caregiver**, and confirm one.
Then read `apps/customer/lib/features/care/presentation/screens/caregiver_booking_screen.dart`
around the confirm button (lines 360 to 410):

| Problem | Where |
|---|---|
| Start time is a literal `'09:00 AM'`; the customer never picks one | `startTime: '09:00 AM'` |
| Notes are a literal `'Caregiver visit for senior'` | `notes: ...` |
| The Bookings-tab copy is created for user `'u1'` instead of the signed-in user | `userId: 'u1'` |
| Failure of that copy is swallowed by an empty `catch (_) {}` | same block |
| The flow ends in a snackbar and `context.pop()`; the farm flow lands on a proper receipt | `KayloSnackbar.showSuccess(...)` |
| Care Home never shows the visit afterwards, and nothing can be cancelled | `care_home_screen.dart` |

The farm flow is the reference for how a Kaylo booking should end:
`features/farm/presentation/screens/farm_payment_screen.dart` (the `context.go(Routes.bookingConfirmation, extra: BookingReceipt(...))` call).

---

## Before you start

```bash
git checkout main
git pull                                  # always start from the latest main
flutter pub get                           # once, at the repo root (pub workspace)
cd apps/customer
flutter run -d chrome --dart-define=USE_MOCK=true
git checkout -b feat/m5-caregiver-booking # never work on main
```

Then read, in this order:

1. `CONTRIBUTING.md`, all of it: daily workflow (§2), where code goes (§3),
   shared code (§4), localization (§5), the screen → provider → interface →
   implementation rule (§6).
2. `features/care/domain/care_repository.dart` (the interface),
   `features/care/data/mock_care_repository.dart` (your implementation),
   `features/care/application/care_providers.dart` (`caregiverBookingsProvider`).
3. `features/farm/presentation/screens/farm_payment_screen.dart` and
   `features/booking/domain/booking_receipt.dart` (the receipt you will reuse).
4. `test/care_flows_test.dart` (how care screens are tested).

---

## Rules for this task

**Kaylo theme, always.**
- Colours, spacing and radii come from `kaylo_ui`: `AppColors`, `AppSpacing`,
  `AppRadius`. No hex values, no `Colors.blue`, no magic numbers for padding.
- Text styles come from `Theme.of(context).textTheme`. Never set a font size
  smaller than what the theme gives you: Care screens run under `careTheme`
  (`packages/kaylo_ui/lib/theme/app_theme.dart`), which is built for seniors,
  18 sp minimum body text, 56 by 56 tap targets, high contrast. Keep every new
  button and chip at least that big.
- Use the shared widgets: `KayloButton`, `KayloCard`, `KayloChip`,
  `KayloListTile`, `KayloSnackbar`, `SectionHeader`, `EmptyState`. The care
  type chips already on the screen (`ChoiceChip` near line 94) show the
  selected and unselected look; match it for the new time slot chips.
- `KayloFeedback.tap()` on selections, `KayloFeedback.press()` on confirm,
  `KayloFeedback.alert()` on an error, before the action.
- Money through `formatRupees` (`kaylo_core`), never string-built rupees.
- Check the screen once with **Care Mode** on (Profile → Settings → Care
  Mode) and once in Tamil; both change sizes a lot.

**Localization.** Every visible string goes into all four files
(`lib/l10n/app_en.arb`, `app_ml.arb`, `app_hi.arb`, `app_ta.arb`), then
`flutter gen-l10n` inside `apps/customer`, and the generated files are
committed. CI fails the PR if they are stale. Times are formatted with
`MaterialLocalizations.of(context).formatTimeOfDay`, dates with
`DateFormat` from `intl` using the current locale, so nothing says "AM" by hand.

**Architecture.** Screens talk to providers, providers to `CareRepository`,
`MockCareRepository` does the work. No Supabase calls anywhere in this PR. If
you add a method to the interface, `SupabaseCareRepository` must compile, so
give it the same one-line delegation the two caregiver methods already use
(`return _fallback.yourMethod(...)`).

**Shared code.** `CaregiverBookingRecord` lives in the customer app
(`features/care/domain/models/caregiver.dart`), so you may extend it. Models in
`packages/kaylo_core/lib/models/` are M1's; ask before touching them.

**Git.** Small commits with conventional messages (`feat(care): time slot
chips`), your own git identity, no AI attribution lines of any kind.
`flutter analyze` and `flutter test` green before every push.

---

## The work, in this order

### 1. Pick a start time (screen)

Add a **Start time** section under the date picker. Show slots as chips in
two rows, Morning (07:00, 09:00, 11:00) and Afternoon (14:00, 16:00), with one
selected by default (09:00). Store the choice as a `TimeOfDay` in the screen
state and keep the slot list in care code, for example a
`caregiverSlots` constant next to `CaregiverBookingRecord`.

On confirm:
- `startTime` on the record is the formatted label (use
  `MaterialLocalizations.of(context).formatTimeOfDay`).
- The `Booking` copy's `scheduledAt` is the date **plus the slot**, not just
  the date, so the Bookings tab sorts and shows it correctly.

### 2. Notes (screen)

An optional multiline `TextField` (`maxLines: 3`, `maxLength: 200`) titled
"Anything the caregiver should know?" with a localized hint such as
"Medicines, mobility, food, language". The app theme already styles inputs;
do not restyle it. Empty text saves as `notes: null`.

### 3. The signed-in user, and a real receipt

- Replace `'u1'` with `ref.read(currentUserIdProvider)`
  (`features/auth/application/current_user_provider.dart`). If it is null the
  person is signed out: still save the care record, skip the Bookings-tab
  copy.
- Delete the empty `catch (_) {}`. If either write throws, call
  `KayloFeedback.alert()` and `KayloSnackbar.showError` with a localized
  string, and stay on the screen.
- On success, do exactly what the farm flow does:

```dart
KayloFeedback.press();
context.go(
  Routes.bookingConfirmation,
  extra: BookingReceipt(
    booking: booking,                     // the Booking you just created
    service: caregiverVisitService,       // id '8' from fullCatalogProvider
    paymentMethod: PaymentMethod.payAfterService,
    extras: [
      ReceiptLine(l10n.caregiver, caregiver.name),
      ReceiptLine(l10n.careType, careTypeLabel),
      ReceiptLine(l10n.startTime, startTimeLabel),
      ReceiptLine(l10n.duration, l10n.hoursCount(hours)),
    ],
  ),
);
```

Remove the snackbar and the `context.pop()`. `BookingConfirmationScreen`
already plays the tick animation and the chime; you get those for free.

### 4. Upcoming care visits on Care Home

In `care_home_screen.dart`, below the three action cards and above the SOS
card, add:

- `SectionHeader(title: l10n.upcomingCareVisits)`.
- The list from `caregiverBookingsProvider`, filtered to
  `status == 'confirmed'` and a date from today onward, newest first, at most
  three. Each row is a `KayloCard` with: caregiver name (title), care type and
  the date and start time (subtitle, one line, ellipsis), the total
  (`formatRupees(totalAmount)`), and a **Cancel** text button.
- When there are none: `EmptyState` with "No caregiver visits booked yet" and
  a button that opens the booking screen.
- Cancel asks first (an `AlertDialog` with localized "Cancel this visit?",
  "Keep it" and "Cancel visit"), then:
  1. `CareRepository.cancelCaregiverBooking(String id)`: new interface method,
     implemented in `MockCareRepository` by setting the record's status to
     `'cancelled'`, and delegated with one line in `SupabaseCareRepository`.
  2. A `cancel(id)` method on the notifier behind `caregiverBookingsProvider`
     that calls it and refreshes the state.
  3. The Bookings-tab copy is cancelled through the same repository method
     Booking Details already uses (`features/booking/presentation/screens/booking_details_screen.dart`
     shows the call).
  4. `KayloSnackbar.showSuccess(context, l10n.visitCancelled)`.

Status values are exactly `'confirmed'`, `'completed'`, `'cancelled'`; that is
the check constraint `doctor_appointments` already has in
`supabase/migrations/0004_care_doctors_caregivers.sql`, and the caregiver
table will match it.

### 5. Small model tidy

On `CaregiverBookingRecord`: add `copyWith`, `bool get isUpcoming`, and a
`DateTime get scheduledAt` that combines `date` and the slot so the two
screens do not each parse the label. Keep the constructor compatible: the mock
repository, the booking screen and the tests all construct it.

### 6. Tests (`test/care_flows_test.dart` style)

Add `test/caregiver_booking_test.dart` with, at least:

1. choosing a slot and typing notes, then confirming, lands on the receipt
   screen showing the caregiver's name and the chosen time;
2. Care Home then lists that visit under Upcoming;
3. cancelling it (confirm in the dialog) removes it from Upcoming;
4. the new section renders in Malayalam without overflow
   (`care_home_smoke_test.dart` shows how to pump a locale).

Use `testApp`, `settle` and `useTallPhone` from `test/support/test_app.dart`.
Never `pumpAndSettle`: the mock repositories answer after a delay and loaders
animate forever, so `settle` (a handful of pumps) is what works here.

---

## Strings to add

English below; you write Malayalam, Hindi and Tamil. Keep them short, Tamil
runs about 40 percent longer than English.

| Key | English |
|---|---|
| `startTime` | Start time |
| `morning` | Morning |
| `afternoon` | Afternoon |
| `notesForCaregiver` | Anything the caregiver should know? |
| `notesForCaregiverHint` | Medicines, mobility, food, language |
| `caregiver` | Caregiver |
| `careType` | Care type |
| `duration` | Duration |
| `hoursCount` | `{count, plural, one{1 hour} other{{count} hours}}` |
| `upcomingCareVisits` | Upcoming care visits |
| `noCareVisitsYet` | No caregiver visits booked yet |
| `cancelVisit` | Cancel visit |
| `cancelVisitQuestion` | Cancel this visit? |
| `keepVisit` | Keep it |
| `visitCancelled` | Visit cancelled |
| `bookingFailed` | Could not save the booking. Please try again. |

Reuse what already exists: `caregiverBooking`, `caregiverBooked`,
`selectCaregiver`, `bookNow`, `cancel`.

---

## Definition of done

- [ ] Slot and notes are chosen on screen; nothing about the visit is a literal in code.
- [ ] Confirm lands on the shared receipt with caregiver, care type, start time, duration.
- [ ] The visit appears in Care Home under Upcoming, and in the Bookings tab at the right date and time.
- [ ] Cancel works from Care Home, with a confirmation, and updates both lists.
- [ ] Signed-out preview still works (no crash on a null user id).
- [ ] All new strings in four languages, `flutter gen-l10n` output committed, Tamil checked.
- [ ] Looks right with Care Mode on: nothing smaller than the theme, tap targets 56 dp.
- [ ] `flutter analyze` clean, `flutter test` green (the four new tests included).
- [ ] No Supabase code touched beyond the one-line delegations.

---

## Running and testing

```bash
flutter pub get                                  # once, at the repo root
cd apps/customer
flutter run -d chrome --dart-define=USE_MOCK=true
flutter analyze
flutter test
flutter test test/caregiver_booking_test.dart    # just yours, while iterating
```

## PR checklist

- Branch `feat/m5-caregiver-booking` off a fresh `main`, one PR to `main`, Nimal merges.
- Conventional commit messages, your own identity, no AI attribution.
- Screens use `kaylo_ui` widgets and theme tokens; no hardcoded colours, sizes or strings.
- Strings in en, ml, hi, ta; generated files committed.
- Two screenshots in the PR body: the booking screen with a slot chosen, and Care Home showing an upcoming visit, one of them in Care Mode.

## Out of scope (do not start these)

- The `caregiver_bookings` table, RLS and the Supabase repository (M1).
- Payments for care visits (M4).
- The caregiver's side of the booking (partner app, M4).
