import 'dart:convert';
import 'service_profession.dart';

bool isProfessionalReviewSource(String source) =>
    source == 'jobSubmissions' || source == 'businessSubmissions';

String reviewFirst(Iterable<dynamic> values) {
  for (final value in values) {
    final s = serviceText(value, 4096);
    if (s.isNotEmpty) return s;
  }
  return '';
}

Uri? reviewWebsite(dynamic value) {
  final text = serviceText(value, 4096);
  final uri = Uri.tryParse(text);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

bool reviewPhotoUrl(dynamic value) {
  final uri = reviewWebsite(value);
  if (uri == null) return false;
  var path = uri.path.toLowerCase();
  try {
    path = Uri.decodeComponent(path);
  } on FormatException {
    return false;
  }
  return !path.contains('verification') && !path.contains('identity_documents');
}

List<String> reviewPublicPhotos(Map<String, dynamic> raw) {
  final fields = serviceMap(raw['fields']), media = serviceMap(raw['media']);
  final values = <dynamic>[
    fields['coverUrl'],
    raw['coverUrl'],
    fields['coverImageUrl'],
    raw['coverImageUrl'],
    fields['logoUrl'],
    raw['logoUrl'],
    fields['businessLogoUrl'],
    raw['businessLogoUrl'],
    fields['profileImageUrl'],
    raw['profileImageUrl'],
    fields['coverPhotoUrl'],
    raw['coverPhotoUrl'],
    fields['imageUrl'],
    raw['imageUrl'],
    fields['photoUrl'],
    raw['photoUrl'],
  ];
  for (final source in [
    raw['gallery'],
    fields['gallery'],
    media['photoUrls'],
    media['portfolioPhotoUrls'],
    media['workPhotoUrls'],
    media['cateringPhotoUrls'],
  ]) {
    if (source is List) values.addAll(source);
  }
  final result = <String>[];
  for (final value in values) {
    if (!reviewPhotoUrl(value)) continue;
    final url = serviceText(value, 4096);
    if (!result.contains(url)) result.add(url);
    if (result.length == 30) break;
  }
  return result;
}

class AdminProfessionalReviewData {
  final Map<String, dynamic> raw;
  final String source;
  AdminProfessionalReviewData(this.raw, this.source);
  Map<String, dynamic> get fields => serviceMap(raw['fields']);
  String get name => reviewFirst([
    fields['title'],
    raw['name'],
    raw['title'],
    'Professionnel',
  ]);
  String get category => reviewFirst([
    fields['jobCategory'],
    fields['businessCategory'],
    fields['professionTitle'],
    raw['businessCategory'],
    raw['jobCategory'],
    raw['category'],
  ]);
  String get categoryLabel =>
      source == 'jobSubmissions' ? serviceDefinition(category).label : category;
  String get description => reviewFirst([
    fields['description'],
    raw['description'],
    fields['requirements'],
  ]);
  String get city => reviewFirst([
    fields['cityOnlyLocation'],
    fields['cityAddress'],
    raw['location'],
  ]);
  String get country => reviewFirst([fields['country'], raw['country']]);
  String get area =>
      reviewFirst([fields['serviceArea'], raw['serviceArea'], city]);
  String get address => reviewFirst([
    fields['address'],
    fields['exactAddressOptional'],
    raw['address'],
    fields['cityAddress'],
    city,
  ]);
  String get phone =>
      reviewFirst([fields['phoneNumber'], raw['phone'], raw['phoneNumber']]);
  String get email => reviewFirst([
    fields['emailAddress'],
    fields['email'],
    raw['email'],
    raw['submitterEmail'],
  ]);
  String get website =>
      reviewFirst([fields['websiteUrl'], raw['website'], raw['websiteUrl']]);
  String get submittedEmail => serviceText(raw['submitterEmail']);
  String get createdLabel {
    final value = raw['createdAt'];
    DateTime? date;
    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else {
      try {
        final candidate = value?.toDate();
        if (candidate is DateTime) date = candidate;
      } catch (_) {}
    }
    if (date == null) return '';
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  String get registration => reviewFirst([
    fields['registration'],
    fields['siret'],
    fields['registrationNumber'],
  ]);
  String get hours => reviewFirst([
    fields['availability'],
    fields['openingHours'],
    raw['openingHours'],
  ]);
  String get publicationStatus => serviceText(raw['status']);
  bool get pending => [
    'pendingApproval',
    'pendingAdminReview',
    'pending',
    'pendingPaymentAndReview',
  ].contains(publicationStatus);
  String get publicationLabel => switch (publicationStatus) {
    'approved' || 'published' => 'Publication approuvée',
    'rejected' => 'Publication refusée',
    'pendingApproval' ||
    'pendingAdminReview' ||
    'pending' ||
    'pendingPaymentAndReview' => 'Publication en attente',
    _ => 'Statut de publication à consulter',
  };
  String get verificationLabel {
    final status = serviceText(raw['verificationStatus']);
    if (status == 'approved' && raw['isVerified'] == true) {
      return 'Approbation enregistrée sur la fiche';
    }
    if (status == 'rejected' || status == 'revoked' || status == 'unverified') {
      return 'Vérification non approuvée';
    }
    if (['pending', 'pendingApproval', 'pendingAdminReview'].contains(status)) {
      return 'Vérification en attente';
    }
    return 'Dossier de vérification à consulter';
  }

  List<String> get photos => reviewPublicPhotos(raw);
  Map<String, dynamic> get serviceDetails => publicServiceDetails(raw);
  String get price =>
      serviceDetails.isEmpty ? '' : servicePrice(serviceDetails);
  Uri? get mapUri {
    final query = reviewFirst([address, area, city]);
    if (query.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': [query, country].where((s) => s.isNotEmpty).join(', '),
    });
  }

  Uri? get searchUri => name.isEmpty
      ? null
      : Uri.https('www.google.com', '/search', {
          'q': [name, city, country].where((s) => s.isNotEmpty).join(' '),
        });
  Uri? get websiteUri => reviewWebsite(website);
  Uri? get phoneUri {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) return null;
    final cleaned = phone.replaceFirst(RegExp(r'^tel:'), '').trim();
    return Uri(
      scheme: 'tel',
      path: '${cleaned.startsWith('+') ? '+' : ''}$digits',
    );
  }

  Uri? get emailUri {
    if (!RegExp(r'^[^@\s<>?]+@[^@\s<>?]+\.[^@\s<>?]+$').hasMatch(email)) {
      return null;
    }
    return Uri(scheme: 'mailto', path: email);
  }
}

/// Compare only the presented public information before a decision.
/// No identity badge, bank account or private dossier is used as proof.
String reviewPresentationFingerprint(AdminProfessionalReviewData m) =>
    jsonEncode([
      m.name,
      m.category,
      m.description,
      m.photos,
      m.city,
      m.country,
      m.area,
      m.address,
      m.phone,
      m.email,
      m.website,
      m.registration,
      m.hours,
      m.publicationStatus,
      m.serviceDetails,
    ]);
