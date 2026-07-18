import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
import 'moderation_state.dart';
import 'registration_screen.dart';
import 'session_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _professionalDetailsController = TextEditingController();
  final TextEditingController _documentsController = TextEditingController();

  XFile? _profileImage;
  bool _showPhonePublicly = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    if (SessionState.isGuest) {
      _fullNameController.text = 'Guest User';
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _fullNameController.text = SessionState.displayName ?? 'User';
      _emailController.text = SessionState.verifiedContact ?? '';
      return;
    }

    final fallbackName = SessionState.displayName ?? user.displayName ?? user.email?.split('@').first ?? 'User';
    _fullNameController.text = fallbackName;
    _emailController.text = (user.email ?? SessionState.verifiedContact ?? '').trim();

    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (data == null || !mounted) return;

      final fullName = (data['fullName'] ?? '').toString().trim();
      final phone = (data['phone'] ?? '').toString();
      final email = (data['email'] ?? '').toString().trim();
      final professionalDetails = (data['professionalDetails'] ?? '').toString();
      final documents = (data['documents'] ?? '').toString();
      final showPhone = data['showPhonePublicly'] == true;

      setState(() {
        _fullNameController.text = fullName.isEmpty ? fallbackName : fullName;
        _phoneController.text = phone;
        _emailController.text = email.isEmpty ? _emailController.text : email;
        _professionalDetailsController.text = professionalDetails;
        _documentsController.text = documents;
        _showPhonePublicly = showPhone;
      });

      SessionState.displayName = _fullNameController.text.trim();
    } catch (_) {
      // Keep fallback values if profile fetch fails.
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _professionalDetailsController.dispose();
    _documentsController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (!mounted || image == null) return;

    setState(() {
      _profileImage = image;
    });
  }

  void _saveProfile() {
    if (SessionState.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create an account or log in to save your profile.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again before saving your profile.')),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim().isEmpty ? (user.email ?? '') : _emailController.text.trim();

    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName,
      'email': email,
      'phone': _phoneController.text.trim(),
      'professionalDetails': _professionalDetailsController.text.trim(),
      'documents': _documentsController.text.trim(),
      'showPhonePublicly': _showPhonePublicly,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).then((_) {
      SessionState.displayName = fullName;
      if (!mounted) return;

      ModerationState.addPendingContent(
        type: 'Profile',
        title: fullName,
        submittedBy: email.isEmpty ? 'current_user@eurohabesha.app' : email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully.')),
      );
    }).catchError((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $error')),
      );
    });
  }

  Future<void> _disconnectAccount() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore sign-out issues and still return to guest mode.
    }

    SessionState.enterGuest();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (SessionState.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Browsing as Guest',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You can explore all content without signing up. Log in only when you want to contact providers, publish content, or save your profile.',
                        style: TextStyle(color: Colors.white70, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white24),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                                );
                              },
                              child: const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                foregroundColor: const Color(0xFF061E12),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text('Log In'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFF0E2E1E),
                      backgroundImage: _profileImage != null ? FileImage(File(_profileImage!.path)) : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person_outline, size: 40, color: Colors.white70)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickProfileImage,
                      icon: const Icon(Icons.photo_camera_outlined, color: Color(0xFFF59E0B)),
                      label: const Text('Upload Optional Profile Photo', style: TextStyle(color: Color(0xFFF59E0B))),
                    ),
                    const Text(
                      'Only image files are accepted. You can skip this step.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fullNameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Full Name'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Phone Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _professionalDetailsController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Professional Details'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _documentsController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Uploaded Documents (references)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _showPhonePublicly,
                activeThumbColor: const Color(0xFFF59E0B),
                title: const Text('Show phone number publicly', style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                  'Turn off to keep your phone private and use in-app contact only.',
                  style: TextStyle(color: Colors.white60),
                ),
                onChanged: (value) {
                  setState(() {
                    _showPhonePublicly = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveProfile,
                child: const Text('Save Profile Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (!SessionState.isGuest && FirebaseAuth.instance.currentUser != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _disconnectAccount,
                  icon: const Icon(Icons.logout_outlined),
                  label: const Text('Disconnect / Log Out'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF0E2E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }
}
