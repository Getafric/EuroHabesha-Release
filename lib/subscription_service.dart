import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_session.dart';

class SubscriptionService {
  static Future<bool> follow({required String type, required String targetId, required String targetName}) async {
    if (type != 'community' && type != 'event') {
      return false;
    }

    if (AppSession.isGuest || !AppSession.isEmailVerified) {
      return false;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) {
      return false;
    }

    await FirebaseFirestore.instance.collection('subscriptions').doc('${user.uid}_${type}_$targetId').set({
      'userId': user.uid,
      'userEmail': user.email,
      'type': type,
      'targetId': targetId,
      'targetName': targetName,
      'createdAt': FieldValue.serverTimestamp(),
      'notificationEnabled': true,
    }, SetOptions(merge: true));
    return true;
  }
}
