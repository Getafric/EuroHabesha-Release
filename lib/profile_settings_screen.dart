import 'package:flutter/material.dart';
import 'app_session.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  // Notification States
  bool jobsNotif = true;
  bool marketNotif = true;
  bool businessNotif = true;
  bool eventsNotif = true;
  bool associationsNotif = true;
  bool messagesNotif = true;
  bool systemNotif = true;

  bool isGuest = AppSession.isGuest;
  String fullName = AppSession.displayName;
  String email = AppSession.email;
  String phoneNumber = AppSession.phone;
  String city = AppSession.city;
  bool phonePublic = false;

  // Appearance State
  bool darkMode = true;
  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    final languageCode = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    selectedLanguage = switch (languageCode) {
      'fr' => 'French',
      'nl' => 'Dutch',
      'am' => 'Amharic',
      _ => 'English',
    };
    isGuest = AppSession.isGuest;
    fullName = AppSession.displayName;
    email = AppSession.email;
    phoneNumber = AppSession.phone;
    city = AppSession.city;
  }

  void _toggleAll(bool value) {
    setState(() {
      jobsNotif = value;
      marketNotif = value;
      businessNotif = value;
      eventsNotif = value;
      associationsNotif = value;
      messagesNotif = value;
      systemNotif = value;
    });
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: fullName);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: phoneNumber);
    final cityController = TextEditingController(text: city);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: Text('Edit Profile Information', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField('Full name', nameController, Icons.person_outline),
              const SizedBox(height: 10),
              _buildTextField('Email address', emailController, Icons.email_outlined),
              const SizedBox(height: 10),
              _buildTextField('Phone number', phoneController, Icons.phone_outlined),
              const SizedBox(height: 10),
              _buildTextField('City and country', cityController, Icons.location_on_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
            onPressed: () {
              setState(() {
                fullName = nameController.text.trim();
                email = emailController.text.trim();
                phoneNumber = phoneController.text.trim();
                city = cityController.text.trim();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile information updated.')),
              );
            },
            child: Text('Save', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: Text('Privacy Policy', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        content: const SingleChildScrollView(
          child: Text(
            'Euro Habesha protects your personal data under European GDPR standards. You can edit your profile, control notification preferences, choose whether your phone number is public or private, and request account deletion from this settings page. Your phone number remains private unless you explicitly make it public.',
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: primaryGold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will request permanent deletion of your Euro Habesha account, profile information, listings, and posts. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion request saved.')),
              );
            },
            child: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryGold.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.menu, color: Color(0xFFFFD700)),
        ),
        title: const Text(
          'Profile Settings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryGold.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName, style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(isGuest ? 'Guest access. Sign in to manage saved items, privacy, and account deletion.' : email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (!isGuest)
                    Text(phonePublic ? 'Public phone: $phoneNumber' : 'Phone number is private', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
                      onPressed: isGuest ? () => Navigator.pushNamed(context, '/login') : _showEditProfileDialog,
                      icon: Icon(isGuest ? Icons.login : Icons.edit, color: primaryDarkGreen),
                      label: Text(isGuest ? 'Sign In / Register' : 'Edit Profile Information', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // ── Enable/Disable All Buttons ──
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _toggleAll(true),
                  child: const Text('Enable all', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => _toggleAll(false),
                  child: const Text('Disable all', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Notification Switches ──
            _buildSwitchItem('Jobs', jobsNotif, (val) => setState(() => jobsNotif = val)),
            _buildSwitchItem('Marketplace', marketNotif, (val) => setState(() => marketNotif = val)),
            _buildSwitchItem('Businesses', businessNotif, (val) => setState(() => businessNotif = val)),
            _buildSwitchItem('Events', eventsNotif, (val) => setState(() => eventsNotif = val)),
            _buildSwitchItem('Associations', associationsNotif, (val) => setState(() => associationsNotif = val)),
            _buildSwitchItem('Messages', messagesNotif, (val) => setState(() => messagesNotif = val)),
            _buildSwitchItem('System Notifications', systemNotif, (val) => setState(() => systemNotif = val)),
            if (!isGuest)
              _buildSwitchItem('Phone number public', phonePublic, (val) => setState(() => phonePublic = val)),
            
            const Divider(color: Colors.white24, height: 40),

            // ── Appearance & Language ──
            const Text('Appearance & Language', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            _buildSwitchItem('Dark Mode', darkMode, (val) => setState(() => darkMode = val)),
            const SizedBox(height: 15),

            // ── Language Dropdown ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Language', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLanguage,
                      dropdownColor: cardGreen,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      items: ['English', 'French', 'Dutch', 'Amharic'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedLanguage = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!isGuest) ...[
              const Text('Privacy & Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildActionItem(Icons.privacy_tip_outlined, 'Privacy Policy', 'Read data protection and phone visibility rules', _showPrivacyPolicy),
              _buildActionItem(Icons.delete_forever, 'Delete Account', 'Request permanent deletion of your account and data', _showDeleteAccountDialog, danger: true),
            ],
            const SizedBox(height: 80), // ከ Bottom Navigation ጋር እንዳይጋጭ
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryDarkGreen,
            activeTrackColor: primaryGold,
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: primaryGold),
        filled: true,
        fillColor: primaryDarkGreen,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap, {bool danger = false}) {
    final color = danger ? Colors.redAccent : primaryGold;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: danger ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 15),
        onTap: onTap,
      ),
    );
  }
}
