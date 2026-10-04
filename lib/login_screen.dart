import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app_session.dart';
import 'notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _googleWebClientId =
      '218564066910-ufqipbmm208mrm6sirk54d0ft8d9rabi.apps.googleusercontent.com';

  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  bool _isObscure = true;
  bool _isLoading = false;
  bool _verificationSent = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _enterApp() {
    Navigator.pushReplacementNamed(context, '/app');
  }

  Future<void> _routeAfterVerifiedAuth(
    User user, {
    String? fallbackName,
    String? fallbackEmail,
  }) async {
    final email = (user.email ?? fallbackEmail ?? '').trim().toLowerCase();

    await NotificationService.instance.registerCurrentToken();

    if (!mounted) {
      return;
    }

    if (email == 'getafricshow1@gmail.com') {
      Navigator.pushReplacementNamed(context, '/admin-passcode');
      return;
    }

    AppSession.signIn(
      name: user.displayName ??
          fallbackName ??
          user.email ??
          'Euro Habesha Member',
      emailAddress: user.email ?? fallbackEmail ?? '',
      verified: true,
    );

    _enterApp();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateEmailForm() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().length < 6) {
      _showMessage(
          'Enter a valid email and a password with at least 6 characters.');
      return false;
    }
    return true;
  }

  Future<void> _signInWithEmail() async {
    if (!_validateEmailForm()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        await refreshedUser?.sendEmailVerification();
        AppSession.signIn(
            name: refreshedUser?.displayName ?? 'Unverified member',
            emailAddress: _emailController.text.trim(),
            verified: false);
        if (mounted) {
          setState(() => _verificationSent = true);
          _showMessage(
              'Please verify your email. We sent a new verification link.');
        }
        return;
      }

      if (mounted) {
        _routeAfterVerifiedAuth(refreshedUser,
            fallbackEmail: _emailController.text.trim());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(e.message ?? 'Email sign-in failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerWithEmail() async {
    if (!_validateEmailForm()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = credential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await credential.user?.sendEmailVerification();
      AppSession.signIn(
          name: 'Unverified member',
          emailAddress: _emailController.text.trim(),
          verified: false);
      if (mounted) {
        setState(() => _verificationSent = true);
        _showMessage(
            'Verification link sent. Check your email before full access.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(e.message ?? 'Account registration failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkEmailVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        if (mounted) {
          _routeAfterVerifiedAuth(user,
              fallbackEmail: _emailController.text.trim());
        }
      } else if (mounted) {
        _showMessage('Email is not verified yet. Please click the link first.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    AppSession.continueAsGuest();
    _enterApp();
  }

  Future<void> _continueWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(serverClientId: _googleWebClientId);
      await googleSignIn.signOut();
      final account = await googleSignIn.signIn();
      if (!mounted || account == null) {
        return;
      }

      final googleAuth = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (!mounted || user == null) {
        return;
      }
      await _routeAfterVerifiedAuth(
        user,
        fallbackName: account.displayName,
        fallbackEmail: account.email,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in needs configuration: $e')),
      );
    }
  }

  Future<void> _continueWithOAuthProvider(
      String providerId, String providerName) async {
    setState(() => _isLoading = true);
    try {
      final provider = OAuthProvider(providerId);
      final credential =
          await FirebaseAuth.instance.signInWithProvider(provider);
      final user = credential.user;
      if (mounted && user != null) {
        _routeAfterVerifiedAuth(user,
            fallbackName: providerName,
            fallbackEmail: user.email ?? '$providerId@eurohabesha.local');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showMessage(
            '$providerName sign-in needs Firebase provider setup: ${e.message ?? e.code}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('$providerName sign-in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Euro Habesha Trust Gateway',
          style: TextStyle(
              color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              32,
        ),
        child: Column(
          children: [
            const Text(
              'Browse freely as a guest. Sign up or log in\nonly when you want to contact, post, or\nmanage content.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 30),

            // ── Email Input ──
            _buildTextField(
              label: 'E-mail diaspora',
              icon: Icons.email_outlined,
              controller: _emailController,
            ),
            const SizedBox(height: 20),

            // ── Password Input ──
            _buildTextField(
              label: 'Mot de passe',
              icon: Icons.lock_outline,
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 15),

            // ── Forgot Password & Resend ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text('Forgot Password?',
                      style: TextStyle(color: primaryGold)),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Resend Verification',
                      style: TextStyle(color: primaryGold)),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // ── Log In Button ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _signInWithEmail,
                child: Text(_isLoading ? 'Please wait...' : 'Log In',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Use this button for email and password sign-in.',
                style: TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 20),

            // ── Create Account & Connect (French) ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cardGreen,
                      side:
                          BorderSide(color: primaryGold.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _registerWithEmail,
                    child: const Text('Créer un compte',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isLoading ? null : _signInWithEmail,
                    child: const Text('Se connecter',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // ── Guest Button ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryGold.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.remove_red_eye_outlined,
                    color: Colors.white),
                label: const Text('Continuer en tant qu\'invité',
                    style: TextStyle(color: Colors.white)),
                onPressed: _continueAsGuest,
              ),
            ),
            if (_verificationSent) ...[
              const SizedBox(height: 15),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardGreen,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryGold),
                ),
                child: Column(
                  children: [
                    Text('Email verification required',
                        style: TextStyle(
                            color: primaryGold, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                        'Open your email and click the verification link before full access is enabled.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _checkEmailVerification,
                      child: const Text('I verified my email'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 15),

            const Center(
              child: Text(
                'Or continue with',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProviderIcon(
                    Icons.g_mobiledata, 'Google', _continueWithGoogle),
                _buildProviderIcon(Icons.apple, 'Apple',
                    () => _continueWithOAuthProvider('apple.com', 'Apple')),
                _buildProviderIcon(
                    Icons.facebook,
                    'Facebook',
                    () =>
                        _continueWithOAuthProvider('facebook.com', 'Facebook')),
                _buildProviderIcon(Icons.music_note, 'TikTok',
                    () => _continueWithOAuthProvider('oidc.tiktok', 'TikTok')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required IconData icon,
      required TextEditingController controller,
      bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _isObscure : false,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: primaryGold),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
      ),
    );
  }

  Widget _buildProviderIcon(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _isLoading ? null : onPressed,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: primaryGold, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.black, size: 30),
        ),
      ),
    );
  }
}
