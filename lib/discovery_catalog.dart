import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

String discoveryFold(String text) {
  var result = text.toLowerCase().trim();
  const accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  for (final entry in accents.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

Map<String, dynamic> discoveryFields(Map<String, dynamic> data) =>
    data['fields'] is Map
    ? Map<String, dynamic>.from(data['fields'] as Map)
    : <String, dynamic>{};

String discoveryText(Map<String, dynamic> data, List<String> keys) {
  final fields = discoveryFields(data);
  for (final key in keys) {
    for (final value in [fields[key], data[key]]) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
  }
  return '';
}

bool discoveryPublished(Map<String, dynamic> data, String collection) {
  if (data['deleted'] == true || data['isDeleted'] == true) {
    return false;
  }
  final status = discoveryFold((data['status'] ?? '').toString());
  // Never infer approval for feed items or submission documents.
  if (status.isEmpty) {
    return const {
      'businesses',
      'jobs',
      'events',
      'marketplace',
      'professionals',
      'communities',
    }.contains(collection);
  }
  return status == 'published' || status == 'approved';
}

String discoveryKind(Map<String, dynamic> data, [String source = '']) {
  final fields = discoveryFields(data);
  final declared = discoveryFold(
    [
      source,
      data['sourceCollection'],
      data['type'],
      data['category'],
      data['submissionType'],
      fields['businessCategory'],
      fields['jobCategory'],
      fields['professionTitle'],
    ].whereType<String>().join(' '),
  );
  if (declared.contains('market') || declared.contains('marche')) {
    return 'market';
  }
  if (declared.contains('event') || declared.contains('evenement')) {
    return 'events';
  }
  if (declared.contains('association') ||
      declared.contains('communit') ||
      declared.contains('communaute')) {
    return 'associations';
  }
  if (declared.contains('employer') ||
      declared.contains('emploi') ||
      declared.contains('job offer') ||
      declared.contains('job_offer')) {
    return 'jobs';
  }
  if (declared.contains('job') ||
      declared.contains('service') ||
      declared.contains('professional') ||
      declared.contains('professionnel')) {
    return 'services';
  }
  if (declared.contains('business') ||
      declared.contains('commerce') ||
      declared.contains('restaurant') ||
      declared.contains('cafe')) {
    return 'businesses';
  }
  return 'other';
}

const discoveryAliases = <String, List<String>>{
  'photo': [
    'photograph',
    'photographi',
    'videograph',
    'videaste',
    'photo/video',
  ],
  'translation': ['traduct', 'traduction', 'translat', 'interpret'],
  'hair': ['coiff', 'hair', 'barber', 'salon'],
  'barber': ['barber', 'barbier'],
  'restaurants': ['restaurant', 'food', 'cuisine', 'traiteur', 'catering'],
  'cafes': ['cafe', 'coffee'],
  'grocery': ['epicer', 'grocery', 'supermar', 'supermarket'],
  'transport': ['transport', 'taxi', 'vtc', 'driver', 'chauffeur'],
};

bool discoveryMatchesCategory(Map<String, dynamic> data, String filter) {
  if (filter.isEmpty) {
    return true;
  }
  if (filter == 'offers') {
    return discoveryIsOffer(data);
  }
  final keys = discoveryAliases[filter] ?? [filter];
  final fields = discoveryFields(data);
  var taxonomy = [
    fields['jobCategory'],
    fields['businessCategory'],
    fields['professionTitle'],
    fields['professionalCategory'],
    fields['serviceType'],
    data['jobCategory'],
    data['businessCategory'],
    data['professionTitle'],
    data['serviceType'],
    data['category'],
  ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');
  // Legacy profiles may only have a title. Do not search arbitrary descriptions
  // for a category match (e.g. a restaurant mentioning a photographer).
  if (taxonomy.isEmpty ||
      const [
        'job',
        'business',
        'service',
        'professional',
      ].contains(discoveryFold(taxonomy))) {
    taxonomy += ' ${discoveryText(data, ['title', 'name'])}';
  }
  final normalized = discoveryFold(taxonomy);
  return keys.any(normalized.contains);
}

DateTime? discoveryDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  final text = value.trim();
  final iso = DateTime.tryParse(text);
  if (iso != null) {
    final dayOnly = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (dayOnly != null &&
        (iso.year != int.parse(dayOnly[1]!) ||
            iso.month != int.parse(dayOnly[2]!) ||
            iso.day != int.parse(dayOnly[3]!))) {
      return null;
    }
    return iso;
  }
  final parts = RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(text);
  if (parts == null) {
    return null;
  }
  final day = int.parse(parts[1]!);
  final month = int.parse(parts[2]!);
  final year = int.parse(parts[3]!);
  final parsed = DateTime(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day
      ? parsed
      : null;
}

DateTime? discoveryEventDate(Map<String, dynamic> data) {
  final fields = discoveryFields(data);
  for (final value in [
    fields['eventDate'],
    data['startAt'],
    data['startDate'],
    data['eventDate'],
    data['date'],
  ]) {
    final date = discoveryDate(value);
    if (date != null) {
      return date;
    }
  }
  return null;
}

bool discoveryIsOffer(Map<String, dynamic> data) {
  final fields = discoveryFields(data);
  final type = discoveryFold(
    (data['type'] ?? data['category'] ?? '').toString(),
  );
  final offer = data['promotion'] is Map ? data['promotion'] as Map : const {};
  final marked =
      const {
        'offer',
        'promotion',
        'promo',
        'offre',
        'discount',
      }.contains(type) ||
      offer['active'] == true ||
      data['hasPromotion'] == true;
  if (!marked || offer['active'] == false || data['promotionActive'] == false) {
    return false;
  }
  final end = discoveryDate(
    offer['endsAt'] ?? data['promotionEndsAt'] ?? fields['promotionEndsAt'],
  );
  final start = discoveryDate(offer['startsAt'] ?? data['promotionStartsAt']);
  final now = DateTime.now();
  return (end == null || end.isAfter(now)) &&
      (start == null || !start.isAfter(now));
}

List<String> discoveryImages(Map<String, dynamic> data) {
  final urls = <String>{};
  void add(dynamic value) {
    if (value is String) {
      final uri = Uri.tryParse(value.trim());
      if (uri != null &&
          ['https', 'http'].contains(uri.scheme) &&
          uri.host.isNotEmpty) {
        urls.add(value.trim());
      }
    } else if (value is List) {
      for (final item in value) {
        add(item);
      }
    } else if (value is Map) {
      for (final key in const [
        'url',
        'downloadUrl',
        'src',
        'imageUrl',
        'photoUrl',
        'coverUrl',
        'coverImageUrl',
        'logoUrl',
        'businessLogoUrl',
        'image',
        'profileImageUrl',
        'gallery',
        'photos',
        'photoUrls',
        'imageUrls',
        'mediaUrls',
        'eventMedia',
        'marketplaceDetails',
        'media',
        'fields',
      ]) {
        if (value.containsKey(key)) add(value[key]);
      }
    }
  }

  add(data);
  return urls.take(16).toList();
}

class DiscoveryEntry {
  const DiscoveryEntry(this.collection, this.id, this.data);
  final String collection;
  final String id;
  final Map<String, dynamic> data;
  String get kind => discoveryKind(data, collection);
  String get title => discoveryText(data, ['title', 'name', 'companyName']);
  String get location =>
      discoveryText(data, ['cityAddress', 'city', 'location', 'address']);
  Map<String, dynamic> get navigationData => collection == 'publicFeed'
      ? {...data, 'feedId': id}
      : {...data, 'sourceCollection': collection, 'sourceId': id};
  String get identity {
    final source = data['sourceCollection'];
    final sourceId = data['sourceId'];
    return source is String &&
            source.isNotEmpty &&
            sourceId is String &&
            sourceId.isNotEmpty
        ? '$source/$sourceId'
        : '$collection/$id';
  }
}

/// Read-only live catalogue. Approval is always taken from published documents.
class DiscoveryCatalog extends ChangeNotifier {
  static const sources = [
    'businesses',
    'jobs',
    'events',
    'marketplace',
    'professionals',
    'communities',
    'publicFeed',
  ];
  final Map<String, List<DiscoveryEntry>> _records = {};
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _subscriptions = {};
  final Set<String> errors = {};
  final Set<String> loading = {};
  bool _disposed = false;
  int _generation = 0;

  DiscoveryCatalog() {
    reload();
  }

  void reload() {
    final generation = ++_generation;
    for (final source in sources) {
      unawaited(_subscriptions.remove(source)?.cancel());
      loading.add(source);
      errors.remove(source);
      _subscriptions[source] = FirebaseFirestore.instance
          .collection(source)
          .snapshots()
          .listen(
            (snapshot) {
              if (_disposed || generation != _generation) return;
              _records[source] = snapshot.docs
                  .where((doc) => discoveryPublished(doc.data(), source))
                  .map((doc) => DiscoveryEntry(source, doc.id, doc.data()))
                  .toList();
              loading.remove(source);
              errors.remove(source);
              notifyListeners();
            },
            onError: (Object error) {
              if (_disposed || generation != _generation) return;
              _records.remove(source);
              loading.remove(source);
              errors.add(source);
              notifyListeners();
            },
          );
    }
  }

  List<DiscoveryEntry> get entries {
    final all = <String, DiscoveryEntry>{};
    // Original published records win over a feed mirror of the same reference.
    for (final source in sources.reversed) {
      for (final entry in _records[source] ?? <DiscoveryEntry>[]) {
        all[entry.identity] = entry;
      }
    }
    return all.values.toList()..sort(
      (a, b) => discoveryFold(a.title).compareTo(discoveryFold(b.title)),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    super.dispose();
  }
}
