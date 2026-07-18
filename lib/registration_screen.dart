import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'navigation_shell.dart';
import 'notification_service.dart';
import 'session_state.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;
  Timer? _submitWatchdog;
  String _submitStage = '';
  String _selectedCountry = 'Germany';

  final Map<String, String> _countryDialCodes = {
    'Germany': '+49',
    'France': '+33',
    'United Kingdom': '+44',
    'United States': '+1',
    'Canada': '+1',
    'Italy': '+39',
    'Spain': '+34',
    'Netherlands': '+31',
    'Belgium': '+32',
    'Austria': '+43',
    'Switzerland': '+41',
  };

  void _handleCountryChange(String? value) {
    if (value == null) return;
    setState(() {
      _selectedCountry = value;
    });
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use. Try logging in instead.';
      case 'invalid-email':
        return 'Invalid email format. Please check your email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/Password sign-up is disabled in Firebase. Enable it in Firebase Auth > Sign-in method.';
      case 'network-request-failed':
        return 'Network error. Please check internet and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? e.code;
    }
  }

  Future<void> _submitRegistration() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase is not initialized. Restart the app and try again.'),
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitStage = 'Connecting to authentication service...';
    });
    debugPrint('[SIGNUP] started for email=${_emailController.text.trim()}');

    _submitWatchdog?.cancel();
    _submitWatchdog = Timer(const Duration(seconds: 35), () {
      if (!mounted || !_isSubmitting) return;
      debugPrint('[SIGNUP] watchdog timeout reached');
      setState(() {
        _isSubmitting = false;
        _submitStage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request is taking too long. Please check connection/Firebase and try again.'),
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
    });

    final email = _emailController.text.trim();
    var verificationEmailSent = false;
    try {
      debugPrint('[SIGNUP] createUserWithEmailAndPassword request');
      final result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          )
          .timeout(const Duration(seconds: 20));

      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'No user returned after sign-up.');
      }
      debugPrint('[SIGNUP] auth created uid=${user.uid}');

      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification().timeout(const Duration(seconds: 12));
          verificationEmailSent = true;
          debugPrint('[SIGNUP] verification email sent');
        } catch (verifyError) {
          debugPrint('[SIGNUP] verification email failed: $verifyError');
        }
      }

      if (mounted) {
        setState(() {
          _submitStage = 'Creating your profile...';
        });
      }

      // Do not block account creation flow on profile-write latency.
      try {
        debugPrint('[SIGNUP] firestore profile upsert');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'fullName': _nameController.text.trim(),
              'email': email,
              'country': _selectedCountry,
              'role': 'user',
              'status': 'active',
              'authMethod': 'email_password',
              'emailVerified': user.emailVerified,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 12));
        debugPrint('[SIGNUP] firestore profile upsert success');
      } catch (profileError) {
        debugPrint('Profile write failed after sign-up: $profileError');
      }

      final fullName = _nameController.text.trim();
      SessionState.markVerified(
        email,
        approved: true,
        uid: user.uid,
        name: fullName.isEmpty ? email.split('@').first : fullName,
      );
      await NotificationService.ensurePermissionAndSync();
      debugPrint('[SIGNUP] session verified, navigating');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verificationEmailSent
                ? 'Account created. We sent a verification email to $email. Check Inbox and Spam/Junk.'
                : 'Account created successfully. Welcome, ${fullName.isEmpty ? 'User' : fullName}.',
          ),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[SIGNUP] FirebaseAuthException code=${e.code} message=${e.message}');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-up failed: ${_friendlyAuthError(e)}'),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    } on TimeoutException {
      debugPrint('[SIGNUP] TimeoutException from signup flow');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign-up timed out. Check internet/Firebase setup and try again.'),
          backgroundColor: Color(0xFF7F1D1D),
        ),
      );
    } catch (e) {
      debugPrint('[SIGNUP] Unknown exception: $e');
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitStage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-up failed: $e'),
          backgroundColor: const Color(0xFF7F1D1D),
        ),
      );
    } finally {
      _submitWatchdog?.cancel();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitStage = '';
        });
      }
      debugPrint('[SIGNUP] flow finished');
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF0E2E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFF59E0B)),
      ),
    );
  }

  @override
  void dispose() {
    _submitWatchdog?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF061E12),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E2E1E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(245, 158, 11, 0.2),
                        blurRadius: 18,
                        offset: Offset(0, 4),
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
              const SizedBox(height: 20),
              const Text(
                'Create a simple email account. Guests can browse first and sign up only when they want to interact.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Email Address'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email address.';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCountry,
                decoration: _inputDecoration('Country'),
                dropdownColor: const Color(0xFF0E2E1E),
                items: _countryDialCodes.keys.map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
                onChanged: _handleCountryChange,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Password').copyWith(
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
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submitRegistration,
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061E12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _submitStage.isEmpty ? 'Creating account...' : _submitStage,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Already have an account? Log In', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
