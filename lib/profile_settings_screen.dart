import 'notification_service.dart';
import 'local_campaign_preferences.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

String languageLabel(BuildContext context, String code) {
  switch (code) {
    case 'system':
      return 'languages.system'.tr();
    case 'en':
      return 'languages.english'.tr();
    case 'fr':
      return 'languages.french'.tr();
    case 'de':
      return 'languages.german'.tr();
    case 'it':
      return 'languages.italian'.tr();
    case 'es':
      return 'languages.spanish'.tr();
    case 'nl':
      return 'languages.dutch'.tr();
    case 'sv':
      return 'languages.swedish'.tr();
    case 'da':
      return 'languages.danish'.tr();
    case 'no':
      return 'languages.norwegian'.tr();
    default:
      return 'languages.english'.tr();
  }
}

const String _languagePreferenceKey = 'app_language_mode';

Future<void> saveLanguagePreference(String code) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_languagePreferenceKey, code);
}

Future<String> loadLanguagePreference() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_languagePreferenceKey) ?? 'system';
}

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
  String _selectedLanguage = 'system';

  // የተጠቃሚው ፕሮፋይል መረጃዎች
  String userName = AppSession.displayName;
  String userEmail = AppSession.email;
  String userCity = AppSession.city;
  String userPhone = AppSession.phone;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isGuest = AppSession.isGuest;
    userName = AppSession.displayName;
    userEmail = AppSession.email;
    userCity = AppSession.city;
    userPhone = AppSession.phone;
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await loadLanguagePreference();

    if (!mounted) return;

    setState(() {
      _selectedLanguage = savedLanguage;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    _selectedLanguage = switch (currentLocale) {
      'en' => 'en',
      'fr' => 'fr',
      'de' => 'de',
      'it' => 'it',
      'es' => 'es',
      'nl' => 'nl',
      'sv' => 'sv',
      'da' => 'da',
      'no' => 'no',
      _ => 'en',
    };
  }

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

  void _showEditProfileDialog() {
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
        title: Text('profile.edit_profile'.tr(),
            style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  await _pickProfileImage();
                  if (!mounted || !dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showEditProfileDialog();
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
              _buildDialogField('profile.full_name'.tr(), nameController),
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

                if (!mounted || !dialogContext.mounted) return;

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
                      onTap: () => _showEditProfileDialog(),
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
                    ? 'language_ui.guest_help'.tr()
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
            Container(
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, color: primaryGold),
                    title: Text('profile.edit_profile'.tr(),
                        style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        color: Colors.white54, size: 16),
                    onTap: () => _showEditProfileDialog(),
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  ListTile(
                    leading: Icon(Icons.settings_outlined, color: primaryGold),
                    title: Text('profile_settings'.tr(),
                        style: const TextStyle(color: Colors.white)),
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
                      title: Text('profile.request_admin_verification'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'profile.request_admin_verification_subtitle'.tr(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
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
                      title: Text('profile.pro_vip_subscriptions'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                          'profile.pro_vip_subscriptions_subtitle'.tr(),
                          style:
                              const TextStyle(color: Colors.white38, fontSize: 11)),
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
                      title: Text('profile.my_tickets'.tr(),
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('profile.my_tickets_subtitle'.tr(),
                          style:
                              const TextStyle(color: Colors.white38, fontSize: 11)),
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
                      title: Text('profile.my_saved_listings'.tr(),
                          style: const TextStyle(color: Colors.white)),
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
                  const LocalCampaignPreferencesCard(),
                  SwitchListTile(
                    secondary:
                        Icon(Icons.notifications_outlined, color: primaryGold),
                    title: Text(
                      'settings.push_notifications'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'settings.notifications_subtitle'.tr(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    activeThumbColor: primaryGold,
                    value: _pushNotificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _pushNotificationsEnabled = value;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(value
                                ? 'settings.notifications_enabled'.tr()
                                : 'settings.notifications_disabled'.tr())),
                      );
                    },
                  ),
                  const Divider(color: Colors.white24, height: 1),
                  if (!_isGuest) ...[
                    SwitchListTile(
                      secondary: Icon(Icons.phone_android, color: primaryGold),
                      title: Text(
                        'settings.phone_privacy'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _phonePublic
                            ? 'settings.phone_public'.tr()
                            : 'settings.phone_private'.tr(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
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
                    title: Text(
                      'settings.language'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'settings.current_language'.tr(
                        args: [languageLabel(context, _selectedLanguage)],
                      ),
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: DropdownButton<String>(
                      value: _selectedLanguage,
                      dropdownColor: cardGreen,
                      underline: const SizedBox.shrink(),
                      iconEnabledColor: primaryGold,
                      style: const TextStyle(color: Colors.white),
                      items: [
                        DropdownMenuItem(
                          value: 'system',
                          child: Text('languages.system'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('languages.english'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'fr',
                          child: Text('languages.french'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'de',
                          child: Text('languages.german'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'it',
                          child: Text('languages.italian'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'es',
                          child: Text('languages.spanish'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'nl',
                          child: Text('languages.dutch'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'sv',
                          child: Text('languages.swedish'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'da',
                          child: Text('languages.danish'.tr()),
                        ),
                        DropdownMenuItem(
                          value: 'no',
                          child: Text('languages.norwegian'.tr()),
                        ),
                      ],
                      onChanged: (String? value) async {
                        if (value == null) return;

                        switch (value) {
                          case 'system':
                            await context.resetLocale();
                            break;
                          case 'en':
                            await context.setLocale(const Locale('en'));
                            break;
                          case 'fr':
                            await context.setLocale(const Locale('fr'));
                            break;
                          case 'de':
                            await context.setLocale(const Locale('de'));
                            break;
                          case 'it':
                            await context.setLocale(const Locale('it'));
                            break;
                          case 'es':
                            await context.setLocale(const Locale('es'));
                            break;
                          case 'nl':
                            await context.setLocale(const Locale('nl'));
                            break;
                          case 'sv':
                            await context.setLocale(const Locale('sv'));
                            break;
                          case 'da':
                            await context.setLocale(const Locale('da'));
                            break;
                          case 'no':
                            await context.setLocale(const Locale('no'));
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
                      title: Text(
                        'settings.privacy_gdpr'.tr(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Colors.white54, size: 16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            backgroundColor: cardGreen,
                            title: Text('settings.privacy_data_title'.tr(),
                                style: TextStyle(
                                    color: primaryGold,
                                    fontWeight: FontWeight.bold)),
                            content: SingleChildScrollView(
                              child: Text(
                                'settings.privacy_gdpr_text'.tr(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text('got_it'.tr(),
                                    style: TextStyle(color: primaryGold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(color: Colors.white24, height: 1),
                  ],
                  ListTile(
                    leading: Icon(_isGuest ? Icons.login : Icons.logout,
                        color: Colors.orangeAccent),
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
                          title: Text('profile.log_out'.tr(),
                              style: const TextStyle(
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.bold)),
                          content: Text(
                            'profile.log_out_confirmation'.tr(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('profile.cancel'.tr(),
                                  style: TextStyle(color: primaryGold)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orangeAccent),
                              onPressed: () async {
                                await NotificationService.instance
                                    .unregisterLocalCampaignDevice();
                                await FirebaseAuth.instance.signOut();
                                AppSession.signOut();

                                if (!profileContext.mounted) return;

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                Navigator.of(profileContext)
                                    .pushNamedAndRemoveUntil(
                                        '/login', (route) => false);
                              },
                              child: Text('profile.log_out'.tr(),
                                  style: const TextStyle(
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
                      title: Text('profile.delete_my_account'.tr(),
                          style: const TextStyle(color: Colors.redAccent)),
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

class SavedListingsScreen extends StatelessWidget {
  const SavedListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);

    const List<Map<String, String>> savedItems = [
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
  String _selectedLanguage = 'system';

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale.languageCode;
    _selectedLanguage = switch (currentLocale) {
      'en' => 'en',
      'fr' => 'fr',
      'de' => 'de',
      'it' => 'it',
      'es' => 'es',
      'nl' => 'nl',
      'sv' => 'sv',
      'da' => 'da',
      'no' => 'no',
      _ => 'en',
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
        title: Text(
          'profile.title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        children: [
          const LocalCampaignPreferencesCard(),
          SwitchListTile(
            secondary: Icon(
              Icons.notifications_outlined,
              color: primaryGold,
            ),
            title: Text(
              'profile.push_notifications'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'profile.notifications_subtitle'.tr(),
              style: const TextStyle(color: Colors.white54),
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
            title: Text(
              'settings.phone_privacy'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              _phonePublic
                  ? 'settings.phone_public'.tr()
                  : 'settings.phone_private'.tr(),
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
            title: Text(
              'settings.language'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'settings.current_language'.tr(args: [_selectedLanguage]),
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              dropdownColor: cardGreen,
              underline: const SizedBox.shrink(),
              iconEnabledColor: primaryGold,
              style: const TextStyle(color: Colors.white),
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text('languages.system'.tr()),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text('languages.english'.tr()),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text('languages.french'.tr()),
                ),
                DropdownMenuItem(
                  value: 'de',
                  child: Text('languages.german'.tr()),
                ),
                DropdownMenuItem(
                  value: 'it',
                  child: Text('languages.italian'.tr()),
                ),
                DropdownMenuItem(
                  value: 'es',
                  child: Text('languages.spanish'.tr()),
                ),
                DropdownMenuItem(
                  value: 'nl',
                  child: Text('languages.dutch'.tr()),
                ),
                DropdownMenuItem(
                  value: 'sv',
                  child: Text('languages.swedish'.tr()),
                ),
                DropdownMenuItem(
                  value: 'da',
                  child: Text('languages.danish'.tr()),
                ),
                DropdownMenuItem(
                  value: 'no',
                  child: Text('languages.norwegian'.tr()),
                ),
              ],
              onChanged: (String? value) async {
                if (value == null) return;

                switch (value) {
                  case 'system':
                    await context.resetLocale();
                    break;
                  case 'en':
                    await context.setLocale(const Locale('en'));
                    break;
                  case 'fr':
                    await context.setLocale(const Locale('fr'));
                    break;
                  case 'de':
                    await context.setLocale(const Locale('de'));
                    break;
                  case 'it':
                    await context.setLocale(const Locale('it'));
                    break;
                  case 'es':
                    await context.setLocale(const Locale('es'));
                    break;
                  case 'nl':
                    await context.setLocale(const Locale('nl'));
                    break;
                  case 'sv':
                    await context.setLocale(const Locale('sv'));
                    break;
                  case 'da':
                    await context.setLocale(const Locale('da'));
                    break;
                  case 'no':
                    await context.setLocale(const Locale('no'));
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
            title: Text(
              'settings.privacy_security'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'settings.privacy_subtitle'.tr(),
              style: const TextStyle(color: Colors.white54),
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
            title: Text(
              'settings.delete_account'.tr(),
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'settings.delete_account_subtitle'.tr(),
              style: const TextStyle(color: Colors.white54),
            ),
            onTap: _showDeleteAccountDialog,
          ),
        ],
      ),
    );
  }
}
