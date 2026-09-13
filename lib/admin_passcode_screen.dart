import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';

class AdminPasscodeScreen extends StatefulWidget {
  const AdminPasscodeScreen({super.key});

  @override
  State<AdminPasscodeScreen> createState() => _AdminPasscodeScreenState();
}

class _AdminPasscodeScreenState extends State<AdminPasscodeScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  static const String superAdminEmail = 'getafricshow1@gmail.com';
  static const String masterPasscode = '7124';

  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  bool _isLoggingOut = false;
  bool _isVerifying = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _cancelAndLogOut() async {
    setState(() => _isLoggingOut = true);
    await FirebaseAuth.instance.signOut();
    AppSession.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _verifyPasscode() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase() ?? '';
    final enteredCode = _pinController.text.trim();

    if (enteredCode.isEmpty) {
      setState(() => _errorText = 'Please enter your verification code.');
      return;
    }

    setState(() => _isVerifying = true);

    // 1. Check if Super Admin
    if (email == superAdminEmail && enteredCode == masterPasscode) {
      AppSession.signIn(
        name: user?.displayName ?? 'Super Admin',
        emailAddress: email,
        verified: true,
        assignedRoles: const ['superAdmin'],
        superAdminValidated: true,
      );
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/app', (route) => false);
      return;
    }

    // 2. Check if Scoped Admin Invitation exists in Firestore
    try {
      final query = await FirebaseFirestore.instance
          .collection('adminInvites')
          .where('email', isEqualTo: email)
          .where('accessCode', isEqualTo: enteredCode)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final inviteData = query.docs.first.data();
        final role = inviteData['role']?.toString() ?? 'Editor';
        final scope = inviteData['scope']?.toString() ?? 'General';
        final permissions = List<String>.from(inviteData['permissions'] ?? []);

        AppSession.signIn(
          name: user?.displayName ?? email,
          emailAddress: email,
          verified: true,
          assignedRoles: [role, 'scoped:$scope', ...permissions],
          superAdminValidated: false, // Scoped admin, NOT super admin
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Welcome, $role for $scope!'),
            backgroundColor: cardGreen,
          ));
          Navigator.pushNamedAndRemoveUntil(context, '/app', (route) => false);
        }
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _errorText = 'Incorrect verification code or no active admin assignment for this email.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Admin';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: primaryDarkGreen,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryGold.withOpacity(0.45)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings, color: primaryGold, size: 58),
                    const SizedBox(height: 14),
                    const Text(
                      'Admin Access Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userEmail,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _pinController,
                      maxLength: 6,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Verification / Access Code',
                        labelStyle: const TextStyle(color: Colors.white54),
                        errorText: _errorText,
                        filled: true,
                        fillColor: primaryDarkGreen,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryGold, width: 2)),
                      ),
                      onSubmitted: (_) => _verifyPasscode(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryGold, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: _isVerifying ? null : _verifyPasscode,
                        child: _isVerifying
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF061E12), strokeWidth: 2))
                            : const Text('Verify & Enter Admin', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _isLoggingOut ? null : _cancelAndLogOut,
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        label: Text(_isLoggingOut ? 'Logging out...' : 'Cancel / Log Out', style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
