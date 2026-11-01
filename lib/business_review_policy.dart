String? businessReviewInputError(int stars, String comment) {
  if (stars < 1 || stars > 5) return 'Choisissez entre 1 et 5 étoiles.';
  if (comment.trim().isEmpty) return 'Écrivez quelques mots avant d’envoyer.';
  if (comment.trim().length > 2000) {
    return 'Votre avis doit faire 2 000 caractères maximum.';
  }
  return null;
}

bool isPublicReviewPath(String path) {
  final parts = path.split('/');
  return parts.length == 2 &&
      ['businesses', 'jobs'].contains(parts[0]) &&
      RegExp(r'^[A-Za-z0-9_-]{1,150}$').hasMatch(parts[1]);
}

String? reviewPublicCollectionForSource(String? source) => switch (source) {
  'businessSubmissions' => 'businesses',
  'jobSubmissions' => 'jobs',
  _ => null,
};
