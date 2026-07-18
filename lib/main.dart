import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_localization_helper.dart';
import 'firebase_options.dart';
import 'navigation_shell.dart';
import 'notification_service.dart';
import 'session_state.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await MobileAds.instance.initialize();
  SessionState.enterGuest();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 12));
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (e) {
    debugPrint('Firebase initialization skipped at startup: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: AppLocalizationHelper.supportedLocales,
      path: AppLocalizationHelper.assetPath,
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      child: const EuroHabeshaApp(),
    ),
  );
}

class EuroHabeshaApp extends StatefulWidget {
  const EuroHabeshaApp({super.key});

  @override
  State<EuroHabeshaApp> createState() => _EuroHabeshaAppState();
}

class _EuroHabeshaAppState extends State<EuroHabeshaApp> {
  static const Color _amberText = Color(0xFFF5C542);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.initialize(appNavigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    final premiumTextTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: _amberText,
      displayColor: _amberText,
    );

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: tr('app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF061E12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5C542),
          secondary: Color(0xFFFFB300),
          surface: Color(0xFF0E2E1E),
          onPrimary: Color(0xFF061E12),
          onSecondary: Color(0xFF061E12),
          onSurface: Color(0xFFF5C542),
        ),
        textTheme: premiumTextTheme,
        primaryTextTheme: premiumTextTheme,
        iconTheme: const IconThemeData(color: _amberText),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFF0A2418),
          foregroundColor: _amberText,
          iconTheme: IconThemeData(color: _amberText),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF0A2418),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF0E2E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: _amberText,
          textColor: _amberText,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0x66F5C542)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: _amberText, width: 1.4),
          ),
          hintStyle: TextStyle(color: Color(0xCCF5C542)),
          labelStyle: TextStyle(color: _amberText),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _amberText),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _amberText,
            side: const BorderSide(color: _amberText),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _amberText,
            foregroundColor: const Color(0xFF061E12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _amberText,
          foregroundColor: Color(0xFF061E12),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0A2418),
          selectedItemColor: _amberText,
          unselectedItemColor: Color(0xB3F5C542),
        ),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const MainNavigationShell(),
    );
  }
}