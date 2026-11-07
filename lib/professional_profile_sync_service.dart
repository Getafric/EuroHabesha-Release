import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessionalProfileSyncService {
  ProfessionalProfileSyncService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> syncPublishedProfile({
    required String sourceCollection,
    required String sourceId,
  }) async {
    if (sourceCollection != 'jobSubmissions') return;
    final sourceSnapshot = await _firestore
        .collection(sourceCollection)
        .doc(sourceId)
        .get();
    if (!sourceSnapshot.exists) return;
    final data = sourceSnapshot.data() ?? <String, dynamic>{};
    final status = data['status']?.toString() ?? '';
    if (status != 'approved' && status != 'published') return;
    final publicRef = _firestore.collection('jobs').doc(sourceId);
    final publicSnapshot = await publicRef.get();
    if (!publicSnapshot.exists) return; // Seul l'admin publie.
    final fields = Map<String, dynamic>.from(
      data['fields'] ?? <String, dynamic>{},
    );
    String field(String key) => fields[key]?.toString().trim() ?? '';
    final phone = field('phoneNumber');
    final city = field('cityAddress');
    final country = field('country');
    final jobCategory = field('jobCategory');
    final publicData = publicSnapshot.data() ?? <String, dynamic>{};
    await publicRef.update({
      'name': field('title'), 'title': field('title'),
      'description': field('description'),
      'location': city.isNotEmpty
          ? city
          : country.isNotEmpty
          ? country
          : 'Europe',
      'phone': phone.isEmpty
          ? ''
          : phone.startsWith('tel:')
          ? phone
          : 'tel:$phone',
      'website': field('websiteUrl'),
      'whatsapp': phone.isEmpty
          ? ''
          : 'https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}',
      'jobCategory': jobCategory, 'category': jobCategory,
      'businessCategory': jobCategory,
      'logoUrl': data['logoUrl']?.toString() ?? '',
      'coverUrl': data['coverUrl']?.toString() ?? '',
      'menuItems': data['menuItems'] ?? <dynamic>[],
      'gallery': data['gallery'] ?? <dynamic>[],
      'businessHours': data['businessHours'] ?? <String, dynamic>{},
      'submittedBy': data['submittedBy'], 'ownerId': data['ownerId'],
      'creatorId': data['creatorId'],
      // Préserve un lien existant si l'admin en a défini un.
      'roomLayoutSourceCollection':
          publicData['roomLayoutSourceCollection'] ?? sourceCollection,
      'roomLayoutBusinessId': publicData['roomLayoutBusinessId'] ?? sourceId,
      'profileUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}
