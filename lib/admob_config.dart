import 'dart:io';

class AdMobConfig {
  static String get appId {
    if (Platform.isAndroid) {
      // Google-provided Android test App ID.
      return 'ca-app-pub-3940256099942544~3347511713';
    }
    if (Platform.isIOS) {
      // Google-provided iOS test App ID.
      return 'ca-app-pub-3940256099942544~1458002511';
    }
    return '';
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Google-provided Android test Banner ID.
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      // Google-provided iOS test Banner ID.
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }
}
