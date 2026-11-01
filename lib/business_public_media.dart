/// Resolves only the public photo fields used by business profiles.
/// It never searches verification documents or modifies a Firestore record.
class BusinessPublicMedia {
  final List<String> logos;
  final List<String> covers;
  final List<String> gallery;

  const BusinessPublicMedia({
    required this.logos,
    required this.covers,
    required this.gallery,
  });

  String get logo => logos.isEmpty ? '' : logos.first;
  String get cover => covers.isEmpty ? '' : covers.first;

  /// Earlier sources take priority within each photo role. An explicit cover
  /// always takes priority over a generic thumbnail from any source.
  factory BusinessPublicMedia.resolve(Iterable<Map<String, dynamic>> sources) {
    final logos = <String>[];
    final covers = <String>[];
    final gallery = <String>[];
    final generic = <String>[];
    for (final source in sources) {
      final rawFields = source['fields'];
      final nodes = <Map>[source, if (rawFields is Map) rawFields];
      for (final node in nodes) {
        for (final key in const [
          'logoUrl',
          'businessLogoUrl',
          'profileImageUrl',
          'logo',
        ]) {
          _append(logos, publicBusinessPhotoUrls([node[key]]));
        }
        for (final key in const [
          'coverUrl',
          'coverImageUrl',
          'coverPhotoUrl',
          'bannerUrl',
          'bannerImageUrl',
        ]) {
          _append(covers, publicBusinessPhotoUrls([node[key]]));
        }
        for (final key in const [
          'gallery',
          'galleryUrls',
          'photos',
          'images',
          'imageUrls',
          'photoUrls',
          'mediaUrls',
        ]) {
          _append(gallery, publicBusinessPhotoUrls([node[key]]));
        }
        for (final key in const [
          'imageUrl',
          'photoUrl',
          'image',
          'photo',
          'thumbnailUrl',
        ]) {
          _append(generic, publicBusinessPhotoUrls([node[key]]));
        }
      }
    }
    final logoChoices = <String>[];
    final coverChoices = <String>[];
    for (final values in [logos, generic, gallery, covers]) {
      _append(logoChoices, values);
    }
    for (final values in [covers, gallery, generic, logos]) {
      _append(coverChoices, values);
    }
    if (gallery.isEmpty) {
      _append(gallery, generic);
    }
    return BusinessPublicMedia(
      logos: List.unmodifiable(logoChoices.take(12)),
      covers: List.unmodifiable(coverChoices.take(12)),
      gallery: List.unmodifiable(gallery.take(100)),
    );
  }
}

void _append(List<String> target, Iterable<String> urls) {
  for (final url in urls) {
    if (target.length >= 100) {
      return;
    }
    if (!target.contains(url)) {
      target.add(url);
    }
  }
}

/// Strings, lists and explicit photo objects are supported. Empty or malformed
/// URLs do not prevent later valid photos from being selected.
List<String> publicBusinessPhotoUrls(Iterable<dynamic> sources) {
  final result = <String>[];
  void read(dynamic value, int depth) {
    if (depth > 4 || result.length >= 100) {
      return;
    }
    if (value is String) {
      final url = value.trim();
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !const ['https', 'http'].contains(uri.scheme) ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          RegExp(
            r'\.(mp4|mov|webm|m4v|pdf)$',
            caseSensitive: false,
          ).hasMatch(uri.path)) {
        return;
      }
      if (!result.contains(url)) {
        result.add(url);
      }
    } else if (value is List) {
      for (final item in value) {
        read(item, depth + 1);
      }
    } else if (value is Map) {
      final type = (value['contentType'] ?? value['type'])?.toString() ?? '';
      if (type.startsWith('video') || type == 'application/pdf') {
        return;
      }
      for (final key in const [
        'url',
        'imageUrl',
        'photoUrl',
        'downloadUrl',
        'src',
      ]) {
        final before = result.length;
        read(value[key], depth + 1);
        if (result.length > before) {
          break;
        }
      }
    }
  }

  for (final source in sources) {
    read(source, 0);
  }
  return result;
}

/// Explicit references only: no matching by name, city or a guessed document ID.
class BusinessPhotoSource {
  final String collection;
  final String id;
  const BusinessPhotoSource(this.collection, this.id);

  String get path => '$collection/$id';

  static BusinessPhotoSource? fromPair(dynamic collection, dynamic id) {
    if (collection is! String || id is! String) {
      return null;
    }
    final collections = <String, String>{
      'businesses': 'businesses',
      'businesssubmissions': 'businessSubmissions',
    };
    final canonical = collections[collection.trim().toLowerCase()];
    final cleanId = id.trim();
    if (canonical == null ||
        cleanId.isEmpty ||
        cleanId.length > 150 ||
        cleanId.contains('/') ||
        cleanId == '.' ||
        cleanId == '..') {
      return null;
    }
    return BusinessPhotoSource(canonical, cleanId);
  }

  static BusinessPhotoSource? fromPath(String path) {
    final parts = path.split('/');
    return parts.length == 2 ? fromPair(parts[0], parts[1]) : null;
  }

  static BusinessPhotoSource? linked(Map<String, dynamic> data) =>
      fromPair(data['sourceCollection'], data['sourceId']);
}
