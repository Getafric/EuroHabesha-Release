import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSession {
  static const String superAdminEmail = 'getafricshow1@gmail.com';

  static bool isGuest = true;
  static bool isEmailVerified = false;
  static bool isSuperAdmin = false;
  static List<String> roles = [];

  static String displayName = 'Guest mode';
  static String email = '';
  static String city = 'Browse Euro Habesha';
  static String phone = '';
  static String photoUrl = '';

  static bool get isSuperAdminAccount =>
      email.trim().toLowerCase() == superAdminEmail;

  static void continueAsGuest() {
    isGuest = true;
    isEmailVerified = false;
    isSuperAdmin = false;
    roles = [];

    displayName = 'Guest mode';
    email = '';
    city = 'Browse Euro Habesha';
    phone = '';
    photoUrl = '';
  }

  static void signIn({
    required String name,
    required String emailAddress,
    bool verified = true,
    List<String> assignedRoles = const [],
    bool superAdminValidated = false,
  }) {
    final normalizedEmail = emailAddress.trim().toLowerCase();

    isGuest = false;
    isEmailVerified = verified;

    isSuperAdmin = superAdminValidated && normalizedEmail == superAdminEmail;

    roles = isSuperAdmin ? ['superAdmin'] : List<String>.from(assignedRoles);

    displayName = name.trim().isEmpty ? emailAddress : name.trim();

    email = emailAddress;
    city = 'Set your city in profile settings';
    phone = '';
    photoUrl = FirebaseAuth.instance.currentUser?.photoURL?.trim() ?? '';
  }

  static Future<void> restoreFromFirebase() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      continueAsGuest();
      return;
    }

    final emailAddress = user.email ?? '';
    final normalizedEmail = emailAddress.trim().toLowerCase();

    final keepValidatedSuperAdmin =
        isSuperAdmin && normalizedEmail == superAdminEmail;

    isGuest = false;
    isEmailVerified = user.emailVerified;

    displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (emailAddress.isNotEmpty ? emailAddress : 'Euro Habesha Member');

    email = emailAddress;
    city = 'Set your city in profile settings';
    phone = '';
    photoUrl = user.photoURL?.trim() ?? '';

    isSuperAdmin = keepValidatedSuperAdmin;

    if (isSuperAdmin) {
      roles = ['superAdmin'];
      return;
    }

    roles = [];

    if (normalizedEmail.isEmpty) {
      return;
    }

    try {
      final inviteDocument = await FirebaseFirestore.instance
          .collection('adminInvites')
          .doc(normalizedEmail)
          .get();

      if (!inviteDocument.exists) {
        return;
      }

      final data = inviteDocument.data();

      if (data == null ||
          data['status']?.toString().toLowerCase() != 'active') {
        return;
      }

      final invitedUserId = data['invitedUserId']?.toString().trim() ?? '';

      if (invitedUserId.isNotEmpty && invitedUserId != user.uid) {
        return;
      }

      final role = data['role']?.toString().trim() ?? '';
      final scope = data['scope']?.toString().trim() ?? '';

      final permissions = data['permissions'] is List
          ? List<String>.from(
              (data['permissions'] as List)
                  .map((permission) => permission.toString()),
            )
          : <String>[];

      roles = [
        if (role.isNotEmpty) role,
        if (scope.isNotEmpty) 'scoped:$scope',
        ...permissions,
      ];
    } on FirebaseException {
      roles = [];
    }
  }

  static void signOut() {
    continueAsGuest();
  }
}
