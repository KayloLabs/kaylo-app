# Member 2 — Authentication, Account & Family

**Role:** Own the gate every user passes through (auth), plus the account surfaces. In R2 you take the **Family Dashboard** — it's a natural extension of accounts and relationships. You also co-lead the Foundation Sprint (Firebase side).

**R1 owns:** Login, Sign Up, OTP Verify, Location Setup, Profile. Plus Firebase/infra tasks in `FOUNDATION_SPRINT.md`.
**R2 owns:** Settings, Google/Apple sign-in, Care-mode toggle, **Family Dashboard**.
**Depends on:** M1's UI kit, `AppUser`, `LocationService`, `StorageService`.
**Branch prefix:** `feature/m2-*`

---

# REVIEW 1 — Foundation Demo

## Core auth infra you build
- `AuthRepository` (interface + Firebase impl): sign up, phone-OTP send/verify, sign out, current-user stream.
- `SessionController` (`AsyncNotifier<AppUser?>`): the app's **auth source of truth** — M1's router redirect + auto-login listen to this. Persist token via `StorageService`.

## Screens
- **Login** — mobile + password (obscure toggle), Forgot password, Login button, "or continue with" placeholder (Google/Apple wired in R2). Phone/password validation, friendly error mapping, loading states.
- **Sign Up** — name, mobile, password → OTP send. Create `users/{uid}` (role `customer`, `careMode=false`) on first verify.
- **OTP Verify** — 6 boxed inputs (auto-advance, paste, backspace nav), "Resend in 00:25" countdown, Firebase verify, expired/wrong-code handling, Android SMS autofill if feasible.
- **Location Setup** — "Enable location," map preview, detected label ("Kochi, Kerala"), manual pick fallback, Confirm → writes `users/{uid}.activeLocation` (used by M3 discovery + M4 booking address).
- **Profile** — avatar, name, "View profile"; rows: My Addresses, Payment Methods, Service History, Help & Support (deep-link out). Edit name + photo (`image_picker` → Storage).

## R1 Definition of Done
- [ ] Sign-up → OTP → account creation, and login working on real Firebase
- [ ] `SessionController` exposed for router + auto-login
- [ ] Location capture with permission + manual fallback, written to user doc
- [ ] Profile view + edit (photo upload)
- [ ] All flows: loading/error/empty, i18n, validation

---

# REVIEW 2 — Advancements

## R2.1 Settings
- Rows: **Language** (en/ml/hi → flips app locale with M1's localization), **Notifications** (toggle categories, reads/writes FCM prefs via M4's service), Privacy Policy, Terms, **Logout** (clears session → Login).
- **Care Mode toggle** — sets `users/{uid}.careMode=true`; coordinates with M1 so the dashboard defaults to the Care tab. This is the switch that turns on the R2 senior experience.

## R2.2 Social sign-in
- Google + Apple via `firebase_auth` providers, wired into the Login "continue with" buttons. Handle account-linking + first-login profile creation.

## R2.3 Family Dashboard (R2 Care pillar)
- "My Parents" list (e.g. Amma — Kochi, Appa — Kochi) + **Add Family Member**.
- Model with `families/{familyId}` linking accounts; a family member (possibly abroad) can act on a linked parent: book services, view/manage the parent's appointments + medicine reminders (M5's data), and receive notifications. **Enforce permission** — only linked members act on a parent.
- Tapping a parent → their profile/booking view. Shared family notifications via M4's FCM.

## R2 Definition of Done
- [ ] Settings incl. language switch, notification prefs, care-mode toggle, logout
- [ ] Google + Apple sign-in working
- [ ] Family Dashboard: link/unlink parents, permissioned remote actions, family notifications
- [ ] All states + i18n; widget tests for OTP input + family permission logic

**Integration you provide:** `SessionController`/`AuthRepository` (M1 router + everyone), `activeLocation` (M3/M4), `careMode` flag (M1 dashboard, M5 Care), family/permission model (M5's care features, M4's notifications).
