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
import 'business_dashboard_screen.dart';
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
    _loadPersonalProfile();
  }
  Future<void> _loadProfessionalProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }
    try {
      final business = await FirebaseFirestore.instance
          .collection('businessSubmissions')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (business.docs.isNotEmpty) {
        final data = business.docs.first.data();
        final fields = Map<String, dynamic>.from(
          data['fields'] ?? <String, dynamic>{},
        );
        final businessName = fields['title']?.toString().trim();
        if (!mounted) return;
        setState(() {
          _hasProfessionalProfile = true;
          _professionalProfileLabel =
              businessName != null && businessName.isNotEmpty
                  ? businessName
                  : 'Mon entreprise';
        });
        return;
      }
      final job = await FirebaseFirestore.instance
          .collection('jobSubmissions')
          .where('ownerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (job.docs.isNotEmpty) {
        final data = job.docs.first.data();
        final fields = Map<String, dynamic>.from(
          data['fields'] ?? <String, dynamic>{},
        );
        final businessName = fields['title']?.toString().trim();
        if (!mounted) return;
        setState(() {
          _hasProfessionalProfile = true;
          _professionalProfileLabel =
              businessName != null && businessName.isNotEmpty
                  ? businessName
                  : 'Mon activité professionnelle';
        });
      }
    } catch (e) {
      debugPrint(
        'Erreur chargement profil professionnel: $e',
      );
    }
  }
  Future<void> _openEditProfile() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EditPersonalProfileScreen()),
    );
    if (saved == true) {
      await _loadPersonalProfile();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil enregistré avec succès.')),
      );
    }
  }

  Future<void> _loadPersonalProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = doc.data() ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        userName = (d['displayName'] ?? user.displayName ?? userName).toString();
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
        title: Text('profile.title'.tr(),
            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
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
                    backgroundImage: _photoUrl != null && _photoUrl!.trim().isNotEmpty
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
                            color: primaryGold, shape: BoxShape.circle),
                        child:
                            Icon(Icons.edit, color: primaryDarkGreen, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(userName,
                style: TextStyle(
                    color: primaryGold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
                _isGuest
                    ? 'Browse freely. Sign in only when you want to post or contact.'
                    : '${_showCityPublicly && userCity.trim().isNotEmpty ? '$userCity • ' : ''}$userEmail',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center),
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
                    title: Text('profile.edit_profile'.tr(),
                        style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 16),
                    onTap: _openEditProfile,
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  // Profile Settings
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: primaryGold),
                    title: Text(
                      'profile.settings'.tr(),
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'profile.settings_subtitle'.tr(),
                      style: TextStyle(color: Colors.white38, fontSize: 11),
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
                      title: Text(
                        'profile.my_orders'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'profile.my_orders_subtitle'.tr(),
                        style: TextStyle(
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
                    const Divider(
                      color: Colors.white24,
                      height: 1,
                    ),
                  ],
                  // Créer mon profil / Espace professionnel
                  if (!_isGuest) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      child: Material(
                        color: primaryGold,
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFF062E25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.business_center_outlined,
                              color: primaryGold,
                              size: 32,
                            ),
                          ),
                          title: Text(
                            _hasProfessionalProfile
                                ? 'Mon espace professionnel'
                                : 'Créer mon profil',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF062E25),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _hasProfessionalProfile &&
                                      _professionalProfileLabel.isNotEmpty
                                  ? _professionalProfileLabel
                                  : 'Créer une activité professionnelle',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF164B3F),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF062E25),
                            size: 18,
                          ),
                          onTap: () async {
                            final uid = FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              final business = await FirebaseFirestore.instance
                                  .collection('businessSubmissions')
                                  .where('ownerId', isEqualTo: uid)
                                  .limit(1)
                                  .get();
                              final job = await FirebaseFirestore.instance
                                  .collection('jobSubmissions')
                                  .where('ownerId', isEqualTo: uid)
                                  .limit(1)
                                  .get();
                              if (!mounted) return;
                              if (business.docs.isNotEmpty ||
                                  job.docs.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const BusinessDashboardScreen(),
                                  ),
                                );
                                return;
                              }
                            }
                            if (!mounted) return;
                            await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileTypeScreen(),
                              ),
                            );
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
                      title: Text(
                        'profile.my_tickets'.tr(),
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'profile.my_tickets_subtitle'.tr(),
                        style: TextStyle(
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
                    const Divider(
                      color: Colors.white24,
                      height: 1,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.bookmark_outline,
                        color: primaryGold,
                      ),
                      title: Text(
                        'profile.saved_listings'.tr(),
                        style: TextStyle(color: Colors.white),
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
                    const Divider(
                      color: Colors.white24,
                      height: 1,
                    ),
                  ],
                  // Log Out
                  ListTile(
                    leading: Icon(_isGuest ? Icons.login : Icons.logout,
                        color: Colors.orangeAccent),
                    title: Text(
                        _isGuest
                            ? 'profile.sign_in_register'.tr()
                            : 'profile.log_out'.tr(),
                        style: const TextStyle(color: Colors.orangeAccent)),
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
                          title: Text('profile.log_out'.tr(),
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold)),
                          content: Text('profile.log_out_confirm'.tr(),
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('common.cancel'.tr(),
                                  style: TextStyle(color: primaryGold)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent),
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
                              child: Text('profile.log_out'.tr(),
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
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
        'city': 'Lyon, France'
      },
      {
        'title': 'Getafric Production',
        'category': 'Photography & Video',
        'city': 'Lyon, France'
      },
    ];
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('My Saved Listings',
            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: savedItems.isEmpty
          ? const Center(
              child: Text('No saved listings yet.',
                  style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                return Card(
                  color: cardGreen,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(item['title']!,
                        style: const TextStyle(
                            color: primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    subtitle: Text('${item['category']} • ${item['city']}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    trailing: const Icon(Icons.bookmark, color: primaryGold),
                  ),
                );
              },
            ),
    );
  }
}
