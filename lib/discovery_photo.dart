import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Public HTTP images only. The web fallback avoids some cross-origin fetch
/// failures; missing URLs or denied/private images still show the fallback.
class DiscoveryPhoto extends StatelessWidget {
  const DiscoveryPhoto({
    super.key,
    required this.urls,
    required this.fallback,
    this.fit = BoxFit.cover,
  });
  final List<String> urls;
  final Widget fallback;
  final BoxFit fit;

  Widget _image(int index) {
    if (index >= urls.length) return fallback;
    return Image.network(
      urls[index],
      key: ValueKey(urls[index]),
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.fallback
          : WebHtmlElementStrategy.never,
      errorBuilder: (_, __, ___) => _image(index + 1),
    );
  }

  @override
  Widget build(BuildContext context) => _image(0);
}
