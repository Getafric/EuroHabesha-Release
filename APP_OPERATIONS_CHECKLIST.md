# App Operations Checklist

This file gives a fast, repeatable workflow for daily use of Euro Habesha.

## 1. Daily Start (Developer)

1. Run `flutter pub get`.
2. Run `flutter run`.
3. Press `R` once after startup when needed (full hot restart).

## 2. Firebase Admin Access Setup (One-Time)

1. Open Firestore Data:
   - https://console.firebase.google.com/project/eurohabesha-f3929/firestore/data
2. Ensure `admin_roles/{your_email_lowercase}` exists with:
   - `role: admin` (or `owner`)
   - `active: true`
3. Ensure `users/{your_uid}` includes:
   - `role: admin` (or `owner`)

## 3. Publish Flow (Admin)

1. Open Admin Panel -> Add Business.
2. Fill required fields and publish.
3. If publish fails with permission denied:
   - Re-check admin role docs above.
   - Re-deploy rules with task `Firebase: Deploy Firestore Rules`.

## 4. Submit -> Approve -> Notify Test (Core QA)

1. Normal user submits listing (`job_submissions`, status = `pending`).
2. Admin opens Verify/Audit and approves or rejects.
3. Confirm user inbox notification under:
   - `users/{uid}/notifications`
4. Confirm listing visibility if approved.

Pass criteria:
- Pending item created.
- Admin action succeeds.
- User gets inbox notification.

## 5. Push Notifications (Cloud Functions)

Functions were added for notification automation. If redeploy needed:

1. `npm install` inside `functions/`
2. Deploy functions (or use VS Code task):
   - `firebase deploy --only functions`

If deploy fails with IAM errors, use a project owner account and grant required service roles in Google Cloud.

## 6. Android Build Stability

Current stable build path uses NDK `27.0.12077973` pin in app module.

If build fails with missing `source.properties`:

1. Delete corrupted local NDK folder.
2. Reinstall via sdkmanager.
3. Rebuild debug APK.

## 7. Fast Troubleshooting Map

- Firestore host resolve errors on device:
  - Switch Wi-Fi/mobile data
  - Disable Private DNS temporarily
  - Ensure automatic date/time
  - Update Google Play Services
- Admin publish blocked:
  - Verify admin role fields in Firestore
  - Re-deploy Firestore rules
- Notifications missing:
  - Verify `users/{uid}/notifications` writes
  - Verify `deviceTokens` collection has token for current user

## 8. Useful Links

- Firestore Data: https://console.firebase.google.com/project/eurohabesha-f3929/firestore/data
- Firestore Rules: https://console.firebase.google.com/project/eurohabesha-f3929/firestore/rules
- Firebase Auth Users: https://console.firebase.google.com/project/eurohabesha-f3929/authentication/users
- Project Overview: https://console.firebase.google.com/project/eurohabesha-f3929/overview
- Cloud Functions (GCP): https://console.cloud.google.com/functions/list?project=eurohabesha-f3929
