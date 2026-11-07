/// Publication review and private identity review are independent workflows.
bool adminReviewPending(Object? status) => const [
  'pendingApproval',
  'pendingAdminReview',
  'pendingPaymentAndReview',
  'pending',
].contains(status?.toString());

bool adminPrivateReviewPending(Object? status) => const [
  'pendingApproval',
  'pendingAdminReview',
  'pending',
].contains(status?.toString());

/// Employer onboarding has no consumer listing or verification badge to publish.
bool adminPublishesConsumerListing(String source) =>
    source != 'employerSubmissions';

const adminPrivateReviewSources = <String>[
  'businessSubmissions',
  'jobSubmissions',
  'businesses',
  'jobs',
];
