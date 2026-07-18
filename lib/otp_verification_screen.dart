import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_shell.dart';
import 'session_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String contactTarget;
  final bool isPhone;
  final bool requiresAdminApproval;
  final String? verificationId;
  final Map<String, dynamic>? pendingProfileData;

  const OtpVerificationScreen({
    super.key,
    required this.contactTarget,
    required this.isPhone,
    this.requiresAdminApproval = false,
    this.verificationId,
    this.pendingProfileData,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyOtp() async {
    if (_codeController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('please_enter_otp_code'))),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      if (widget.verificationId != null && widget.verificationId!.isNotEmpty) {
        final credential = PhoneAuthProvider.credential(
          verificationId: widget.verificationId!,
          smsCode: _codeController.text.trim(),
        );
        final result = await FirebaseAuth.instance.signInWithCredential(credential);
        final user = result.user;

        if (user != null && widget.pendingProfileData != null) {
          final profileData = Map<String, dynamic>.from(widget.pendingProfileData!);
          profileData['uid'] = user.uid;
          profileData['updatedAt'] = FieldValue.serverTimestamp();
          profileData['createdAt'] = FieldValue.serverTimestamp();

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set(profileData, SetOptions(merge: true));
          await FirebaseFirestore.instance.collection('approvals').doc(user.uid).set({
            'uid': user.uid,
            'type': 'registration',
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }

      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });

      if (widget.requiresAdminApproval) {
        SessionState.markPendingApproval(widget.contactTarget);
      } else {
        SessionState.markVerified(widget.contactTarget, approved: true);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.requiresAdminApproval
                ? tr('otp_verified_pending_approval')
                : tr('otp_verified_success'),
          ),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verification failed: ${e.message ?? e.code}')),
      );
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('otp_verification')),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF061E12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${tr('enter_verification_code_sent_to')} ${widget.contactTarget}.',
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0E2E1E),
                  hintText: tr('otp_hint'),
                  hintStyle: const TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('otp_resend_help'),
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isVerifying ? null : _verifyOtp,
                child: _isVerifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF061E12)),
                        ),
                      )
                    : Text(tr('verify_otp'), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
