import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_role_service.dart';
import 'login_screen.dart';
import 'session_state.dart';

class AdminAccessDiagnostics {
  const AdminAccessDiagnostics({
    required this.granted,
    required this.byClaim,
    required this.byRoleDoc,
    required this.byUserRole,
    required this.normalizedContact,
    required this.rawEmail,
    required this.uid,
    required this.claimRole,
    required this.claimAdmin,
    required this.claimOwner,
    required this.roleDocId,
    required this.roleDocRole,
    required this.roleDocActive,
    required this.roleDocReadError,
    required this.userRole,
    required this.userDocReadError,
  });

  final bool granted;
  final bool byClaim;
  final bool byRoleDoc;
  final bool byUserRole;

  final String normalizedContact;
  final String rawEmail;
  final String uid;

  final String claimRole;
  final bool claimAdmin;
  final bool claimOwner;

  final String roleDocId;
  final String roleDocRole;
  final bool roleDocActive;
  final String roleDocReadError;

  final String userRole;
  final String userDocReadError;
}

class AccessControl {
  static const Set<String> _elevatedRoles = {'owner', 'subadmin', 'admin'};

  static Stream<bool> _asBroadcast(Stream<bool> stream) {
    if (stream.isBroadcast) return stream;
    return stream.asBroadcastStream();
  }

  static String? currentNormalizedContact() {
    final fromSession = AdminRoleService.normalizeContact(SessionState.verifiedContact ?? '');
    if (fromSession.isNotEmpty) return fromSession;
    final authEmail = AdminRoleService.normalizeContact(FirebaseAuth.instance.currentUser?.email ?? '');
    if (authEmail.isNotEmpty) return authEmail;
    return null;
  }

  static String? _currentUid() {
    final fromSession = (SessionState.currentUid ?? '').trim();
    if (fromSession.isNotEmpty) return fromSession;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static bool _isElevatedRole(dynamic role) {
    final normalized = (role ?? '').toString().trim().toLowerCase();
    return _elevatedRoles.contains(normalized);
  }

  static Future<bool> _hasElevatedRoleByUid(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return _isElevatedRole(doc.data()?['role']);
  }

  static Stream<bool> _watchElevatedRoleByUid(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => _isElevatedRole(doc.data()?['role']));
  }

  static Stream<bool> watchCurrentUserAdminAccess() {
    final contact = currentNormalizedContact();
    final uid = _currentUid();

    if ((contact == null || contact.isEmpty) && (uid == null || uid.isEmpty)) {
      return _asBroadcast(Stream<bool>.value(false));
    }

    if (contact != null && contact.isNotEmpty && uid != null && uid.isNotEmpty) {
      final controller = StreamController<bool>.broadcast();
      var hasRoleDocAccess = false;
      var hasUserRoleAccess = false;

      late final StreamSubscription<bool> roleSub;
      late final StreamSubscription<bool> userSub;

      void emit() {
        if (!controller.isClosed) {
          controller.add(hasRoleDocAccess || hasUserRoleAccess);
        }
      }

      controller.onListen = () {
        roleSub = AdminRoleService.watchHasAdminAccess(contact).listen((value) {
          hasRoleDocAccess = value;
          emit();
        });
        userSub = _watchElevatedRoleByUid(uid).listen((value) {
          hasUserRoleAccess = value;
          emit();
        });
      };

      controller.onCancel = () async {
        await roleSub.cancel();
        await userSub.cancel();
      };

      return _asBroadcast(controller.stream);
    }

    if (contact != null && contact.isNotEmpty) {
      return _asBroadcast(AdminRoleService.watchHasAdminAccess(contact));
    }

    return _asBroadcast(_watchElevatedRoleByUid(uid!));
  }

  static Future<bool> hasCurrentUserAdminAccess() async {
    final contact = currentNormalizedContact();
    final uid = _currentUid();

    bool hasRoleDocAccess = false;
    bool hasUserRoleAccess = false;

    if (contact != null && contact.isNotEmpty) {
      hasRoleDocAccess = await AdminRoleService.hasAdminAccess(contact);
    }
    if (uid != null && uid.isNotEmpty) {
      hasUserRoleAccess = await _hasElevatedRoleByUid(uid);
    }

    return hasRoleDocAccess || hasUserRoleAccess;
  }

  static Future<AdminAccessDiagnostics> diagnoseCurrentUserAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = (user?.uid ?? _currentUid() ?? '').trim();
    final rawEmail = (user?.email ?? '').trim();
    final normalizedContact = currentNormalizedContact() ?? '';

    var claimAdmin = false;
    var claimOwner = false;
    var claimRole = '';
    try {
      if (user != null) {
        final token = await user.getIdTokenResult();
        final claims = token.claims ?? const <String, dynamic>{};
        claimAdmin = claims['admin'] == true;
        claimOwner = claims['owner'] == true;
        claimRole = (claims['role'] ?? '').toString().trim().toLowerCase();
      }
    } catch (_) {
      // Claims are optional; diagnostics should continue even when unavailable.
    }

    String roleDocId = '';
    String roleDocRole = '';
    var roleDocActive = false;
    String roleDocReadError = '';
    var byRoleDoc = false;

    final roleDocKeys = <String>{};
    if (normalizedContact.isNotEmpty) roleDocKeys.add(normalizedContact);
    if (rawEmail.isNotEmpty) roleDocKeys.add(rawEmail);
    if (uid.isNotEmpty) roleDocKeys.add(uid);

    for (final key in roleDocKeys) {
      try {
        final doc = await FirebaseFirestore.instance.collection('admin_roles').doc(key).get();
        if (!doc.exists) continue;

        final data = doc.data() ?? const <String, dynamic>{};
        final active = data['active'] != false;
        final role = (data['role'] ?? '').toString().trim().toLowerCase();

        if (roleDocId.isEmpty) {
          roleDocId = key;
          roleDocRole = role;
          roleDocActive = active;
        }

        if (active && _isElevatedRole(role)) {
          byRoleDoc = true;
          roleDocId = key;
          roleDocRole = role;
          roleDocActive = true;
          break;
        }
      } on FirebaseException catch (error) {
        if (roleDocReadError.isEmpty) {
          roleDocReadError = error.code;
        }
      } catch (_) {
        if (roleDocReadError.isEmpty) {
          roleDocReadError = 'read-failed';
        }
      }
    }

    var userRole = '';
    String userDocReadError = '';
    var byUserRole = false;
    if (uid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        userRole = (userDoc.data()?['role'] ?? '').toString().trim().toLowerCase();
        byUserRole = _isElevatedRole(userRole);
      } on FirebaseException catch (error) {
        userDocReadError = error.code;
      } catch (_) {
        userDocReadError = 'read-failed';
      }
    }

    final byClaim = claimAdmin || claimOwner || _isElevatedRole(claimRole);
    return AdminAccessDiagnostics(
      granted: byClaim || byRoleDoc || byUserRole,
      byClaim: byClaim,
      byRoleDoc: byRoleDoc,
      byUserRole: byUserRole,
      normalizedContact: normalizedContact,
      rawEmail: rawEmail,
      uid: uid,
      claimRole: claimRole,
      claimAdmin: claimAdmin,
      claimOwner: claimOwner,
      roleDocId: roleDocId,
      roleDocRole: roleDocRole,
      roleDocActive: roleDocActive,
      roleDocReadError: roleDocReadError,
      userRole: userRole,
      userDocReadError: userDocReadError,
    );
  }

  static Future<bool> isCurrentUserOwner() async {
    final contact = currentNormalizedContact();
    if (contact != null && contact.isNotEmpty) {
      final byContact = await AdminRoleService.isOwner(contact);
      if (byContact) return true;
    }

    final uid = _currentUid();
    if (uid != null && uid.isNotEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = (doc.data()?['role'] ?? '').toString().trim().toLowerCase();
      if (role == 'owner') return true;
    }

    return false;
  }

  static Future<bool> ensureAdminAccess(BuildContext context, {String? actionLabel}) async {
    if (!ensureVerified(context, actionLabel: actionLabel)) {
      return false;
    }

    final contact = currentNormalizedContact();
    if (contact == null || contact.isEmpty) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to verify your account contact for admin access.')),
      );
      return false;
    }

    final granted = await hasCurrentUserAdminAccess();
    if (granted) {
      return true;
    }

    if (!context.mounted) return false;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: const Text('Admin access denied', style: TextStyle(color: Colors.white)),
          content: const Text(
            'You do not have admin access yet. Ask the owner to invite your account email as sub-admin.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
    return false;
  }

  static bool ensureVerified(BuildContext context, {String? actionLabel}) {
    final authUser = FirebaseAuth.instance.currentUser;
    final hasAuthSession = authUser != null;

    if (!hasAuthSession) {
      SessionState.enterGuest();
    }

    if (hasAuthSession && (SessionState.isGuest || !SessionState.isVerified)) {
      final contact = (authUser.email ?? authUser.uid).trim();
      SessionState.markVerified(
        contact,
        approved: true,
        uid: authUser.uid,
        name: (authUser.displayName ?? '').trim().isEmpty ? null : authUser.displayName,
      );
    }

    if (hasAuthSession && !SessionState.isGuest && SessionState.isVerified) {
      return true;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          titlePadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Create Free Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          content: Text(
            actionLabel == null
                ? 'Create a free account to access this service.'
                : 'Create a free account to access this service: $actionLabel',
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Maybe later', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Create Free Account'),
            ),
          ],
        );
      },
    );

    return false;
  }

  static bool ensureApprovedContributor(BuildContext context, {String? actionLabel}) {
    if (!ensureVerified(context, actionLabel: actionLabel)) {
      return false;
    }

    if (SessionState.isApproved) {
      return true;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: Text(
            tr('pending_admin_approval'),
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            tr('pending_admin_approval_detail'),
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(tr('ok'), style: const TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );

    return false;
  }
}
