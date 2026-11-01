/// Public presentation images are separate from private verification documents.
String? requiredProfessionalPhotoError(String type, {required bool hasPhoto}) {
  if (['job', 'business', 'professional'].contains(type) && !hasPhoto) {
    return 'Ajoutez une photo de présentation de votre activité avant de continuer.';
  }
  return null;
}
