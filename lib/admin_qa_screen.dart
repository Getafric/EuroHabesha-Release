import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminQaScreen extends StatelessWidget {
  const AdminQaScreen({super.key});

  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Stream<int> _countStream(Query<Map<String, dynamic>> query) {
    return query.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Widget _metricCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Stream<int> stream,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x2210B981),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold));
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                );
              }
              return Text(
                '${snapshot.data}',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = Timestamp.fromDate(_todayStart);
    final firestore = FirebaseFirestore.instance;

    final pendingSubmissions = _countStream(
      firestore.collection('job_submissions').where('status', isEqualTo: 'pending'),
    );

    final approvedToday = _countStream(
      firestore
          .collection('job_submissions')
          .where('status', isEqualTo: 'approved')
          .where('approvedAt', isGreaterThanOrEqualTo: today),
    );

    final rejectedToday = _countStream(
      firestore
          .collection('job_submissions')
          .where('status', isEqualTo: 'rejected')
          .where('rejectedAt', isGreaterThanOrEqualTo: today),
    );

    final notificationsToday = _countStream(
      firestore.collectionGroup('notifications').where('createdAt', isGreaterThanOrEqualTo: today),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        centerTitle: true,
        title: const Text('Admin QA Dashboard', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'Live counters for moderation and notification health. Use this after each release or rule change.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          _metricCard(
            context: context,
            title: 'Pending Submissions',
            subtitle: 'Items waiting for admin review',
            stream: pendingSubmissions,
            icon: Icons.pending_actions_outlined,
          ),
          const SizedBox(height: 10),
          _metricCard(
            context: context,
            title: 'Approved Today',
            subtitle: 'Approved in current local day',
            stream: approvedToday,
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 10),
          _metricCard(
            context: context,
            title: 'Rejected Today',
            subtitle: 'Rejected in current local day',
            stream: rejectedToday,
            icon: Icons.cancel_outlined,
          ),
          const SizedBox(height: 10),
          _metricCard(
            context: context,
            title: 'Notifications Written Today',
            subtitle: 'Writes to users/*/notifications',
            stream: notificationsToday,
            icon: Icons.notifications_active_outlined,
          ),
        ],
      ),
    );
  }
}
