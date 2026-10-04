import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';

class AdminInvitationScreen extends StatefulWidget {
  const AdminInvitationScreen({
    super.key,
    required this.invitationId,
  });

  final String invitationId;

  @override
  State<AdminInvitationScreen> createState() => _AdminInvitationScreenState();
}

class _AdminInvitationScreenState extends State<AdminInvitationScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isProcessing = false;
  String? _errorMessage;

  DocumentReference<Map<String, dynamic>> get _inviteRef =>
      _firestore.collection('adminInvites').doc(widget.invitationId);

  Future<void> _respondToInvitation({
    required bool accept,
  }) async {
    if (_isProcessing) return;

    final user = FirebaseAuth.instance.currentUser;
    final currentEmail = user?.email?.trim().toLowerCase() ?? '';

    if (user == null || currentEmail.isEmpty) {
      setState(() {
        _errorMessage = 'Vous devez être connecté.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(_inviteRef);

        if (!snapshot.exists) {
          throw Exception('Cette invitation n’existe plus.');
        }

        final data = snapshot.data() ?? {};

        final invitedEmail =
            data['email']?.toString().trim().toLowerCase() ?? '';

        final invitedUserId = data['invitedUserId']?.toString().trim() ?? '';

        final status = data['status']?.toString().trim().toLowerCase() ?? '';

        if (invitedEmail != currentEmail) {
          throw Exception(
            'Cette invitation ne correspond pas à votre compte.',
          );
        }

        if (invitedUserId.isNotEmpty && invitedUserId != user.uid) {
          throw Exception(
            'Cette invitation appartient à un autre compte.',
          );
        }

        if (status != 'pending') {
          throw Exception(
            status == 'active'
                ? 'Cette invitation a déjà été acceptée.'
                : 'Cette invitation n’est plus disponible.',
          );
        }

        transaction.update(_inviteRef, {
          'status': accept ? 'active' : 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
          'respondedByUid': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Recharge immédiatement les permissions après acceptation.
      if (accept) {
        await AppSession.restoreFromFirebase();
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: accept ? cardGreen : Colors.orange.shade800,
          content: Text(
            accept
                ? 'Invitation acceptée. Votre accès administrateur est activé.'
                : 'Invitation refusée.',
          ),
        ),
      );

      Navigator.pop(context, accept);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase() ?? '';

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        foregroundColor: Colors.white,
        title: const Text('Invitation administrateur'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _inviteRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _MessageView(
              message: 'Impossible de charger cette invitation.',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            );
          }

          if (!snapshot.data!.exists) {
            return const _MessageView(
              message: 'Cette invitation n’existe plus.',
            );
          }

          final data = snapshot.data!.data() ?? {};

          final invitedEmail =
              data['email']?.toString().trim().toLowerCase() ?? '';
          final role = data['role']?.toString().trim() ?? 'Admin';
          final scope = data['scope']?.toString().trim() ?? 'General';
          final status =
              data['status']?.toString().trim().toLowerCase() ?? 'pending';

          if (currentEmail.isEmpty || invitedEmail != currentEmail) {
            return const _MessageView(
              message: 'Cette invitation ne correspond pas au compte connecté.',
            );
          }

          if (status == 'active') {
            return const _MessageView(
              icon: Icons.verified_user_outlined,
              message:
                  'Cette invitation a déjà été acceptée. Votre accès administrateur est actif.',
            );
          }

          if (status == 'rejected') {
            return const _MessageView(
              icon: Icons.cancel_outlined,
              message: 'Cette invitation a été refusée.',
            );
          }

          if (status != 'pending') {
            return const _MessageView(
              message: 'Cette invitation n’est plus disponible.',
            );
          }

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: primaryGold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: primaryGold,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Invitation administrateur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: primaryGold,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Vous avez été invité à devenir administrateur Euro Habesha.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _InfoRow(
                        label: 'E-mail',
                        value: invitedEmail,
                      ),
                      _InfoRow(
                        label: 'Rôle',
                        value: role,
                      ),
                      _InfoRow(
                        label: 'Catégorie',
                        value: scope,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _respondToInvitation(
                                    accept: true,
                                  ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGold,
                            foregroundColor: primaryDarkGreen,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryDarkGreen,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Accepter',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () => _respondToInvitation(
                                    accept: false,
                                  ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Refuser'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _AdminInvitationScreenState.primaryGold,
              size: 58,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
