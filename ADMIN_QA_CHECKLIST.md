# Admin QA Checklist

Use this quick checklist every time you validate submit -> review -> notify flow.

## A. Pre-Check

- [ ] App is running (`flutter run`) and hot restart done (`R`)
- [ ] Admin account can open Admin Panel
- [ ] Hidden Admin QA Dashboard opens (long-press Admin panel title)
- [ ] Normal user account can submit listing
- [ ] Firestore connectivity works (no host resolve errors)

## B. Submit Phase (Normal User)

- [ ] User submits a new listing from Jobs/Services
- [ ] Document appears in `job_submissions`
- [ ] Submission has `status = pending`
- [ ] Submission has `userId`, `title`, `category`, `city`, `phone`

Pass if all are checked.

## C. Admin Review Phase

- [ ] Admin opens Verify/Audit tab
- [ ] New pending item is visible
- [ ] Admin can click Approve
- [ ] Admin can click Reject (separate test)

Pass if no permission error is shown.

## D. Approval Path Validation

- [ ] On approve, `job_submissions/{id}.status` becomes `approved`
- [ ] New document is created in `jobs`
- [ ] Listing appears in Jobs/Services UI
- [ ] User receives inbox notification in `users/{uid}/notifications`
- [ ] Notification title/body indicates approval

## E. Rejection Path Validation

- [ ] On reject, `job_submissions/{id}.status` becomes `rejected`
- [ ] User receives inbox notification in `users/{uid}/notifications`
- [ ] Notification title/body indicates rejection

## F. Push Notification Validation (Optional but Recommended)

- [ ] `deviceTokens` contains token for admin user
- [ ] `deviceTokens` contains token for submitter user
- [ ] Admin gets review push for pending submission
- [ ] Submitter gets push after approve/reject

If inbox works but push banner does not show, check Android notification settings and battery optimization.

## G. Cloud Functions Health

- [ ] `onJobSubmissionCreatedNotifyAdmins` executes successfully
- [ ] `onJobSubmissionStatusChangedNotifyUser` executes successfully
- [ ] No critical function error in logs

Logs:
- https://console.cloud.google.com/functions/list?project=eurohabesha-f3929

## H. Fast Fail Mapping

- If submit fails: check Firestore rules + network
- If admin cannot review: check admin role (`admin_roles` / `users.role`)
- If user not notified in inbox: check write path `users/{uid}/notifications`
- If push missing only: check FCM token + device notification settings

## I. Final Result

- [ ] PASS (Submit + Review + Inbox notify all successful)
- [ ] PARTIAL (Core works, push banner missing)
- [ ] FAIL (Core flow blocked)
