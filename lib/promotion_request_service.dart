import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The saved payload is frozen until the server confirms its exact request ID.
class PromotionRequestService {
  PromotionRequestService({required this.scope, required this.uid});
  final String scope;
  final String uid;
  String get _key => 'eh_promotion_pending_v1_${uid}_$scope';

  void _checkUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError(
        'Connectez-vous avec le compte qui a préparé la demande.',
      );
    }
  }

  Future<Map<String, dynamic>?> loadPending() async {
    _checkUser();
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == null) {
      return null;
    }
    final decoded = jsonDecode(value);
    if (decoded is! Map || decoded['requestId'] is! String) {
      throw StateError(
        'Une demande enregistrée doit être vérifiée avant un nouvel envoi.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<Map<String, dynamic>> prepare(
    Uint8List photo,
    Map<String, dynamic> payload,
  ) async {
    _checkUser();
    if (await loadPending() != null) {
      throw StateError('Vérifiez d’abord la demande déjà enregistrée.');
    }
    if (photo.isEmpty || photo.length >= 8 * 1024 * 1024) {
      throw StateError('La photo doit faire moins de 8 Mo.');
    }
    final requestId = payload['requestId'] as String;
    final storage = FirebaseStorage.instance.ref(
      'advertisement_requests/$uid/$requestId.png',
    );
    await storage.putData(photo, SettableMetadata(contentType: 'image/png'));
    final previewUrl = await storage.getDownloadURL();
    _checkUser();
    final frozen = <String, dynamic>{...payload, '_previewUrl': previewUrl};
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(frozen))) {
      throw StateError(
        'La demande n’a pas pu être enregistrée sur cet appareil. '
        'Aucun envoi au serveur n’a été effectué.',
      );
    }
    return frozen;
  }

  Future<Map<String, dynamic>> prepareEdit(
    Uint8List? photo,
    Map<String, dynamic> payload, {
    required String existingImageUrl,
  }) async {
    _checkUser();
    if (await loadPending() != null) {
      throw StateError('Vérifiez d’abord la modification déjà enregistrée.');
    }
    var previewUrl = existingImageUrl;
    if (photo != null) {
      if (photo.isEmpty || photo.length >= 8 * 1024 * 1024) {
        throw StateError('La photo doit faire moins de 8 Mo.');
      }
      final id = payload['requestId'] as String;
      final editId = payload['editId'] as String;
      final storage = FirebaseStorage.instance.ref(
        'advertisement_requests/$uid/${id}_$editId.png',
      );
      await storage.putData(photo, SettableMetadata(contentType: 'image/png'));
      previewUrl = await storage.getDownloadURL();
    }
    _checkUser();
    final frozen = <String, dynamic>{
      ...payload,
      '_operation': 'update',
      'replacePhoto': photo != null,
      '_previewUrl': previewUrl,
    };
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(frozen))) {
      throw StateError(
        'Enregistrement local impossible. Aucun envoi effectué.',
      );
    }
    return frozen;
  }

  Future<String> sendPending(Map<String, dynamic> frozen) async {
    _checkUser();
    final response = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable(
          frozen['_operation'] == 'update'
              ? 'updateAdvertisementRequest'
              : 'createAdvertisementRequest',
        )
        .call(frozen)
        .timeout(const Duration(seconds: 65));
    _checkUser();
    final id = response.data['requestId'];
    if (id is! String || id != frozen['requestId']) {
      throw StateError('La confirmation de la demande doit être vérifiée.');
    }
    await clearPending();
    return id;
  }

  Future<void> clearPending() async {
    _checkUser();
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.remove(_key)) {
      throw StateError(
        'Impossible de confirmer l’enregistrement sur cet appareil.',
      );
    }
  }

  static Future<void> review(
    String requestId, {
    required bool approved,
    int? expectedRevision,
  }) async {
    await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('reviewAdvertisementRequest')
        .call({
          'requestId': requestId,
          'approved': approved,
          if (expectedRevision != null) 'expectedRevision': expectedRevision,
        })
        .timeout(const Duration(seconds: 35));
  }
}
