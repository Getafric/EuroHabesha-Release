const admin = require('firebase-admin');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');

admin.initializeApp();

async function getAdminUids() {
  const firestore = admin.firestore();
  const uids = new Set();

  const usersSnap = await firestore.collection('users').where('role', 'in', ['owner', 'admin', 'subadmin']).get();
  usersSnap.docs.forEach((doc) => {
    if (doc.id) uids.add(doc.id);
  });

  const rolesSnap = await firestore.collection('admin_roles').get();
  for (const roleDoc of rolesSnap.docs) {
    const contact = (roleDoc.id || '').trim().toLowerCase();
    const active = roleDoc.data().active !== false;
    const role = String(roleDoc.data().role || '').trim().toLowerCase();
    if (!active) continue;
    if (!['owner', 'admin', 'subadmin'].includes(role)) continue;
    if (!contact.includes('@')) continue;

    const userByEmail = await firestore.collection('users').where('email', '==', contact).limit(1).get();
    if (!userByEmail.empty) {
      const uid = userByEmail.docs[0].id;
      if (uid) uids.add(uid);
    }
  }

  return Array.from(uids);
}

async function sendPushToUserUids({ uids, title, body, type, data = {} }) {
  const targetUids = (uids || []).map((u) => String(u || '').trim()).filter((u) => u.length > 0);
  if (targetUids.length === 0) return;

  const firestore = admin.firestore();
  const tokenSnap = await firestore.collection('deviceTokens').where('uid', 'in', targetUids).get();

  const tokenDocs = tokenSnap.docs;
  const tokens = tokenDocs.map((doc) => doc.id).filter((t) => t);
  if (tokens.length === 0) {
    logger.info('No targeted tokens found. Skipping push send.');
  } else {
    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data: {
        type,
        ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      },
    });

    response.responses.forEach((result, idx) => {
      if (!result.success) {
        logger.warn(`Failed targeted send token index ${idx}`, result.error);
      }
    });
  }

  const batch = firestore.batch();
  targetUids.forEach((uid) => {
    const ref = firestore.collection('users').doc(uid).collection('notifications').doc();
    batch.set(ref, {
      title,
      body,
      type,
      payload: data,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: 'system',
    });
  });
  await batch.commit();
}

async function sendPushToAllUsers({ title, body, type, data = {} }) {
  const tokenSnapshot = await admin.firestore().collection('deviceTokens').get();
  if (tokenSnapshot.empty) {
    logger.info('No FCM tokens found. Skipping push send.');
    return;
  }

  const tokens = tokenSnapshot.docs.map((doc) => doc.id);

  const response = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: {
      title,
      body,
    },
    data: {
      type,
      ...Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
    },
  });

  const firestore = admin.firestore();
  const batch = firestore.batch();

  tokenSnapshot.docs.forEach((tokenDoc) => {
    const tokenData = tokenDoc.data();
    const uid = tokenData.uid;
    if (!uid) return;

    const notifRef = firestore.collection('users').doc(uid).collection('notifications').doc();
    batch.set(notifRef, {
      title,
      body,
      type,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      ...data,
    });
  });

  await batch.commit();

  response.responses.forEach((result, idx) => {
    if (!result.success) {
      logger.warn(`Failed to send to token index ${idx}`, result.error);
    }
  });
}

exports.onUserRegistrationCreated = onDocumentCreated('users/{uid}', async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const uid = event.params.uid;
  if (data.status !== 'pending') return;

  await admin.firestore().collection('approvals').doc(uid).set(
    {
      uid,
      type: 'registration',
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      profileSnapshot: {
        fullName: data.fullName || '',
        email: data.email || '',
        phone: data.phone || '',
      },
    },
    { merge: true }
  );

  logger.info(`Pending approval created for user ${uid}`);
});

exports.onAnnouncementCreatedSendPush = onDocumentCreated('announcements/{announcementId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;

  const title = `Euro Habesha - ${data.title || 'New Update'}`;
  const body = data.body || 'A new event or announcement is available.';
  const type = data.type || 'announcement';

  await sendPushToAllUsers({
    title,
    body,
    type,
    data: {
      announcementId: event.params.announcementId,
    },
  });

  logger.info(`Push sent for announcement ${event.params.announcementId}`);
});

exports.onJobPublishedSendPush = onDocumentCreated('jobs/{jobId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  if (data.status && data.status !== 'approved') return;

  const title = `Euro Habesha - New Job: ${data.title || 'Job Posted'}`;
  const body = data.description
    ? String(data.description).slice(0, 120)
    : 'A new approved job is now available.';

  await sendPushToAllUsers({
    title,
    body,
    type: 'job',
    data: {
      jobId: event.params.jobId,
    },
  });

  logger.info(`Push sent for job ${event.params.jobId}`);
});

exports.onApprovalStatusChanged = onDocumentUpdated('approvals/{uid}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;

  if (before.status === after.status) return;

  const uid = event.params.uid;
  await admin.firestore().collection('users').doc(uid).set(
    {
      status: after.status,
      approvedAt: after.status === 'approved' ? admin.firestore.FieldValue.serverTimestamp() : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  const notifRef = admin.firestore().collection('users').doc(uid).collection('notifications').doc();
  await notifRef.set({
    title: 'Account Approval Update',
    body: after.status === 'approved'
      ? 'Your account has been approved by admin and is now public.'
      : `Your account status is now: ${after.status}`,
    type: 'approval',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });

  logger.info(`Approval status synced for user ${uid}`);
});

exports.onJobSubmissionCreatedNotifyAdmins = onDocumentCreated('job_submissions/{submissionId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  if ((data.status || '').toString() !== 'pending') return;

  const adminUids = await getAdminUids();
  if (adminUids.length === 0) {
    logger.info('No admin UIDs found for pending submission alert.');
    return;
  }

  const title = 'New Submission Needs Approval';
  const body = `${(data.title || 'A listing').toString()} is pending review.`;

  await sendPushToUserUids({
    uids: adminUids,
    title,
    body,
    type: 'admin_review',
    data: {
      submissionId: event.params.submissionId,
      status: 'pending',
    },
  });

  logger.info(`Admin alert sent for pending submission ${event.params.submissionId}`);
});

exports.onJobSubmissionStatusChangedNotifyUser = onDocumentUpdated('job_submissions/{submissionId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;

  const beforeStatus = String(before.status || '').trim().toLowerCase();
  const afterStatus = String(after.status || '').trim().toLowerCase();
  if (beforeStatus === afterStatus) return;
  if (!['approved', 'rejected'].includes(afterStatus)) return;

  const userId = String(after.userId || '').trim();
  if (!userId) return;

  const listingTitle = String(after.title || 'Your listing').trim();
  const approved = afterStatus === 'approved';
  const title = approved ? 'Listing Approved' : 'Listing Update';
  const body = approved
    ? `Your listing "${listingTitle}" has been approved and is now live.`
    : `Your listing "${listingTitle}" was reviewed and not approved. Please edit and submit again.`;

  await sendPushToUserUids({
    uids: [userId],
    title,
    body,
    type: approved ? 'approval' : 'rejection',
    data: {
      submissionId: event.params.submissionId,
      status: afterStatus,
    },
  });

  logger.info(`Submitter notified for ${event.params.submissionId} with status=${afterStatus}`);
});
