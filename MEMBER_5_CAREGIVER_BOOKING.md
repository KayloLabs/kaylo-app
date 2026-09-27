# M5 (Sandeep): finishing the caregiver booking

Hi Sandeep. The farm flow, messages and the whole Care section you built are
the heart of the demo, so this next piece is a natural continuation: taking
the caregiver booking from "works" to "feels finished", the way the farm flow
does. It is Flutter-only work with the mock data, nothing on the Supabase
side; M1 adds the table later and implements the interface you leave behind.

If you want a picture of the target: **Urban Company** (pick a slot, add a
note, get a receipt, see it under Upcoming) and **Practo** (care bookings
listed with a cancel).

---

## Where the flow stands today

Run the app with mocks, open the Care tab, tap **Book a Caregiver** and
confirm one. Then have a look at the confirm button in
`apps/customer/lib/features/care/presentation/screens/caregiver_booking_screen.dart`
(around lines 360 to 410). A few things were stubbed to get the flow moving,
and now they can become real:

| Today | What we want |
|---|---|
| The start time is fixed at `'09:00 AM'` | The customer picks a slot |
| The notes are fixed text | An optional notes field |
| The Bookings-tab copy is saved for user `'u1'` | The signed-in user |
| A failed save is caught silently | A small error message, and the screen stays put |
| The flow ends with a snackbar and `pop()` | The shared receipt screen, like the farm flow |
| Care Home does not show the visit afterwards | An "Upcoming care visits" list with cancel |

The farm flow is a good model for the ending:
`features/farm/presentation/screens/farm_payment_screen.dart`, the
`context.go(Routes.bookingConfirmation, extra: BookingReceipt(...))` call.

---

## Getting set up

```bash
git checkout main
git pull                                  # start from the latest main
flutter pub get                           # once, at the repo root (pub workspace)
cd apps/customer
flutter run -d chrome --dart-define=USE_MOCK=true
git checkout -b feat/m5-caregiver-booking
```

Worth a read before coding, in this order:

1. `CONTRIBUTING.md`: the daily workflow (§2), where code goes (§3), shared
   code (§4), localization (§5), and the screen → provider → interface →
   implementation flow (§6).
2. `features/care/domain/care_repository.dart` (the interface),
   `features/care/data/mock_care_repository.dart` (your implementation),
   `features/care/application/care_providers.dart` (`caregiverBookingsProvider`).
3. `features/farm/presentation/screens/farm_payment_screen.dart` and
   `features/booking/domain/booking_receipt.dart` (the receipt you can reuse).
4. `test/care_flows_test.dart`, to see how care screens are tested.

---

## Things to keep in mind

**The Kaylo look.** Colours, spacing and radii come from `kaylo_ui`
(`AppColors`, `AppSpacing`, `AppRadius`) and text styles from
`Theme.of(context).textTheme`, so the new pieces match the rest without
effort. Care screens run under `careTheme`
(`packages/kaylo_ui/lib/theme/app_theme.dart`), which is tuned for seniors:
18 sp body text and 56 by 56 tap targets. Keeping the theme's sizes as they
are is enough; just avoid shrinking anything for fit. The shared widgets
(`KayloButton`, `KayloCard`, `KayloChip`, `KayloListTile`, `KayloSnackbar`,
`SectionHeader`, `EmptyState`) cover everything this task needs, and the care
type chips already on the screen (`ChoiceChip`, near line 94) show the
selected and unselected look to match for the time slots. A
`KayloFeedback.tap()` on selections and `KayloFeedback.press()` on confirm
gives the haptics and sound the other flows have, and `formatRupees`
(`kaylo_core`) formats money the Indian way.

Two quick checks at the end make a big difference: once with **Care Mode**
on (Profile → Settings → Care Mode) and once in Tamil, since both change the
sizes a lot.

**Localization.** Each visible string goes into the four files
(`lib/l10n/app_en.arb`, `app_ml.arb`, `app_hi.arb`, `app_ta.arb`), then
`flutter gen-l10n` inside `apps/customer`, with the generated files committed
(CI checks they are current). For times and dates,
`MaterialLocalizations.of(context).formatTimeOfDay` and `DateFormat` from
`intl` handle the locale, so nothing needs a hand-written "AM".

**Architecture.** Screen → provider → `CareRepository` → `MockCareRepository`,
as everywhere else. No Supabase calls in this PR. If you add a method to the
interface, `SupabaseCareRepository` needs it too so it compiles; the two
caregiver methods at the bottom of that file show the one-line
`return _fallback.yourMethod(...)` to copy.

**Shared code.** `CaregiverBookingRecord` lives in the customer app
(`features/care/domain/models/caregiver.dart`), so it is yours to extend.
Models in `packages/kaylo_core/lib/models/` are shared by both apps; a quick
word with M1 before changing one saves a merge headache.

**Git.** Small commits with conventional messages (`feat(care): time slot
chips`), your own git identity, no AI attribution lines. `flutter analyze` and
`flutter test` green before each push keeps CI happy.

---

## The work, in a sensible order

### 1. Pick a start time (screen)

A **Start time** section under the date picker: chips in two rows, Morning
(07:00, 09:00, 11:00) and Afternoon (14:00, 16:00), with 09:00 selected by
default. Keep the choice as a `TimeOfDay` in the screen state, and the slot
list in care code, for example a `caregiverSlots` constant next to
`CaregiverBookingRecord`.

On confirm:
- `startTime` on the record is the formatted label
  (`MaterialLocalizations.of(context).formatTimeOfDay`).
- The `Booking` copy's `scheduledAt` is the date **plus the slot**, so the
  Bookings tab sorts and shows it at the right time.

### 2. Notes (screen)

An optional multiline `TextField` (`maxLines: 3`, `maxLength: 200`) titled
"Anything the caregiver should know?" with a hint like "Medicines, mobility,
food, language". The app theme already styles inputs. Empty text saves as
`notes: null`.

### 3. The signed-in user, and a real receipt

- `'u1'` becomes `ref.read(currentUserIdProvider)`
  (`features/auth/application/current_user_provider.dart`). When it is null
  (signed-out preview), still save the care record and skip the Bookings-tab
  copy.
- The empty `catch (_) {}` can go. If either write throws,
  `KayloFeedback.alert()` plus `KayloSnackbar.showError` with a localized
  string, and the screen stays put.
- On success, the same ending the farm flow has:

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

The snackbar and `context.pop()` are no longer needed;
`BookingConfirmationScreen` brings the tick animation and the chime with it.

### 4. Upcoming care visits on Care Home

In `care_home_screen.dart`, between the three action cards and the SOS card:

- `SectionHeader(title: l10n.upcomingCareVisits)`.
- The list from `caregiverBookingsProvider`, filtered to
  `status == 'confirmed'` with a date from today onward, newest first, at most
  three. Each row a `KayloCard`: caregiver name (title), care type with the
  date and start time (subtitle, one line, ellipsis), the total
  (`formatRupees(totalAmount)`), and a **Cancel** text button.
- With nothing booked: `EmptyState` with "No caregiver visits booked yet" and
  a button to the booking screen.
- Cancel asks first (an `AlertDialog`: "Cancel this visit?", "Keep it",
  "Cancel visit"), then:
  1. `CareRepository.cancelCaregiverBooking(String id)`, a new interface
     method: `MockCareRepository` sets the record's status to `'cancelled'`,
     `SupabaseCareRepository` gets the one-line delegation.
  2. A `cancel(id)` on the notifier behind `caregiverBookingsProvider` that
     calls it and refreshes the state.
  3. The Bookings-tab copy is cancelled through the repository method Booking
     Details already uses
     (`features/booking/presentation/screens/booking_details_screen.dart`
     shows the call).
  4. `KayloSnackbar.showSuccess(context, l10n.visitCancelled)`.

Status values are `'confirmed'`, `'completed'` and `'cancelled'`, matching the
check constraint `doctor_appointments` has in
`supabase/migrations/0004_care_doctors_caregivers.sql`; the caregiver table
will use the same.

### 5. A small model tidy

On `CaregiverBookingRecord`: a `copyWith`, a `bool get isUpcoming`, and a
`DateTime get scheduledAt` combining `date` and the slot so the two screens
share one definition. The constructor is used by the mock repository, the
booking screen and the tests, so keeping it compatible avoids churn.

### 6. Tests (in the style of `test/care_flows_test.dart`)

A new `test/caregiver_booking_test.dart` covering:

1. choosing a slot and typing notes, then confirming, lands on the receipt
   with the caregiver's name and the chosen time;
2. Care Home then lists that visit under Upcoming;
3. cancelling it (confirming in the dialog) removes it from Upcoming;
4. the new section renders in Malayalam without overflow
   (`care_home_smoke_test.dart` shows how to pump a locale).

`testApp`, `settle` and `useTallPhone` in `test/support/test_app.dart` do the
setup. One tip that saves an afternoon: `pumpAndSettle` hangs here because the
mock repositories answer after a delay and the loaders animate forever;
`settle` (a handful of pumps) is the helper that works.

---

## Strings to add

English below; the Malayalam, Hindi and Tamil are yours. Short is good, Tamil
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

Already there and reusable: `caregiverBooking`, `caregiverBooked`,
`selectCaregiver`, `bookNow`, `cancel`.

---

## When it is done, we should be able to

- [ ] Pick a slot and add notes on screen, with nothing about the visit fixed in code.
- [ ] Confirm and land on the shared receipt showing caregiver, care type, start time, duration.
- [ ] See the visit on Care Home under Upcoming, and in the Bookings tab at the right date and time.
- [ ] Cancel from Care Home, after a confirmation, and see both lists update.
- [ ] Use the signed-out preview without a crash on the null user id.
- [ ] Read every new string in the four languages, with the generated files committed and Tamil checked.
- [ ] Turn Care Mode on and find everything still comfortable: theme sizes intact, 56 dp targets.
- [ ] Run `flutter analyze` clean and `flutter test` green, the four new tests included.
- [ ] Confirm nothing in the Supabase repository changed beyond the one-line delegations.

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

## Opening the PR

- Branch `feat/m5-caregiver-booking` off a fresh `main`, one PR to `main`; Nimal merges.
- Conventional commit messages, your own identity, no AI attribution.
- Two screenshots in the PR body help the review a lot: the booking screen with a slot chosen, and Care Home showing an upcoming visit, one of them in Care Mode.

## Not needed for this task (we take care of these)

- The `caregiver_bookings` table, RLS and the Supabase repository (M1).
- Payments for care visits (M4).
- The caregiver's side of the booking in the partner app (M4).

Any doubt along the way, ping Nimal on the PR or in the group; a draft PR
early is welcome.
