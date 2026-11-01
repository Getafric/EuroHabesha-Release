import 'package:flutter/material.dart';

/// Displays the saved image in full. Opening/zooming never edits its bytes.
class PublicProfilePhoto extends StatelessWidget {
  final List<String> urls;
  final Widget fallback;
  final String? semanticLabel;
  const PublicProfilePhoto({
    super.key,
    required this.urls,
    required this.fallback,
    this.semanticLabel,
  });

  Widget _image(BuildContext context, List<String> choices, int index) {
    if (index >= choices.length) return fallback;
    return Semantics(
      button: true,
      label: semanticLabel ?? 'Ouvrir la photo entière',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                _FullProfilePhoto(photos: choices, initialIndex: index),
          ),
        ),
        child: ColoredBox(
          color: const Color(0xFF061E12),
          child: SizedBox.expand(
            child: Image.network(
              choices[index],
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => _image(context, choices, index + 1),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final choices = urls
        .where((url) {
          final uri = Uri.tryParse(url.trim());
          return uri != null &&
              const ['http', 'https'].contains(uri.scheme) &&
              uri.host.isNotEmpty;
        })
        .map((url) => url.trim())
        .toSet()
        .take(12)
        .toList();
    return _image(context, choices, 0);
  }
}

class _FullProfilePhoto extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;
  const _FullProfilePhoto({required this.photos, required this.initialIndex});
  @override
  State<_FullProfilePhoto> createState() => _FullProfilePhotoState();
}

class _FullProfilePhotoState extends State<_FullProfilePhoto> {
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
    backgroundColor: const Color(0xFF061E12),
    appBar: AppBar(
      backgroundColor: const Color(0xFF061E12),
      foregroundColor: const Color(0xFFFFD700),
      title: Text('Photo ${_index + 1} / ${widget.photos.length}'),
    ),
    body: SafeArea(
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: Image.network(
              widget.photos[index],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                child: Text(
                  'Photo indisponible',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
