import 'package:flutter/material.dart';
import 'dynamic_submission_screen.dart';

class SubmissionMenuScreen extends StatelessWidget {
  const SubmissionMenuScreen({super.key});

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    final options = [
      _SubmissionOption('Register a Business', 'Business profile, phone, address, reservation-ready setup', Icons.storefront, SubmissionType.business),
      _SubmissionOption('Submit an Event', 'Tickets, performers, end time, age rules, and amenities', Icons.event, SubmissionType.event),
      _SubmissionOption('Register a Community', 'Church, mosque, association, gathering schedule, and contacts', Icons.groups, SubmissionType.community),
      _SubmissionOption('Submit a Job', 'Job/service listing with WhatsApp or in-app contact options', Icons.work, SubmissionType.job),
      _SubmissionOption('Request Verification', 'Professional, business, or community verification review', Icons.verified_user, SubmissionType.verification),
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Submission & Registration', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final option = options[index];
          return Card(
            color: cardGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: primaryGold,
                child: Icon(option.icon, color: primaryDarkGreen),
              ),
              title: Text(option.title, style: const TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(option.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DynamicSubmissionScreen(type: option.type)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SubmissionOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final SubmissionType type;

  const _SubmissionOption(this.title, this.subtitle, this.icon, this.type);
}
