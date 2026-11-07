import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Explicit interface phrases only. Business names and user publications are
/// never sent to a translation service. Existing catalogues stay authoritative.
class AppUi {
  static final Map<String, Map<String, String>> _catalogues = {};
  static final Map<String, String> _keys = {};
  static void _flatten(Map value, String prefix, Map<String, String> result) {
    for (final entry in value.entries) {
      final key = prefix.isEmpty ? '${entry.key}' : '$prefix.${entry.key}';
      if (entry.value is Map) {
        _flatten(entry.value as Map, key, result);
      } else if (entry.value is String) {
        result[key] = entry.value as String;
      }
    }
  }

  static Future<void> load() async {
    for (final language in [
      'en',
      'fr',
      'de',
      'it',
      'es',
      'nl',
      'sv',
      'da',
      'no',
    ]) {
      try {
        final raw = await rootBundle.loadString(
          'assets/translations/$language.json',
        );
        final flat = <String, String>{};
        _flatten(jsonDecode(raw) as Map, '', flat);
        _catalogues[language] = flat;
      } catch (_) {
        _catalogues[language] = {};
      }
    }
    // Match French and English interface literals, never arbitrary substrings.
    for (final language in ['en', 'fr']) {
      for (final entry
          in (_catalogues[language] ?? <String, String>{}).entries) {
        _keys[entry.value.trim()] = entry.key;
      }
    }
  }

  static String _label(String value) =>
      value.trim().replaceFirst(RegExp(r'\s*\*$'), '');
  static bool known(String value) => _keys.containsKey(_label(value));
  static String text(BuildContext context, String value) {
    final key = _keys[_label(value)];
    final required = value.trim().endsWith('*') ? ' *' : '';
    if (key == null) {
      // Paragraphs combine several known interface sentences. Resolve complete
      // phrases only; never translate individual words in publication content.
      if (value.length < 36) return value;
      var result = value;
      final fragments =
          _keys.keys.where((p) => p.length > 35 && value.contains(p)).toList()
            ..sort((a, b) => b.length.compareTo(a.length));
      final language = context.locale.languageCode;
      for (final phrase in fragments) {
        final k = _keys[phrase]!;
        final translated = _catalogues[language]?[k] ?? _catalogues['en']?[k];
        if (translated != null) result = result.replaceAll(phrase, translated);
      }
      return result;
    }
    final language = context.locale.languageCode;
    return (_catalogues[language]?[key] ??
            _catalogues['en']?[key] ??
            _label(value)) +
        required;
  }
}

String ui(BuildContext context, String value) => AppUi.text(context, value);

/// A regular Text underneath: Flutter accessibility, layout and widget tests
/// retain their usual behaviour. Used only for interface labels.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  @override
  Widget build(BuildContext context) => Text(
    ui(context, data),
    style: style,
    strutStyle: strutStyle,
    textAlign: textAlign,
    textDirection: textDirection,
    locale: locale,
    softWrap: softWrap,
    overflow: overflow,
    textScaler: textScaler,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel,
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    selectionColor: selectionColor,
  );
}
