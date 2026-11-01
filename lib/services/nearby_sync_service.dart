import 'package:cloud_firestore/cloud_firestore.dart';

/// Index public de découverte. Ne contient jamais de coordonnées privées
/// d'un utilisateur ni de documents de vérification professionnelle.
///
/// Ce service prépare les opérations dans le batch fourni par l'appelant.
/// L'appelant doit ajouter au MEME batch les modifications du document public
/// d'origine, puis effectuer un seul `await batch.commit()`.
class NearbySyncService {
  NearbySyncService(this.firestore);

  final FirebaseFirestore firestore;

  static const String collectionName = 'nearbyItems';
  static const Set<String> supportedCollections = {
    'businesses',
    'events',
    'marketplace',
    'jobs',
    'posts',
  };

  DocumentReference<Map<String, dynamic>> referenceFor({
    required String sourceCollection,
    required String sourceId,
  }) {
    if (!supportedCollections.contains(sourceCollection)) {
      throw ArgumentError.value(sourceCollection, 'sourceCollection',
          'Collection non autorisée pour Nearby');
    }
    if (sourceId.trim().isEmpty || sourceId.contains('/')) {
      throw ArgumentError.value(sourceId, 'sourceId', 'ID invalide');
    }
    return firestore.collection(collectionName).doc('${sourceCollection}_$sourceId');
  }

  /// Appeler uniquement avec les données FINALES du document PUBLIC approuvé.
  /// Un statut non publié provoque le retrait de l'index.
  void stageUpsert(
    WriteBatch batch, {
    required String sourceCollection,
    required String sourceId,
    required Map<String, dynamic> publicData,
  }) {
    final ref = referenceFor(
      sourceCollection: sourceCollection,
      sourceId: sourceId,
    );
    final status = _string([publicData['status']]).toLowerCase();
    final hidden = publicData['isDeleted'] == true ||
        publicData['deleted'] == true ||
        publicData['archived'] == true ||
        publicData['isDemo'] == true ||
        publicData['isActive'] == false;
    if (!{'published', 'approved'}.contains(status) || hidden) {
      batch.delete(ref);
      return;
    }

    final fields = _map(publicData['fields']);
    final category = _category(sourceCollection, publicData, fields);
    final title = _string([
      fields['title'], fields['businessName'], fields['name'],
      publicData['title'], publicData['businessName'], publicData['name'],
      publicData['text'], publicData['question'],
    ]);
    final description = _string([
      fields['description'], publicData['description'],
      publicData['text'], publicData['content'], publicData['question'],
    ]);
    final city = _string([
      fields['city'], fields['ville'], publicData['city'],
      publicData['ville'],
    ]);
    final country = _string([
      fields['country'], publicData['country'], publicData['pays'],
    ]);
    final location = _string([
      fields['cityAddress'], publicData['cityAddress'],
      fields['location'], publicData['location'], city,
    ]);
    final subcategory = _string([
      fields['connectCategory'], publicData['connectCategory'],
      fields['communityCategory'], publicData['communityCategory'],
      fields['businessCategory'], publicData['businessCategory'],
      fields['itemCategory'], publicData['itemCategory'],
      fields['category'], publicData['category'],
    ]);
    final media = _map(publicData['media']);
    final eventMedia = _map(publicData['eventMedia']);
    final marketMedia = _map(publicData['marketplaceDetails']);
    final imageUrl = _string([
      publicData['imageUrl'], publicData['image'], publicData['logoUrl'],
      fields['imageUrl'], fields['logoUrl'],
      eventMedia['coverUrl'], marketMedia['mainPhotoUrl'],
      _firstListString(media['photoUrls']),
      _firstListString(eventMedia['photoUrls']),
      _firstListString(marketMedia['photoUrls']),
    ]);

    // Ne copier que des coordonnées explicitement destinées à être publiques.
    // Ne jamais utiliser les coordonnées d'un profil privé ou de l'auteur.
    final publicGeo = _map(publicData['publicLocation']);
    final lat = _number(publicGeo['latitude'] ?? publicGeo['lat']);
    final lng = _number(publicGeo['longitude'] ?? publicGeo['lng']);
    final hasGeo = lat != null && lng != null &&
        lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

    final item = <String, dynamic>{
      'sourceCollection': sourceCollection,
      'sourceId': sourceId,
      'category': category,
      'subcategory': subcategory,
      'title': title.isEmpty ? 'Publication' : title,
      'description': description,
      'imageUrl': imageUrl,
      'city': city,
      'country': country,
      'location': location,
      'status': 'published',
      'isVerified': publicData['isVerified'] == true,
      'locationPrecision': hasGeo ? 'exact' : 'city',
      'createdAt': publicData['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (hasGeo) {
      item['latitude'] = lat;
      item['longitude'] = lng;
      item['geoPoint'] = GeoPoint(lat, lng);
    }
    batch.set(ref, item); // remplacement : évite les anciennes coordonnées obsolètes
  }

  void stageRemove(
    WriteBatch batch, {
    required String sourceCollection,
    required String sourceId,
  }) {
    batch.delete(referenceFor(
      sourceCollection: sourceCollection,
      sourceId: sourceId,
    ));
  }

  static String _category(String collection, Map<String, dynamic> data,
      Map<String, dynamic> fields) {
    switch (collection) {
      case 'businesses': return 'business';
      case 'events': return 'event';
      case 'marketplace': return 'marketplace';
      case 'posts': return 'connect';
      case 'jobs':
        final type = _string([data['type'], fields['type'],
          data['listingType'], fields['listingType']]).toLowerCase();
        return {'professional', 'pro', 'service'}.contains(type)
            ? 'professional' : 'job';
      default: throw ArgumentError('Collection inconnue');
    }
  }

  static Map<String, dynamic> _map(dynamic value) => value is Map
      ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  static String _string(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static String? _firstListString(dynamic value) {
    if (value is! List) return null;
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) return item.trim();
    }
    return null;
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
