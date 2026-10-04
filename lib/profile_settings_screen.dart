import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'app_session.dart';
import 'events_screen.dart';
import 'verification_screen.dart';
import 'pro_vip_subscription_screen.dart';
import 'status_badge_widget.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  bool _pushNotificationsEnabled = true;
  bool _phonePublic = false;
  bool _isGuest = AppSession.isGuest;
  String _selectedLanguage = 'Auto';

  // የተጠቃሚው ፕሮፋይል መረጃዎች (በቀላሉ በስክሪኑ ላይ እንዲዘመኑ)
  String userName = AppSession.displayName;
  String userEmail = AppSession.email;
  String userCity = AppSession.city;
  String userPhone = AppSession.phone;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _selectedLanguage = switch (languageCode) {
      'fr' => 'French',
      'nl' => 'Dutch',
      'am' => 'Amharic',
      _ => 'English',
    };
    _isGuest = AppSession.isGuest;
    userName = AppSession.displayName;
    userEmail = AppSession.email;
    userCity = AppSession.city;
    userPhone = AppSession.phone;
  }

  // የፕሮፋይል ፎቶ ከጋለሪ የመምረጫ ፊቸር
  Future<void> _pickProfileImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _savePublicProfile({
    required String name,
    required String city,
    required String phone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Please sign in first.');
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Full name is required.');
    }

    String? photoUrl;

    final existingUser = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    photoUrl = existingUser.data()?['photoUrl']?.toString();

    if (_profileImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profilePhotos')
          .child(user.uid)
          .child('profile.jpg');

      await storageRef.putFile(_profileImage!);
      photoUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': cleanName,
      'photoUrl': photoUrl,
      'city': city.trim(),
      'phone': phone.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.updateDisplayName(cleanName);

    AppSession.displayName = cleanName;
    AppSession.city = city.trim();
    AppSession.phone = phone.trim();

    if (!mounted) return;

    setState(() {
      userName = cleanName;
      userCity = city.trim();
      userPhone = phone.trim();
    });
  }

  // 1. የተሟላ የፕሮፋይል ማስተካከያ ፖፕ-አፕ (ስም፣ ኢሜል፣ ከተማ፣ ስልክ እና ፎቶ)
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
      builder: (dialogContext) => AlertDialog(
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
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
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
            onPressed: () => Navigator.pop(dialogContext),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
            onPressed: () async {
              try {
                await _savePublicProfile(
                  name: nameController.text,
                  city: cityController.text,
                  phone: phoneController.text,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                  ),
                );
              } catch (error) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile could not be saved: $error'),
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

  // 2. አካውንት የማጥፊያ ማረጋገጫ
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text('Delete Account',
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to delete your account? This action is permanent and will remove all your data, posts, and listings from Euro Habesha.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account successfully deleted.')),
              );
            },
            child: const Text('Delete Permanently',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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
            if (!_isGuest) ...[
              const SizedBox(height: 4),
              Text(
                _phonePublic
                    ? 'Phone visible publicly: $userPhone'
                    : 'Phone number is private',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
            const SizedBox(height: 25),

            if (!_isGuest) ...[
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

                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: primaryGold),
                    title: Text('profile_settings'.tr(),
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        'Notifications, privacy, language, deletion',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ProfileSettingsScreen()),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),

                  if (!_isGuest && !AppSession.isSuperAdmin) ...[
                    ListTile(
                      leading:
                          Icon(Icons.verified_outlined, color: primaryGold),
                      title: const Text('Request Admin Verification',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                          'Submit business SIRET or ID for "✓ Verified" mark',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VerificationScreen()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.workspace_premium, color: primaryGold),
                      title: const Text('PRO & VIP Subscriptions',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                          'Upgrade directory ranking via App Store / Google Play',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ProVipSubscriptionScreen()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    ListTile(
                      leading: Icon(Icons.confirmation_number_outlined,
                          color: primaryGold),
                      title: const Text('My Tickets',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                          'View your purchased tickets and QR codes',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MyTicketsScreen())),
                    ),
                    const Divider(color: Colors.white24, height: 1),
                    ListTile(
                      leading: Icon(Icons.bookmark_outline, color: primaryGold),
                      title: const Text('My Saved Listings',
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const SavedListingsScreen()),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                  ],

                  // Notifications Toggle
                  SwitchListTile(
                    secondary:
                        Icon(Icons.notifications_outlined, color: primaryGold),
                    title: const Text('Push Notifications',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Receive alerts & updates',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                    activeThumbColor: primaryGold,
                    value: _pushNotificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(value
                                ? 'Notifications enabled'
                                : 'Notifications disabled')),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),

                  if (!_isGuest) ...[
                    SwitchListTile(
                      secondary: Icon(Icons.phone_android, color: primaryGold),
                      title: const Text('Phone Number Visibility',
                          style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                          _phonePublic
                              ? 'Public on profile and listings'
                              : 'Private and hidden from other users',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      activeThumbColor: primaryGold,
                      value: _phonePublic,
                      onChanged: (bool value) {
                        setState(() => _phonePublic = value);
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                  ],

                  ListTile(
                    leading: Icon(Icons.language, color: primaryGold),
                    title: const Text('Language',
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text('Current: $_selectedLanguage',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: cardGreen,
                      underline: const SizedBox.shrink(),
                      iconEnabledColor: primaryGold,
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        'System language',
                        'English',
                        'French',
                        'Amharic',
                        'Tigrinya',
                      ].map((language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value == null) return;

                        switch (value) {
                          case 'System language':
                            await context.resetLocale();
                            break;

                          case 'English':
                            await context.setLocale(const Locale('en'));
                            break;

                          case 'French':
                            await context.setLocale(const Locale('fr'));
                            break;

                          case 'Amharic':
                            await context.setLocale(const Locale('am'));
                            break;

                          case 'Tigrinya':
                            await context.setLocale(const Locale('ti'));
                            break;
                        }

                        if (!mounted) return;

                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 1),

                  if (!_isGuest) ...[
                    ListTile(
                      leading: Icon(Icons.lock_outline, color: primaryGold),
                      title: const Text('Privacy & Security (GDPR)',
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: cardGreen,
                            title: Text('Privacy & Data Protection',
                                style: TextStyle(
                                    color: primaryGold,
                                    fontWeight: FontWeight.bold)),
                            content: const SingleChildScrollView(
                              child: Text(
                                'Euro Habesha operates strictly under European General Data Protection Regulation (GDPR) standards.\n\n'
                                '• Your personal information, phone number, and listings are fully encrypted and secured.\n'
                                '• We do not share your data with third-party advertising networks.\n'
                                '• You have the full right to export or permanently delete your data at any time through your profile settings.',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text('Got It',
                                    style: TextStyle(color: primaryGold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
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

                  if (!_isGuest)
                    ListTile(
                      leading: const Icon(Icons.delete_forever,
                          color: Colors.redAccent),
                      title: const Text('Delete My Account',
                          style: TextStyle(color: Colors.redAccent)),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
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

    final List<Map<String, String>> savedItems = const [
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

// ==========================================
// Profile Settings Screen
// ==========================================

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  bool _pushNotificationsEnabled = true;
  bool _phonePublic = false;
  String _selectedLanguage = 'Auto';

  @override
  void initState() {
    super.initState();

    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    _selectedLanguage = switch (languageCode) {
      'fr' => 'French',
      'am' => 'Amharic',
      'ti' => 'Tigrinya',
      _ => 'English',
    };
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardGreen,
        title: Text(
          'Privacy & Data Protection',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Manage your privacy and personal data settings for Euro Habesha.',
          style: TextStyle(
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Close',
              style: TextStyle(color: primaryGold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action is permanent.',
          style: TextStyle(
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: primaryGold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion is not connected yet.',
                  ),
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
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
        backgroundColor: const Color(0xFF0B2F20),
        foregroundColor: Colors.white,
        title: const Text(
          'Profile Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        children: [
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: primaryGold,
            ),
            title: const Text(
              'Push Notifications',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Receive alerts & updates',
              style: TextStyle(color: Colors.white54),
            ),
            activeThumbColor: primaryGold,
            value: _pushNotificationsEnabled,
            onChanged: (value) {
              setState(() {
                _pushNotificationsEnabled = value;
              });
            },
          ),
          const Divider(color: Colors.white24),
          SwitchListTile(
            secondary: Icon(
              Icons.phone_android,
              color: primaryGold,
            ),
            title: const Text(
              'Phone Privacy',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _phonePublic
                  ? 'Your phone number is public'
                  : 'Your phone number is private',
              style: const TextStyle(color: Colors.white54),
            ),
            activeThumbColor: primaryGold,
            value: _phonePublic,
            onChanged: (value) {
              setState(() {
                _phonePublic = value;
              });
            },
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: Icon(
              Icons.language,
              color: primaryGold,
            ),
            title: const Text(
              'Language',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Current: $_selectedLanguage',
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: cardGreen,
              underline: const SizedBox.shrink(),
              iconEnabledColor: primaryGold,
              style: const TextStyle(color: Colors.white),
              items: const [
                'System language',
                'English',
                'French',
                'Amharic',
                'Tigrinya',
              ].map((language) {
                return DropdownMenuItem<String>(
                  value: language,
                  child: Text(language),
                );
              }).toList(),
              onChanged: (value) async {
                if (value == null) return;

                switch (value) {
                  case 'System language':
                    await context.resetLocale();
                    break;

                  case 'English':
                    await context.setLocale(const Locale('en'));
                    break;

                  case 'French':
                    await context.setLocale(const Locale('fr'));
                    break;

                  case 'Amharic':
                    await context.setLocale(const Locale('am'));
                    break;

                  case 'Tigrinya':
                    await context.setLocale(const Locale('ti'));
                    break;
                }

                if (!mounted) return;

                setState(() {
                  _selectedLanguage = value;
                });
              },
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: Icon(
              Icons.lock_outline,
              color: primaryGold,
            ),
            title: const Text(
              'Privacy & Security',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Privacy and personal data',
              style: TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
            onTap: _showPrivacyDialog,
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(
              Icons.delete_forever,
              color: Colors.redAccent,
            ),
            title: const Text(
              'Delete My Account',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Permanently delete your account and data',
              style: TextStyle(color: Colors.white54),
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
