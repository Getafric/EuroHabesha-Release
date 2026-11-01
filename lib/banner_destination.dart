String bannerCollectionForType(String type) => switch (type) {
  'business' => 'businesses',
  'job' => 'jobs',
  'event' => 'events',
  'marketplace' => 'marketplace',
  _ => '',
};
String bannerRouteForType(String type) => switch (type) {
  'business' => '/business',
  'job' => '/job',
  'event' => '/event',
  'marketplace' => '/marketplace',
  _ => '',
};

/// Exact public references only; no name-based or same-ID collection guessing.
String? exactJobBannerId(Map<String, dynamic> banner) {
  if (banner['targetType'] != 'job') return null;
  final collection = banner['targetCollection'];
  if (collection != null && collection != 'jobs') return null;
  final value = banner['targetId'];
  if (value is! String ||
      value.trim().isEmpty ||
      value != value.trim() ||
      value.length > 150 ||
      value.contains('/') ||
      value == '.' ||
      value == '..') {
    return null;
  }
  return value;
}
