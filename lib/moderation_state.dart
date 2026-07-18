import 'package:shared_preferences/shared_preferences.dart';

class PendingContentItem {
  final String id;
  final String type;
  final String title;
  final String submittedBy;
  final DateTime createdAt;

  PendingContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.submittedBy,
    required this.createdAt,
  });
}

class ModerationState {
  static const String _ownerContactKey = 'owner_admin_contact';
  static const String _subAdminsKey = 'granted_admin_contacts';

  static String? ownerContact;
  static bool _isInitialized = false;

  static final List<String> subAdmins = ['community@eurohabesha.app'];

  static final List<PendingContentItem> pendingContent = [
    PendingContentItem(
      id: 'seed_profile_1',
      type: 'Profile',
      title: 'Professional profile update',
      submittedBy: 'new.member@diaspora.eu',
      createdAt: DateTime(2026, 6, 10),
    ),
  ];

  static String normalizeContact(String contact) {
    return contact.trim().toLowerCase().replaceAll(' ', '');
  }

  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    ownerContact = normalizeContact(prefs.getString(_ownerContactKey) ?? '');

    final saved = prefs.getStringList(_subAdminsKey);
    if (saved != null && saved.isNotEmpty) {
      subAdmins
        ..clear()
        ..addAll(saved.map(normalizeContact).where((item) => item.isNotEmpty));
    } else {
      subAdmins
        ..clear()
        ..add('community@eurohabesha.app');
      await _persistSubAdmins();
    }

    _isInitialized = true;
  }

  static Future<void> setOwnerIfMissing(String contact) async {
    final normalized = normalizeContact(contact);
    if (normalized.isEmpty) return;
    await ensureInitialized();
    if ((ownerContact ?? '').isNotEmpty) return;

    ownerContact = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ownerContactKey, normalized);
  }

  static bool isOwner(String contact) {
    final normalized = normalizeContact(contact);
    return normalized.isNotEmpty && normalized == (ownerContact ?? '');
  }

  static Future<void> addSubAdmin(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    if (!subAdmins.contains(normalized)) {
      subAdmins.add(normalized);
      await _persistSubAdmins();
    }
  }

  static Future<void> removeSubAdminAt(int index) async {
    if (index < 0 || index >= subAdmins.length) return;
    subAdmins.removeAt(index);
    await _persistSubAdmins();
  }

  static Future<void> _persistSubAdmins() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_subAdminsKey, subAdmins.map(normalizeContact).toList());
  }

  static void addPendingContent({
    required String type,
    required String title,
    required String submittedBy,
  }) {
    pendingContent.insert(
      0,
      PendingContentItem(
        id: '${type.toLowerCase()}_${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        submittedBy: submittedBy,
        createdAt: DateTime.now(),
      ),
    );
  }

  static PendingContentItem? approveAt(int index) {
    if (index < 0 || index >= pendingContent.length) return null;
    return pendingContent.removeAt(index);
  }

  static PendingContentItem? rejectAt(int index) {
    if (index < 0 || index >= pendingContent.length) return null;
    return pendingContent.removeAt(index);
  }
}
