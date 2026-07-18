import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web FirebaseOptions are not configured yet.');
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS FirebaseOptions are not configured yet.');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS FirebaseOptions are not configured yet.');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows FirebaseOptions are not configured yet.');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux FirebaseOptions are not configured yet.');
      default:
        throw UnsupportedError('Unsupported platform for FirebaseOptions.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCVMaMtACft2n11LDFJuy6vtiaNh6lM4eM',
    appId: '1:218564066910:android:e7900e60c10457a50f7ecf',
    messagingSenderId: '218564066910',
    projectId: 'eurohabesha-f3929',
    storageBucket: 'eurohabesha-f3929.firebasestorage.app',
  );
}
