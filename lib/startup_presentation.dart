import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StartupPresentation {
  const StartupPresentation({
    this.enabled = true,
    this.mediaType = 'local',
    this.storagePath = '',
    this.durationSeconds = 10,
  });

  final bool enabled;
  final String mediaType;
  final String storagePath;
  final int durationSeconds;
  bool get isLocal => mediaType == 'local';
  static final pathPattern = RegExp(
    r'^startup_media/[A-Za-z0-9_-]+\.(mp4|jpg|png|webp)$',
  );

  static StartupPresentation? fromMap(Map<String, dynamic> data) {
    final enabled = data['enabled'];
    final type = data['mediaType'];
    final path = data['storagePath'];
    final duration = data['durationSeconds'];
    if (enabled is! bool ||
        type is! String ||
        path is! String ||
        duration is! int ||
        duration < 3 ||
        duration > 15 ||
        !['local', 'video', 'image'].contains(type))
      return null;
    if (type == 'local' && path.isNotEmpty) return null;
    if (type != 'local' && enabled && !pathPattern.hasMatch(path)) return null;
    if (path.isNotEmpty && !pathPattern.hasMatch(path)) return null;
    if (path.isNotEmpty && type == 'video' && !path.endsWith('.mp4'))
      return null;
    if (path.isNotEmpty && type == 'image' && path.endsWith('.mp4'))
      return null;
    return StartupPresentation(
      enabled: enabled,
      mediaType: type,
      storagePath: path,
      durationSeconds: duration,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'mediaType': mediaType,
    'storagePath': storagePath,
    'durationSeconds': durationSeconds,
  };

  Future<String> downloadUrl() => FirebaseStorage.instance
      .ref(storagePath)
      .getDownloadURL()
      .timeout(const Duration(seconds: 3));
}

class StartupPresentationSettings {
  static DocumentReference<Map<String, dynamic>> get reference =>
      FirebaseFirestore.instance.collection('app_settings').doc('startup');

  static Future<StartupPresentation> loadForLaunch() async {
    try {
      // Do not indefinitely delay launch or use a stale disabled/enabled setting.
      final doc = await reference
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 2));
      return doc.exists
          ? StartupPresentation.fromMap(doc.data() ?? {}) ??
                const StartupPresentation()
          : const StartupPresentation();
    } catch (_) {
      return const StartupPresentation();
    }
  }
}
