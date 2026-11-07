import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'connect_space_model.dart';

class ConnectSpaceService {
  ConnectSpaceService._();
  static FirebaseFirestore get db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get requests =>
      db.collection('connectSpaceRequests');
  static CollectionReference<Map<String, dynamic>> get spaces =>
      db.collection('connectSpaces');

  static Future<void> review(
    String id, {
    required bool approve,
    String note = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      throw StateError('Connexion requise.');
    }
    await db.runTransaction((tx) async {
      final request = await tx.get(requests.doc(id));
      final data = request.data();
      if (data == null || data['status'] != 'pendingApproval') {
        throw StateError(
          'Cette demande a déjà été traitée. Actualisez la liste.',
        );
      }
      tx.update(request.reference, {
        'status': approve ? 'approved' : 'rejected',
        'reviewedBy': user.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewNote': note.trim(),
      });
      if (approve) {
        tx.set(spaces.doc(id), {
          ...connectPublicSpaceFields(data, id),
          'publishedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  static Future<void> askToJoin(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      throw StateError(
        'Connectez-vous et vérifiez votre e-mail pour demander à rejoindre.',
      );
    }
    // Stable per-user document id: repeated taps cannot create several requests.
    await spaces.doc(id).collection('membershipRequests').doc(user.uid).set({
      'userId': user.uid,
      'displayName': user.displayName ?? 'Membre Euro Habesha',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> reviewMember(
    String spaceId,
    String uid, {
    required bool approve,
  }) async {
    final reviewer = FirebaseAuth.instance.currentUser;
    if (reviewer == null) {
      throw StateError('Connexion requise.');
    }
    final parent = spaces.doc(spaceId);
    await db.runTransaction((tx) async {
      final request = await tx.get(
        parent.collection('membershipRequests').doc(uid),
      );
      final data = request.data();
      if (data == null || data['status'] != 'pending') {
        throw StateError('Cette adhésion a déjà été traitée.');
      }
      tx.update(request.reference, {
        'status': approve ? 'approved' : 'rejected',
        'reviewedBy': reviewer.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
      if (approve) {
        tx.set(parent.collection('members').doc(uid), {
          'userId': uid,
          'displayName': data['displayName'],
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
