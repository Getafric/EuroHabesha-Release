import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'business_public_media.dart';

const _dark = Color(0xFF061E12);
const _gold = Color(0xFFFFD700);
const _green = Color(0xFF123629);

/// Reads only real, public image URLs. Never substitutes stock photographs.
List<String> businessProfilePhotos(Iterable<dynamic> sources) =>
    publicBusinessPhotoUrls(sources);

/// Falls back to another real public photo when a legacy URL no longer loads.
class BusinessProfileImage extends StatelessWidget {
  final List<String> urls;
  final Widget fallback;
  final BoxFit fit;
  final String? semanticLabel;
  const BusinessProfileImage({
    super.key,
    required this.urls,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });

  Widget _image(List<String> choices, int index) {
    if (index >= choices.length) {
      return fallback;
    }
    return Image.network(
      choices[index],
      key: ValueKey(choices[index]),
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (_, __, ___) => _image(choices, index + 1),
    );
  }

  @override
  Widget build(BuildContext context) =>
      _image(publicBusinessPhotoUrls(urls).take(12).toList(), 0);
}

/// Refreshes media from exact published references. It reads no private
/// verification subcollections and never changes booking or moderation data.
class BusinessProfileMediaView extends StatefulWidget {
  final Map<String, dynamic> data;
  final Widget Function(BuildContext context, BusinessPublicMedia media)
  builder;
  const BusinessProfileMediaView({
    super.key,
    required this.data,
    required this.builder,
  });

  @override
  State<BusinessProfileMediaView> createState() =>
      _BusinessProfileMediaViewState();
}

class _BusinessProfileMediaViewState extends State<BusinessProfileMediaView> {
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profile;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _original;
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? _originalData;
  bool _loaded = false;
  int _generation = 0;
  int _originalGeneration = 0;
  String? _originalPath;

  DocumentReference<Map<String, dynamic>>? _reference(
    Map<String, dynamic> data,
  ) {
    final value = data['docRef'];
    if (value is DocumentReference<Map<String, dynamic>>) {
      final parts = value.path.split('/');
      if (BusinessPhotoSource.fromPath(value.path) != null ||
          (parts.length == 2 && parts.first == 'publicFeed')) {
        return value;
      }
    }
    final linked = BusinessPhotoSource.linked(data);
    return linked == null ? null : FirebaseFirestore.instance.doc(linked.path);
  }

  bool _published(Map<String, dynamic> data) =>
      data['status'] == null ||
      const ['approved', 'published'].contains(data['status']);

  @override
  void initState() {
    super.initState();
    _watch();
  }

  @override
  void didUpdateWidget(covariant BusinessProfileMediaView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_reference(oldWidget.data)?.path != _reference(widget.data)?.path) {
      _watch();
    }
  }

  void _watch() {
    _generation++;
    _originalGeneration++;
    unawaited(_profile?.cancel());
    unawaited(_original?.cancel());
    _profileData = null;
    _originalData = null;
    _originalPath = null;
    _loaded = false;
    final generation = _generation;
    final reference = _reference(widget.data);
    if (reference == null) {
      return;
    }
    _profile = reference.snapshots().listen(
      (snapshot) {
        if (!mounted || generation != _generation) {
          return;
        }
        if (!snapshot.exists && snapshot.metadata.isFromCache) {
          return;
        }
        final data = snapshot.data();
        // A confirmed deletion/withdrawal must not resurrect cached photos.
        final visible = data != null && _published(data);
        final linked = data != null && _published(data)
            ? BusinessPhotoSource.linked(data)
            : null;
        final path = linked?.path == reference.path ? null : linked?.path;
        if (path != _originalPath) {
          _watchOriginal(path, generation);
        }
        setState(() {
          _loaded = true;
          _profileData = visible ? data : <String, dynamic>{};
        });
      },
      onError: (Object error) {
        // Keep public photos supplied by the caller if a read fails.
      },
    );
  }

  void _watchOriginal(String? path, int generation) {
    _originalGeneration++;
    final originalGeneration = _originalGeneration;
    unawaited(_original?.cancel());
    _originalData = null;
    _originalPath = path;
    if (path == null) {
      return;
    }
    _original = FirebaseFirestore.instance
        .doc(path)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted ||
                generation != _generation ||
                originalGeneration != _originalGeneration) {
              return;
            }
            final data = snapshot.data();
            setState(
              () => _originalData = data != null && _published(data)
                  ? data
                  : null,
            );
          },
          onError: (Object error) {
            if (mounted &&
                generation == _generation &&
                originalGeneration == _originalGeneration) {
              setState(() => _originalData = null);
            }
          },
        );
  }

  @override
  void dispose() {
    _generation++;
    _originalGeneration++;
    unawaited(_profile?.cancel());
    unawaited(_original?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = BusinessPublicMedia.resolve([
      if (!_loaded) widget.data,
      if (_profileData != null) _profileData!,
      if (_originalData != null) _originalData!,
    ]);
    return widget.builder(context, media);
  }
}

class BusinessProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const BusinessProfileCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _green,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _gold.withValues(alpha: .22)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _gold, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _HoursLine {
  final String days;
  final String hours;
  const _HoursLine(this.days, this.hours);
}

const _shortDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const _fullDays = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

int? _dayIndex(String raw) {
  final s = raw.toLowerCase().replaceAll('.', '').trim();
  const aliases = [
    ['mon', 'monday', 'lun', 'lundi'],
    ['tue', 'tues', 'tuesday', 'mar', 'mardi'],
    ['wed', 'wednesday', 'mer', 'mercredi'],
    ['thu', 'thur', 'thurs', 'thursday', 'jeu', 'jeudi'],
    ['fri', 'friday', 'ven', 'vendredi'],
    ['sat', 'saturday', 'sam', 'samedi'],
    ['sun', 'sunday', 'dim', 'dimanche'],
  ];
  for (var i = 0; i < aliases.length; i++) {
    if (aliases[i].contains(s)) return i;
  }
  return null;
}

List<int>? _days(String value) {
  final range = value.split(RegExp(r'\s*(?:[-–—]|\bto\b|\bà\b)\s*'));
  if (range.length == 2) {
    final start = _dayIndex(range[0]);
    final end = _dayIndex(range[1]);
    if (start == null || end == null) return null;
    final days = <int>[start];
    while (days.last != end && days.length < 7) {
      days.add((days.last + 1) % 7);
    }
    return days;
  }
  final days = value.split(RegExp(r'\s*[,·&]\s*')).map(_dayIndex).toList();
  if (days.isEmpty || days.any((d) => d == null)) return null;
  return days.cast<int>();
}

String? _hours(String raw) {
  final lower = raw.toLowerCase().trim();
  if (['closed', 'fermé', 'ferme', 'fermée'].contains(lower)) return 'Fermé';
  if (['open', 'ouvert'].contains(lower))
    return 'Ouvert (horaires non précisés)';
  // Multiple time ranges remain separate, preserving midday closures.
  final intervals = raw.split(RegExp(r'\s*(?:/|,|\bet\b)\s*'));
  final formatted = <String>[];
  final pattern = RegExp(
    r'^\s*([01]?\d|2[0-3])[:h]([0-5]\d)\s*[-–—]\s*([01]?\d|2[0-3])[:h]([0-5]\d)\s*$',
  );
  for (final interval in intervals) {
    final match = pattern.firstMatch(interval);
    if (match == null) return null;
    String clock(int h, int m) =>
        '${match.group(h)!.padLeft(2, '0')}:${match.group(m)}';
    formatted.add('${clock(1, 2)} – ${clock(3, 4)}');
  }
  return formatted.join(' / ');
}

/// Unknown or conflicting text stays visible verbatim rather than guessed.
Map<int, String>? _parseHours(String raw) {
  final result = <int, String>{};
  final pieces = raw.split(RegExp(r'[|;\n]')).where((p) => p.trim().isNotEmpty);
  for (final piece in pieces) {
    final colon = piece.indexOf(':');
    if (colon < 0) return null;
    final days = _days(piece.substring(0, colon));
    final hours = _hours(piece.substring(colon + 1));
    if (days == null || hours == null) return null;
    for (final day in days) {
      if (result.containsKey(day) && result[day] != hours) return null;
      result[day] = hours;
    }
  }
  return result.isEmpty ? null : result;
}

String _groupDays(List<int> days) {
  if (days.length == 1) return _fullDays[days.first];
  final parts = <String>[];
  var i = 0;
  while (i < days.length) {
    final start = days[i];
    var end = start;
    while (i + 1 < days.length && days[i + 1] == end + 1) {
      end = days[++i];
    }
    parts.add(
      end > start
          ? '${_shortDays[start]} – ${_shortDays[end]}'
          : _shortDays[start],
    );
    i++;
  }
  return parts.join(' · ');
}

class BusinessProfileHours extends StatelessWidget {
  final String raw;
  const BusinessProfileHours({super.key, required this.raw});

  Widget _line(String day, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: LayoutBuilder(
      builder: (context, size) {
        final dayText = Text(day, style: const TextStyle(color: Colors.white));
        final hourText = Text(
          value,
          style: TextStyle(
            color: value == 'Fermé' ? Colors.white60 : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        );
        if (size.maxWidth < 280 || value.length > 22) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [dayText, const SizedBox(height: 5), hourText],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: dayText),
            const SizedBox(width: 14),
            Flexible(child: hourText),
          ],
        );
      },
    ),
  );

  void _details(BuildContext context, Map<int, String> schedule) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _green,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Horaires détaillés',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < 7; i++)
                _line(_fullDays[i], schedule[i] ?? 'Non renseigné'),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: _dark,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _parseHours(raw);
    final groups = <String, List<int>>{};
    if (schedule != null) {
      for (var i = 0; i < 7; i++) {
        final value = schedule[i];
        if (value != null) groups.putIfAbsent(value, () => []).add(i);
      }
    }
    final lines = groups.entries
        .map((e) => _HoursLine(_groupDays(e.value), e.key))
        .toList();
    return BusinessProfileCard(
      icon: Icons.schedule,
      title: 'Horaires',
      child: schedule == null
          ? Text(
              raw.trim().isEmpty ? 'Horaires non renseignés' : raw.trim(),
              style: const TextStyle(color: Colors.white, height: 1.5),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const Divider(color: Colors.white12, height: 1),
                  _line(lines[i].days, lines[i].hours),
                ],
                const Divider(color: Colors.white12),
                TextButton(
                  onPressed: () => _details(context, schedule),
                  style: TextButton.styleFrom(
                    foregroundColor: _gold,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Row(
                    children: [
                      Expanded(child: Text('Voir les horaires détaillés')),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class BusinessProfileGallery extends StatelessWidget {
  final List<String> photos;
  const BusinessProfileGallery({super.key, required this.photos});

  Widget _photo(String url, {BoxFit fit = BoxFit.cover}) => Image.network(
    url,
    fit: fit,
    errorBuilder: (_, __, ___) => const Center(
      child: Icon(Icons.broken_image_outlined, color: _gold, size: 32),
    ),
  );

  void _open(BuildContext context, int start) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) =>
            _BusinessPhotoViewer(photos: photos, initialIndex: start),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();
    return BusinessProfileCard(
      icon: Icons.photo_library_outlined,
      title: 'Photos de l’établissement',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _open(context, 0),
              style: TextButton.styleFrom(foregroundColor: _gold),
              child: Text('Tout voir (${photos.length})'),
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => Semantics(
                button: true,
                label: 'Ouvrir la photo ${i + 1}',
                child: InkWell(
                  onTap: () => _open(context, i),
                  borderRadius: BorderRadius.circular(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(width: 118, child: _photo(photos[i])),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPhotoViewer extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const _BusinessPhotoViewer({
    required this.photos,
    required this.initialIndex,
  });
  @override
  State<_BusinessPhotoViewer> createState() => _BusinessPhotoViewerState();
}

class _BusinessPhotoViewerState extends State<_BusinessPhotoViewer> {
  late final PageController _controller;
  late int _index;
  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _dark,
    appBar: AppBar(
      backgroundColor: _dark,
      foregroundColor: _gold,
      title: Text('Photo ${_index + 1} / ${widget.photos.length}'),
    ),
    body: SafeArea(
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: Image.network(
              widget.photos[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'Photo indisponible',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
