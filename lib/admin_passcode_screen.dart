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
  static const String requiredPasscode = '7124';

  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  bool _isLoggingOut = false;

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

  void _verifyPasscode() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.trim().toLowerCase();

    if (email != superAdminEmail) {
      setState(() => _errorText = 'This security screen is only for the Super Admin account.');
      return;
    }

    if (_pinController.text.trim() != requiredPasscode) {
      setState(() => _errorText = 'Incorrect security code. Try again or cancel to log out.');
      return;
    }

    AppSession.signIn(
      name: user?.displayName ?? 'Super Admin',
      emailAddress: user?.email ?? superAdminEmail,
      verified: true,
      assignedRoles: const ['superAdmin'],
      superAdminValidated: true,
    );

    Navigator.pushNamedAndRemoveUntil(context, '/app', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? superAdminEmail;

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
                      'Super Admin Verification',
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
                      maxLength: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: '4-digit security code',
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
                        onPressed: _verifyPasscode,
                        child: const Text('Verify & Continue', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
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
