import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  none,
  admin,
  subadmin,
  owner,
}

class AdminRoleService {
  static CollectionReference<Map<String, dynamic>> get _roles =>
      FirebaseFirestore.instance.collection('admin_roles');

  static String normalizeContact(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '');
  }

  static AdminRole _parseRole(Map<String, dynamic>? data) {
    if (data == null) return AdminRole.none;
    final active = data['active'] != false;
    if (!active) return AdminRole.none;
    final role = (data['role'] ?? '').toString().toLowerCase();
    if (role == 'owner') return AdminRole.owner;
    if (role == 'admin') return AdminRole.admin;
    if (role == 'subadmin') return AdminRole.subadmin;
    return AdminRole.none;
  }

  static Future<AdminRole> getRoleForContact(String contact) async {
    final normalized = normalizeContact(contact);
    if (normalized.isEmpty) return AdminRole.none;
    final snap = await _roles.doc(normalized).get();
    return _parseRole(snap.data());
  }

  static Stream<AdminRole> watchRoleForContact(String contact) {
    final normalized = normalizeContact(contact);
    if (normalized.isEmpty) return Stream.value(AdminRole.none);
    return _roles.doc(normalized).snapshots().map((doc) => _parseRole(doc.data()));
  }

  static Stream<bool> watchHasAdminAccess(String contact) {
    return watchRoleForContact(contact).map((role) => role != AdminRole.none);
  }

  static Future<bool> hasAdminAccess(String contact) async {
    final role = await getRoleForContact(contact);
    return role != AdminRole.none;
  }

  static Future<bool> isOwner(String contact) async {
    final role = await getRoleForContact(contact);
    return role == AdminRole.owner;
  }

  static Future<void> grantSubAdmin({
    required String email,
    required String invitedBy,
  }) async {
    final normalized = normalizeContact(email);
    if (normalized.isEmpty) return;
    await _roles.doc(normalized).set({
      'contact': normalized,
      'role': 'subadmin',
      'active': true,
      'invitedBy': normalizeContact(invitedBy),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> revokeAdmin(String email) async {
    final normalized = normalizeContact(email);
    if (normalized.isEmpty) return;
    await _roles.doc(normalized).set({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
