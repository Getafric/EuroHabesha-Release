import 'l10n/app_ui.dart';

import 'dart:async';

import 'professional_activity_flow.dart';
import 'member_interface_text.dart';
import 'advertisement_request_screen.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_personal_profile_screen.dart';
import 'app_session.dart';
import 'profile_settings_screen.dart';
import 'events_screen.dart';
import 'profile_type_screen.dart';
import 'my_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);
  bool _isGuest = AppSession.isGuest;
  // የተጠቃሚው ፕሮፋይል መረጃዎች (በቀላሉ በስክሪኑ ላይ እንዲዘመኑ)
  String userName = AppSession.displayName;
  String userEmail = AppSession.email;
  String userCity = AppSession.city;
  String userPhone = AppSession.phone;
  String? _photoUrl;
  bool _showCityPublicly = false;
  bool _hasProfessionalProfile = false;
  bool _professionalLoading = true;
  bool _professionalLoadFailed = false;
  bool _hasApprovedProfessionalProfile = false;
  int _professionalLoadVersion = 0;
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _professionalWatchers = [];

  @override
  void dispose() {
    for (final watcher in _professionalWatchers) {
      watcher.cancel();
    }
    super.dispose();
  }

  String _professionalProfileLabel = '';
  @override
  void initState() {
    super.initState();
    _isGuest = AppSession.isGuest;
    userName = AppSession.displayName;
    userEmail = AppSession.email;
    userCity = AppSession.city;
    userPhone = AppSession.phone;
    _loadProfessionalProfile();
    final professionalUser = FirebaseAuth.instance.currentUser;
    if (professionalUser != null && !professionalUser.isAnonymous) {
      for (final source in const [
        'businessSubmissions',
        'jobSubmissions',
        'employerSubmissions',
        'eventSubmissions',
      ]) {
        _professionalWatchers.add(
          FirebaseFirestore.instance
              .collection(source)
              .where('ownerId', isEqualTo: professionalUser.uid)
              .snapshots()
              .listen(
                (_) {
                  if (mounted) {
                    _loadProfessionalProfile();
                  }
                },
                onError: (Object error) {
                  if (mounted) {
                    setState(() {
                      _professionalLoading = false;
                      _professionalLoadFailed = true;
                    });
                  }
                },
              ),
        );
      }
    }
    _loadPersonalProfile();
  }

  Future<void> _loadProfessionalProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    final loadVersion = ++_professionalLoadVersion;
    try {
      final entries = await ProfessionalProfileLookup.load(user.uid);
      if (!mounted ||
          loadVersion != _professionalLoadVersion ||
          FirebaseAuth.instance.currentUser?.uid != user.uid) {
        return;
      }
      setState(() {
        _professionalLoading = false;
        _professionalLoadFailed = false;
        _hasProfessionalProfile = entries.isNotEmpty;
        _hasApprovedProfessionalProfile = entries.any(
          (entry) => activityPublicationApproved(entry.data['status']),
        );
        _professionalProfileLabel = entries.isEmpty ? '' : entries.first.title;
      });
    } catch (error) {
      if (mounted && loadVersion == _professionalLoadVersion) {
        setState(() {
          _professionalLoading = false;
          _professionalLoadFailed = true;
        });
      }
      debugPrint('Chargement du profil professionnel : $error');
    }
  }

  Future<void> _openEditProfile() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditPersonalProfileScreen()),
    );
    if (saved == true) {
      await _loadPersonalProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Profil enregistré avec succès.')),
        );
      }
    }
  }

  Future<void> _loadPersonalProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final d = doc.data() ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        userName = (d['displayName'] ?? user.displayName ?? userName)
            .toString();
        userEmail = user.email ?? userEmail;
        userCity = (d['city'] ?? '').toString();
        userPhone = (d['phone'] ?? '').toString();
        _photoUrl = (d['photoUrl'] ?? user.photoURL)?.toString();
        _showCityPublicly = d['showCityPublicly'] == true;
      });
    } catch (e) {
      debugPrint('Erreur chargement profil personnel: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: AppText(
          'profile.title'.tr(),
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryDarkGreen,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ── ራስጌ የፕሮፋይል ፎቶ እና ዝርዝር ──
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: cardGreen,
                    backgroundImage:
                        _photoUrl != null && _photoUrl!.trim().isNotEmpty
                        ? NetworkImage(_photoUrl!)
                        : null,
                    child: _photoUrl == null || _photoUrl!.trim().isEmpty
                        ? Icon(Icons.person, color: primaryGold, size: 55)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _openEditProfile,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryGold,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.edit,
                          color: primaryDarkGreen,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName,
              style: TextStyle(
                color: primaryGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _isGuest
                  ? 'Browse freely. Sign in only when you want to post or contact.'
                  : '${_showCityPublicly && userCity.trim().isNotEmpty ? '$userCity • ' : ''}$userEmail',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            if (!_isGuest && !AppSession.isSuperAdmin) ...[
              const VerificationStatusCard(),
            ],
            // ── ሴቲንግ እና ዝርዝሮች ──
            Container(
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  // Edit Profile
                  ListTile(
                    leading: Icon(Icons.person_outline, color: primaryGold),
                    title: AppText(
                      'profile.edit_profile'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                    onTap: _openEditProfile,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Profile Settings
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: primaryGold),
                    title: AppText(
                      'profile.settings'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: AppText(
                      'profile.settings_subtitle'.tr(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white54,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // My Orders
                  if (!_isGuest) ...[
                    ListTile(
                      leading: Icon(
                        Icons.receipt_long_outlined,
                        color: primaryGold,
                      ),
                      title: AppText(
                        'profile.my_orders'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: AppText(
                        'profile.my_orders_subtitle'.tr(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyOrdersScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                  ],
                  // One professional entry; extra activities belong in the professional space.
                  if (!_isGuest) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Material(
                        color: const Color(0xFFFFD700),
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF061E12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.business_center_outlined,
                              color: Color(0xFFFFD700),
                              size: 30,
                            ),
                          ),
                          title: Text(
                            _professionalLoading
                                ? memberText(
                                    context,
                                    'Chargement de mes activités…',
                                    'Loading my activities…',
                                  )
                                : _professionalLoadFailed
                                ? memberText(
                                    context,
                                    'Réessayer le chargement',
                                    'Retry loading',
                                  )
                                : _hasApprovedProfessionalProfile
                                ? memberText(
                                    context,
                                    'Mon espace professionnel',
                                    'My professional space',
                                  )
                                : _hasProfessionalProfile
                                ? memberText(
                                    context,
                                    'Suivre ma demande',
                                    'Track my application',
                                  )
                                : memberText(
                                    context,
                                    'Créer et publier',
                                    'Create and publish',
                                  ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            _hasProfessionalProfile
                                ? _professionalProfileLabel
                                : memberText(
                                    context,
                                    'Créer une activité professionnelle',
                                    'Create a professional activity',
                                  ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.black,
                          ),
                          onTap: _professionalLoading
                              ? null
                              : () async {
                                  if (_professionalLoadFailed) {
                                    await _loadProfessionalProfile();
                                    return;
                                  }
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => _hasProfessionalProfile
                                          ? const ProfileTypeScreen()
                                          : const SubmissionMenuScreen(),
                                    ),
                                  );
                                  if (mounted) {
                                    await _loadProfessionalProfile();
                                  }
                                },
                        ),
                      ),
                    ),
                    // Toujours disponible pour les utilisateurs connectés,
                    // y compris le Super Admin.
                    ListTile(
                      leading: Icon(
                        Icons.confirmation_number_outlined,
                        color: primaryGold,
                      ),
                      title: AppText(
                        'profile.my_tickets'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: AppText(
                        'profile.my_tickets_subtitle'.tr(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyTicketsScreen(),
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    ListTile(
                      leading: Icon(Icons.bookmark_outline, color: primaryGold),
                      title: AppText(
                        'profile.saved_listings'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SavedListingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                  ],
                  // Log Out
                  ListTile(
                    leading: Icon(
                      _isGuest ? Icons.login : Icons.logout,
                      color: Colors.orangeAccent,
                    ),
                    title: Text(
                      _isGuest
                          ? 'profile.sign_in_register'.tr()
                          : 'profile.log_out'.tr(),
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    onTap: () {
                      if (_isGuest) {
                        Navigator.pushNamed(context, '/login');
                        return;
                      }
                      final profileContext = context;
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          backgroundColor: cardGreen,
                          title: AppText(
                            'profile.log_out'.tr(),
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: AppText(
                            'profile.log_out_confirm'.tr(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: AppText(
                                'common.cancel'.tr(),
                                style: TextStyle(color: primaryGold),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                              ),
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                AppSession.signOut();
                                if (!profileContext.mounted) {
                                  return;
                                }
                                Navigator.pop(dialogContext);
                                Navigator.of(profileContext)
                                    .pushNamedAndRemoveUntil(
                                      '/login',
                                      (route) => false,
                                    );
                              },
                              child: AppText(
                                'profile.log_out'.tr(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ── ማይ ሴቭድ ሊስቲንግ ገጽ (Saved Listings Screen) ──
// ==========================================
class SavedListingsScreen extends StatelessWidget {
  const SavedListingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);
    // ለምሳሌ የተጠቃሚው ሴቭ ያደረጋቸው ሊስቲንጎች (ወደፊት ከዳታቤዝ ይመጣሉ)
    final List<Map<String, String>> savedItems = [
      {
        'title': 'Habesha Market Lyon',
        'category': 'Grocery & Store',
        'city': 'Lyon, France',
      },
      {
        'title': 'Getafric Production',
        'category': 'Photography & Video',
        'city': 'Lyon, France',
      },
    ];
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const AppText(
          'My Saved Listings',
          style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: savedItems.isEmpty
          ? const Center(
              child: AppText(
                'No saved listings yet.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                return Card(
                  color: cardGreen,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      item['title']!,
                      style: const TextStyle(
                        color: primaryGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: AppText(
                      '${item['category']} • ${item['city']}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(Icons.bookmark, color: primaryGold),
                  ),
                );
              },
            ),
    );
  }
}
