# Euro Habesha Prelaunch 10-Step Checklist

This checklist is split into two lanes:
- In this repo: changes we can ship directly from code/config.
- Outside (Firebase/Store Console): settings you must enable in dashboards.

Status legend:
- [x] Done
- [ ] Pending

## 1) Guest-first onboarding flow
- [x] In repo: app starts in guest browsing mode.
- [x] In repo: auth prompt appears only when guest attempts protected actions.
- [x] In repo: login/register simplified to email + password.

Files:
- lib/main.dart
- lib/access_control.dart
- lib/login_screen.dart
- lib/registration_screen.dart
- lib/profile_screen.dart

## 2) Firestore Security Rules hardening
- [ ] Outside: deploy and validate firestore.rules in Firebase.
- [ ] Outside: test read/write matrix for guest vs signed-in users.

Command:
- firebase deploy --only firestore:rules

## 3) Storage security for uploaded documents/media
- [x] In repo: storage.rules added.
- [x] In repo: firebase.json updated to include storage rules.
- [ ] Outside: deploy storage rules.

Command:
- firebase deploy --only storage

## 4) Admin authorization on backend side
- [ ] Outside: configure backend-trusted admin identity (custom claims or secure admin collection with server checks).
- [ ] Outside: ensure only true admins can approve verification documents.

## 5) Legal document handling
- [ ] In repo: move legal document payloads from Firestore base64 fields to Firebase Storage references.
- [ ] Outside: verify only owner/admin can access document files.

## 6) Crash monitoring and analytics
- [ ] In repo: add Firebase Crashlytics dependency and initialization.
- [ ] Outside: enable Crashlytics in Firebase project and verify first test crash appears.

## 7) Auth quota and fallback behavior
- [x] In repo: removed phone OTP dependency from active flow.
- [ ] Outside: add test users and monitor Authentication quota alerts.
- [ ] Outside: verify email/password sign-up and login error handling under quota/network failures.

## 8) Abuse controls and moderation logging
- [ ] In repo: add report/block action for user-generated content.
- [ ] In repo: persist moderation audit logs (who approved/rejected, when, why).

## 9) Legal/compliance surfaces
- [ ] In repo: add Privacy Policy and Terms screens with links from profile/login.
- [ ] Outside: host final policy URLs for store submission.

## 10) Release build + store readiness
- [ ] Outside: create signed release keystore and set release signing config.
- [ ] Outside: verify release build on at least 3 physical devices + slow network.
- [ ] Outside: finalize store assets, support email, and release notes.

---

## High-priority next actions (recommended order)
1. Deploy Firestore + Storage rules.
2. Move legal documents to Storage (stop storing sensitive docs in Firestore documents).
3. Add backend-trusted admin authorization.
4. Add Crashlytics and run one internal test build.

## Firebase Console direct links
- Providers: https://console.firebase.google.com/project/eurohabesha-f3929/authentication/providers
- Auth settings: https://console.firebase.google.com/project/eurohabesha-f3929/authentication/settings
- Project settings: https://console.firebase.google.com/project/eurohabesha-f3929/settings/general
- Usage/quotas: https://console.firebase.google.com/project/eurohabesha-f3929/usage/details
