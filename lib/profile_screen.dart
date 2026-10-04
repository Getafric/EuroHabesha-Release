import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'app_session.dart';
import 'profile_settings_screen.dart';
import 'events_screen.dart';
import 'verification_screen.dart';
import 'pro_vip_subscription_screen.dart';
import 'status_badge_widget.dart';
import 'profile_type_screen.dart';
import 'my_orders_screen.dart';
import 'business_dashboard_screen.dart';
import 'event_organizer_dashboard_screen.dart';

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
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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

  // የፕሮፋይል ፎቶ ከጋለሪ የመምረጫ ፊቸር
  Future<void> _pickProfileImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _showEditProfileDialog(BuildContext context) {
    final TextEditingController nameController =
        TextEditingController(text: userName);
    final TextEditingController emailController =
        TextEditingController(text: userEmail);
    final TextEditingController cityController =
        TextEditingController(text: userCity);
    final TextEditingController phoneController =
        TextEditingController(text: userPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: Text('Edit Profile & Credentials',
            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ፎቶ መቀየሪያ አዝራር በዲያሎጉ ውስጥ
              GestureDetector(
                onTap: () async {
                  await _pickProfileImage();
                  Navigator.pop(context);
                  _showEditProfileDialog(
                      context); // ፎቶው ወዲያውኑ እንዲታደስ ዲያሎጉን እንደገና መክፈት
                },
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: primaryDarkGreen,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt, color: primaryGold, size: 25)
                      : null,
                ),
              ),
              const SizedBox(height: 15),
              _buildDialogField('Full Name', nameController),
              const SizedBox(height: 10),
              _buildDialogField('Email Address', emailController),
              const SizedBox(height: 10),
              _buildDialogField('City & Country', cityController),
              const SizedBox(height: 10),
              _buildDialogField('Phone Number', phoneController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;

              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vous devez être connecté.'),
                  ),
                );
                return;
              }

              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              final newCity = cityController.text.trim();
              final newPhone = phoneController.text.trim();

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'displayName': newName,
                  'email': newEmail,
                  'city': newCity,
                  'phone': newPhone,
                  'accountType': 'particulier',
                  'profileCreated': true,
                  'profileUpdatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                if (!mounted) return;

                setState(() {
                  userName = newName;
                  userEmail = newEmail;
                  userCity = newCity;
                  userPhone = newPhone;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil enregistré avec succès.'),
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Impossible d’enregistrer le profil : $e',
                    ),
                  ),
                );
              }
            },
            child: Text('Save Changes',
                style: TextStyle(
                    color: primaryDarkGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('User Profile & Settings',
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
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? Icon(Icons.person, color: primaryGold, size: 55)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showEditProfileDialog(context),
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
                    : '$userCity • $userEmail',
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
                    title: const Text('Edit Profile & Credentials',
                        style: TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 16),
                    onTap: () => _showEditProfileDialog(context),
                  ),
                  const Divider(color: Colors.white24, height: 1),

                  // Profile Settings
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: primaryGold),
                    title: const Text(
                      'Profile Settings',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Notifications, privacy, language, deletion',
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
                      title: const Text(
                        'My Orders',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Track current orders and view order history',
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

                    // Mes événements
                    const SizedBox(height: 10),
                    Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                            Icons.event_available_outlined,
                            color: primaryGold,
                            size: 32,
                          ),
                        ),
                        title: const Text(
                          'Mes événements',
                          style: TextStyle(
                            color: Color(0xFF062E25),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Gérer mes événements et ma billetterie',
                            style: TextStyle(
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const EventOrganizerDashboardScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white24, height: 1),

                  // Request Admin Verification
                  if (!_isGuest) ...[
                    if (!AppSession.isSuperAdmin) ...[
                      ListTile(
                        leading: Icon(
                          Icons.verified_outlined,
                          color: primaryGold,
                        ),
                        title: const Text(
                          'Request Admin Verification',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Submit business SIRET or ID for "✓ Verified" mark',
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
                              builder: (context) => const VerificationScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                      ListTile(
                        leading: Icon(
                          Icons.workspace_premium,
                          color: primaryGold,
                        ),
                        title: const Text(
                          'PRO & VIP Subscriptions',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Upgrade directory ranking via App Store / Google Play',
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
                              builder: (context) =>
                                  const ProVipSubscriptionScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(
                        color: Colors.white24,
                        height: 1,
                      ),
                    ],

                    // Toujours disponible pour les utilisateurs connectés,
                    // y compris le Super Admin.
                    ListTile(
                      leading: Icon(
                        Icons.confirmation_number_outlined,
                        color: primaryGold,
                      ),
                      title: const Text(
                        'My Tickets',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'View your purchased tickets and QR codes',
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
                      title: const Text(
                        'My Saved Listings',
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
                    title: Text(_isGuest ? 'Sign In / Register' : 'Log Out',
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
                          title: const Text('Log Out',
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold)),
                          content: const Text(
                              'Are you sure you want to log out from Euro Habesha?',
                              style: TextStyle(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('Cancel',
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
                              child: const Text('Log Out',
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

  Widget _buildDialogField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: primaryGold, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: primaryDarkGreen,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        ),
      ],
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

class VerificationStatusCard extends StatelessWidget {
  const VerificationStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data == null) return const SizedBox.shrink();

        final isVerified = data['isVerified'] == true ||
            data['verificationStatus'] == 'approved';
        final subTier = data['subscriptionTier']?.toString();
        final isSubActive = data['subscriptionActive'] == true &&
            (subTier == 'pro' || subTier == 'vip');

        if (!isVerified && !isSubActive && data['verificationStatus'] == null) {
          return const SizedBox.shrink();
        }

        return Card(
          color: const Color(0xFF004D40),
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  isVerified ? Icons.check_circle : Icons.verified_outlined,
                  color: isVerified
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFFD700),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isVerified
                                ? '✓ Verified by Admin'
                                : 'Verification: ${data['verificationStatus'] ?? 'Not Verified'}',
                            style: TextStyle(
                              color: isVerified
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          if (isSubActive) ...[
                            const SizedBox(width: 8),
                            StatusBadgeWidget(
                                subscriptionTier: subTier, compact: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isVerified
                            ? 'Your official business/identity proof has been confirmed.'
                            : 'Verification request is under admin review.',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
