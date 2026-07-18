import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'provider_chat_thread_screen.dart';

class ProfessionalDetailScreen extends StatelessWidget {
  const ProfessionalDetailScreen({super.key, required this.professional});

  final Professional professional;

  Future<String> _resolveProviderUid() async {
    final direct = professional.userId.trim();
    if (direct.isNotEmpty) return direct;

    final email = (professional.email ?? '').trim();
    if (email.isEmpty) return '';

    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (usersSnap.docs.isEmpty) return '';
      return usersSnap.docs.first.id.trim();
    } on FirebaseException {
      // Non-admin users may not have permission to query users collection.
      return '';
    }
  }

  Future<void> _launch(BuildContext context, Uri uri, String errorMessage) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Widget _verificationChip() {
    final stage = professional.verificationStage.toLowerCase();
    Color color = const Color(0xFF10B981);
    String label = 'Verified';
    if (stage == 'vip') {
      color = const Color(0xFFF59E0B);
      label = 'VIP Verified';
    } else if (stage == 'professional') {
      color = const Color(0xFF22D3EE);
      label = 'Professional Verified';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        title: const Text('Professional Profile', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF123222),
                  backgroundImage: (professional.imageUrl ?? '').trim().isEmpty
                      ? null
                      : NetworkImage(professional.imageUrl!),
                  child: (professional.imageUrl ?? '').trim().isEmpty
                      ? const Icon(Icons.person_outline, color: Color(0xFFF59E0B))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              professional.name,
                              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (professional.isVerified || professional.verificationStage.isNotEmpty) _verificationChip(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        professional.category,
                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${professional.city}, ${professional.country}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              professional.bio,
              style: const TextStyle(color: Colors.white70, height: 1.45),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact & Connect',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Color(0xFFF59E0B)),
                  title: Text(professional.phone, style: const TextStyle(color: Colors.white)),
                  subtitle: const Text('Tap to call', style: TextStyle(color: Colors.white54)),
                  onTap: () => _launch(
                    context,
                    Uri.parse('tel:${professional.phone.trim()}'),
                    'Could not open phone dialer.',
                  ),
                ),
                if ((professional.email ?? '').trim().isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.email_outlined, color: Color(0xFFF59E0B)),
                    title: Text(professional.email!, style: const TextStyle(color: Colors.white)),
                    subtitle: const Text('Tap to send email', style: TextStyle(color: Colors.white54)),
                    onTap: () => _launch(
                      context,
                      Uri(scheme: 'mailto', path: professional.email!.trim()),
                      'Could not open email app.',
                    ),
                  ),
                if ((professional.website ?? '').trim().isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language_outlined, color: Color(0xFFF59E0B)),
                    title: Text(professional.website!, style: const TextStyle(color: Colors.white)),
                    subtitle: const Text('Tap to open website', style: TextStyle(color: Colors.white54)),
                    onTap: () {
                      final raw = professional.website!.trim();
                      final normalized = raw.startsWith('http://') || raw.startsWith('https://') ? raw : 'https://$raw';
                      _launch(context, Uri.parse(normalized), 'Could not open website.');
                    },
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: const Color(0xFF061E12),
                    ),
                    onPressed: () async {
                      final providerUid = await _resolveProviderUid();
                      if (!context.mounted) return;
                      if (providerUid.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Direct messaging is unavailable for this profile right now.')),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProviderChatThreadScreen(
                            providerUid: providerUid,
                            providerName: professional.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
