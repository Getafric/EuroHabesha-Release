// EuroHabesha - Complete Flutter Login Screen
// Copy this file directly to your Flutter project's `lib/login_screen.dart` directory.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app_localization_helper.dart';
import 'navigation_shell.dart';
import 'notification_service.dart';
import 'registration_screen.dart';
import 'session_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  String _friendlyGoogleAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'This email already exists with a different sign-in method. Sign in with that method first, then link Google from account settings.';
        case 'credential-already-in-use':
          return 'This Google account is already linked to another user. Use that account directly.';
        case 'too-many-requests':
          return 'Google sign-in is temporarily rate-limited. Please wait a few minutes and try again.';
        case 'network-request-failed':
          return 'Network error while contacting Google/Firebase. Check internet and try again.';
        case 'invalid-credential':
          return 'Google returned an invalid credential. Please retry and select the account again.';
        case 'user-disabled':
          return 'This Firebase user is disabled. Contact support.';
        default:
          final message = (error.message ?? '').trim();
          if (message.toUpperCase().contains('FULL')) {
            return 'Google sign-in request is currently limited (FULL). Wait a moment and retry, or switch network and try again.';
          }
          return message.isEmpty ? error.code : message;
      }
    }

    final fallback = error.toString();
    if (fallback.toUpperCase().contains('FULL')) {
      return 'Google connection limit reached (FULL). Please retry shortly.';
    }
    return fallback;
  }

  String _displayNameFor(User user) {
    final candidate = (user.displayName ?? '').trim();
    if (candidate.isNotEmpty) return candidate;
    final local = (user.email ?? '').split('@').first.trim();
    if (local.isNotEmpty) return local;
    return 'User';
  }

  Future<void> _upsertUserProfile(User user, {required String authMethod}) async {
    final email = user.email ?? '';
    final displayName = _displayNameFor(user);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': displayName,
        'email': email,
        'country': '',
        'authMethod': authMethod,
        'emailVerified': user.emailVerified,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        debugPrint('Profile upsert permission denied for ${user.uid}. Continuing auth flow.');
        return;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return snap.data();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        debugPrint('Profile read permission denied for $uid. Using auth fallback profile.');
        return null;
      }
      rethrow;
    }
  }

  Future<void> _finishAuth(User user) async {
    final contact = (user.email ?? user.uid).trim();
    final profile = await _fetchUserProfile(user.uid);
    final fullName = (profile?['fullName'] ?? '').toString().trim();
    final displayName = fullName.isEmpty ? _displayNameFor(user) : fullName;
    SessionState.markVerified(
      contact,
      approved: true,
      uid: user.uid,
      name: displayName,
    );
    await NotificationService.ensurePermissionAndSync();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome, $displayName. Login successful.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      (route) => false,
    );
  }

  Future<void> _handleGoogleLogin() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential).timeout(const Duration(seconds: 20));
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'No user returned from Google sign-in.');
      }

      await _upsertUserProfile(user, authMethod: 'google').timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      await _finishAuth(user);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in timed out. Please try again.')),
      );
    } catch (error) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        final existingUser = FirebaseAuth.instance.currentUser;
        if (existingUser != null) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          await _finishAuth(existingUser);
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final message = _friendlyGoogleAuthError(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $message')),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetController = TextEditingController(text: _emailController.text.trim());
    final messenger = ScaffoldMessenger.of(context);

    final resetEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: const Text('Forgot Password', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: resetController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF0E2E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                final email = resetController.text.trim();
                if (email.isEmpty) return;
                Navigator.of(dialogContext).pop(email);
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );

    resetController.dispose();

    if (!mounted || resetEmail == null || resetEmail.isEmpty) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmail);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Password reset email sent to $resetEmail. Check Inbox and Spam/Junk.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Reset failed: ${error.message ?? error.code}')),
      );
    }
  }

  Future<void> _showResendVerificationDialog() async {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final passwordController = TextEditingController(text: _passwordController.text);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          title: const Text('Resend Verification', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0E2E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0E2E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                final password = passwordController.text;
                final messenger = ScaffoldMessenger.of(context);

                if (email.isEmpty || password.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Enter email and password to resend verification.')),
                  );
                  return;
                }

                try {
                  final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  final user = credential.user;
                  if (user == null) {
                    throw FirebaseAuthException(code: 'no-user', message: 'No user returned from sign-in.');
                  }

                  await user.reload();
                  final refreshedUser = FirebaseAuth.instance.currentUser;
                  final isVerified = refreshedUser?.emailVerified ?? false;

                  if (isVerified) {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('This email is already verified. You can sign in now.')),
                    );
                    return;
                  }

                  await (refreshedUser ?? user).sendEmailVerification();
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  messenger.showSnackBar(
                    SnackBar(content: Text('Verification email sent to $email. Check Inbox and Spam/Junk.')),
                  );
                } on FirebaseAuthException catch (error) {
                  if (!mounted) return;
                  final msg = switch (error.code) {
                    'user-not-found' => 'No account found for this email.',
                    'wrong-password' => 'Incorrect password for this account.',
                    'invalid-email' => 'Invalid email format.',
                    'too-many-requests' => 'Too many attempts. Please try again later.',
                    _ => error.message ?? error.code,
                  };
                  messenger.showSnackBar(SnackBar(content: Text('Could not resend verification: $msg')));
                } catch (error) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Could not resend verification: $error')),
                  );
                }
              },
              child: const Text('Resend'),
            ),
          ],
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final contactTarget = _emailController.text.trim();
    FirebaseAuth.instance
        .signInWithEmailAndPassword(
          email: contactTarget,
          password: _passwordController.text,
        )
        .then((result) async {
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'No user returned from sign-in.');
      }

      try {
        await _upsertUserProfile(user, authMethod: 'email_password');
      } catch (error) {
        debugPrint('Profile upsert skipped due to error: $error');
      }

      Map<String, dynamic>? profile;
      try {
        profile = await _fetchUserProfile(user.uid);
      } catch (error) {
        debugPrint('Profile fetch skipped due to error: $error');
      }

      final fullName = (profile?['fullName'] ?? '').toString().trim();
      final fallbackName = _displayNameFor(user);
      final displayName = fullName.isEmpty ? fallbackName : fullName;

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      SessionState.markVerified(
        contactTarget,
        approved: true,
        uid: user.uid,
        name: displayName,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welcome, $displayName. Login successful.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
        (route) => false,
      );
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      final message = error is FirebaseAuthException ? error.message ?? error.code : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $message')),
      );
    });
  }

  void _handleGuestAccess() {
    SessionState.enterGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainNavigationShell()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12), // Deep Habesha Emerald
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: AppLocalizationHelper.languageMenu(context),
                  ),
                  const SizedBox(height: 12),
                  // Brand Logo
                  Center(
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E2E1E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(245, 158, 11, 0.2),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/branding/euro_habesha_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // App Title
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          'Euro Habesha',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Euro Habesha Trust Gateway',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Header instruction
                  Text(
                    'Browse freely as a guest. Sign up or log in only when you want to contact, post, or manage content.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: tr('diaspora_email'),
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFF59E0B)),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr('please_enter_email_address');
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return tr('please_enter_valid_email');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: tr('password'),
                      labelStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFF59E0B)),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white54,
                        ),
                      ),
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
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your password.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 2,
                      children: [
                        TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFFF59E0B))),
                        ),
                        TextButton(
                          onPressed: _showResendVerificationDialog,
                          child: const Text('Resend Verification', style: TextStyle(color: Color(0xFFF59E0B))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF061E12),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061E12)),
                            ),
                          )
                        : Text(
                            'Log In',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use this button for email and password sign-in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                            );
                          },
                          child: Text(tr('create_account'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF061E12),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: Text(tr('log_in'), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleGuestAccess,
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(tr('continue_guest')),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleLogin,
                    icon: const Icon(Icons.g_mobiledata, size: 22),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Use Google button only if you want to sign in with a Google account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('guest_access_note'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

