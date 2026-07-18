import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AppLocalizationHelper {
  static const supportedLocales = [
    Locale('en'),
    Locale('am'),
    Locale('fr'),
  ];

  static const assetPath = 'assets/lang';

  static Widget languageMenu(BuildContext context) {
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language, color: Colors.white),
      tooltip: tr('select_language'),
      onSelected: (locale) {
        context.setLocale(locale);
      },
      itemBuilder: (context) {
        return [
          PopupMenuItem<Locale>(
            value: const Locale('en'),
            child: Text(tr('language_english')),
          ),
          PopupMenuItem<Locale>(
            value: const Locale('am'),
            child: Text(tr('language_amharic')),
          ),
          PopupMenuItem<Locale>(
            value: const Locale('fr'),
            child: Text(tr('language_french')),
          ),
        ];
      },
    );
  }
}
