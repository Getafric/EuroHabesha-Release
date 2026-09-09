import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';

class PublicFeedSection extends StatelessWidget {
  const PublicFeedSection({super.key});

  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('publicFeed')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 64, child: Center(child: CircularProgressIndicator(color: primaryGold)));
        }

        final docs = (snapshot.data?.docs ?? []).where((doc) => doc.data()['status'] == 'published').toList()
          ..sort((left, right) => _priorityScore(right.data()).compareTo(_priorityScore(left.data())));
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Approved Community Feed', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) => _PublicFeedCard(doc: doc)),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }

  int _priorityScore(Map<String, dynamic> data) {
    final badge = Map<String, dynamic>.from(data['verificationBadge'] ?? {});
    final badgeTitle = badge['title']?.toString().toLowerCase() ?? '';
    final publishedAt = data['publishedAt'];
    final timestamp = publishedAt is Timestamp ? publishedAt.millisecondsSinceEpoch ~/ 100000 : 0;
    final reviewScore = ((data['rating'] as num?)?.toDouble() ?? 0) * 1000;
    final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
    final verifiedBoost = badgeTitle.isNotEmpty ? 5000000 : 0;
    final vipBoost = badgeTitle.contains('vip') ? 12000000 : 0;
    final proBoost = badgeTitle.contains('pro') ? 8000000 : 0;
    final silverBoost = badgeTitle.contains('silver') ? 6000000 : 0;
    final demoPenalty = data['isDemo'] == true ? -20000000 : 0;

    return demoPenalty + vipBoost + proBoost + silverBoost + verifiedBoost + reviewScore.round() + reviewCount + timestamp;
  }
}

class _PublicFeedCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _PublicFeedCard({required this.doc});

  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final title = data['title']?.toString() ?? 'Approved post';
    final category = data['category']?.toString().toUpperCase() ?? 'APPROVED';
    final subtitle = data['subtitle']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';
    final badgeTitle = (data['verificationBadge'] as Map?)?['title']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: primaryGold.withOpacity(0.18), borderRadius: BorderRadius.circular(20)),
                child: Text(category, style: const TextStyle(color: primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              if (badgeTitle != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: primaryGold, size: 16),
                const SizedBox(width: 4),
                Text(badgeTitle, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
              const Spacer(),
              if (AppSession.isSuperAdmin)
                IconButton(
                  tooltip: 'Delete post',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDelete(context),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35), maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardGreen,
        title: const Text('Delete feed item?', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        content: const Text('This will remove the approved post from the public feed immediately.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await doc.reference.update({'status': 'deleted', 'deletedAt': FieldValue.serverTimestamp()});
    }
  }
}
