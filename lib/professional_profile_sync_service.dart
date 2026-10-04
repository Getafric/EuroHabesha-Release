import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalProfileSyncService {
  ProfessionalProfileSyncService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> syncPublishedProfile({
    required String sourceCollection,
    required String sourceId,
  }) async {
    // Pour l'instant, cette synchronisation concerne
    // les profils professionnels publiés dans "jobs".
    if (sourceCollection != 'jobSubmissions') {
      return;
    }

    final sourceRef = _firestore.collection(sourceCollection).doc(sourceId);

    final sourceSnapshot = await sourceRef.get();

    if (!sourceSnapshot.exists) {
      return;
    }

    final data = sourceSnapshot.data() ?? <String, dynamic>{};

    final status = data['status']?.toString() ?? '';

    // Ne jamais publier automatiquement un profil
    // qui n'a pas encore été approuvé par l'admin.
    if (status != 'approved' && status != 'published') {
      return;
    }

    final publicRef = _firestore.collection('jobs').doc(sourceId);

    final publicSnapshot = await publicRef.get();

    // Très important :
    // si l'Admin n'a jamais créé la page publique,
    // le professionnel ne la crée pas lui-même.
    if (!publicSnapshot.exists) {
      return;
    }

    final fields = Map<String, dynamic>.from(
      data['fields'] ?? <String, dynamic>{},
    );

    final title = fields['title']?.toString().trim() ?? '';

    final phone = fields['phoneNumber']?.toString().trim() ?? '';

    final city = fields['cityAddress']?.toString().trim() ?? '';

    final country = fields['country']?.toString().trim() ?? '';

    final website = fields['websiteUrl']?.toString().trim() ?? '';

    final description = fields['description']?.toString().trim() ?? '';

    final jobCategory = fields['jobCategory']?.toString().trim() ?? '';

    final location = city.isNotEmpty
        ? city
        : country.isNotEmpty
            ? country
            : 'Europe';

    final whatsapp = phone.isEmpty
        ? ''
        : 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}';

    final Map<String, dynamic> updates = {
      // Informations modifiables par le professionnel
      'name': title,
      'title': title,
      'description': description,
      'location': location,
      'phone': phone.isEmpty
          ? ''
          : phone.startsWith('tel:')
              ? phone
              : 'tel:$phone',
      'website': website,
      'whatsapp': whatsapp,

      // Catégorie conservée depuis la soumission approuvée
      'jobCategory': jobCategory,
      'category': jobCategory,
      'businessCategory': jobCategory,

      // Identité visuelle
      'logoUrl': data['logoUrl']?.toString() ?? '',
      'coverUrl': data['coverUrl']?.toString() ?? '',

      // Menu professionnel
      'menuItems': data['menuItems'] ?? <dynamic>[],

      // Galerie existante, si elle existe encore
      'gallery': data['gallery'] ?? <dynamic>[],

      // Horaires structurés
      'businessHours': data['businessHours'] ?? <String, dynamic>{},

      // On conserve explicitement l'identité propriétaire.
      'submittedBy': data['submittedBy'],
      'ownerId': data['ownerId'],
      'creatorId': data['creatorId'],

      'profileUpdatedAt': FieldValue.serverTimestamp(),
    };

    // Ne modifie volontairement PAS :
    // status, publishedAt, approvedBy, isVerified,
    // verificationBadge, rating, reviewCount, etc.
    await publicRef.update(updates);
  }
}
