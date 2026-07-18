import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'access_control.dart';
import 'provider_chat_thread_screen.dart';

class ServiceProfileDetailScreen extends StatefulWidget {
  const ServiceProfileDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.description,
    required this.providerName,
    required this.city,
    required this.phone,
    required this.email,
    required this.website,
    required this.userId,
    this.imageUrl = '',
    this.postId = '',
    this.postType = 'listing',
  });

  final String title;
  final String category;
  final String description;
  final String providerName;
  final String city;
  final String phone;
  final String email;
  final String website;
  final String userId;
  final String imageUrl;
  final String postId;
  final String postType;


  @override
  State<ServiceProfileDetailScreen> createState() => _ServiceProfileDetailScreenState();
}

class _ServiceProfileDetailScreenState extends State<ServiceProfileDetailScreen> {
  late Future<_ResolvedServiceProfile> _resolvedFuture;

  Future<String> _resolveProviderUid(_ResolvedServiceProfile profile) async {
    String firstNonEmpty(List<String> values) {
      for (final value in values) {
        final text = value.trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    final direct = firstNonEmpty([
      profile.userId,
      widget.userId,
    ]);
    if (direct.isNotEmpty) return direct;

    final email = profile.email.trim();
    if (email.isNotEmpty) {
      try {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (usersSnap.docs.isNotEmpty) {
          return usersSnap.docs.first.id.trim();
        }
      } on FirebaseException {
        // Non-admin users may not have permission to query users collection.
      }
    }

    return '';
  }

  @override
  void initState() {
    super.initState();
    _resolvedFuture = _resolveProfile();
  }

  String _reviewTargetId(_ResolvedServiceProfile profile) {
    if (widget.postId.trim().isNotEmpty) {
      return '${widget.postType.trim()}:${widget.postId.trim()}';
    }
    if (profile.userId.trim().isNotEmpty) {
      return 'user:${profile.userId.trim()}';
    }
    final base = '${profile.title}|${profile.providerName}|${profile.category}'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return base.isEmpty ? 'unknown_provider' : base;
  }

  String _reviewTargetKey(String targetId) => 'provider:$targetId';

  Future<void> _launch(BuildContext context, Uri uri, String errorMessage) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  Future<_ResolvedServiceProfile> _resolveProfile() async {
    var resolved = _ResolvedServiceProfile(
      title: widget.title,
      category: widget.category,
      description: widget.description,
      providerName: widget.providerName,
      city: widget.city,
      phone: widget.phone,
      email: widget.email,
      website: widget.website,
      userId: widget.userId,
      imageUrl: widget.imageUrl,
    );

    bool missingCore() {
      return resolved.phone.trim().isEmpty
          || resolved.email.trim().isEmpty
          || resolved.userId.trim().isEmpty
          || resolved.description.trim().isEmpty;
    }

    Future<_ResolvedServiceProfile?> fromDocument(String collection, String id) async {
      if (id.trim().isEmpty) return null;
      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await FirebaseFirestore.instance.collection(collection).doc(id).get();
      } on FirebaseException {
        return null;
      }
      if (!doc.exists) return null;
      final data = doc.data() ?? const <String, dynamic>{};
      var merged = _mergeFromData(resolved, data);

      // Legacy listing announcements can reference the real source document.
      // Resolve that source to recover missing user/contact metadata.
      final sourceCollection = (data['sourceCollection'] ?? '').toString().trim();
      final sourceId = (data['sourceId'] ?? '').toString().trim();
      if ((merged.userId.trim().isEmpty || merged.phone.trim().isEmpty || merged.email.trim().isEmpty)
          && sourceCollection.isNotEmpty
          && sourceId.isNotEmpty
          && (sourceCollection != collection || sourceId != id.trim())) {
        try {
          final sourceDoc = await FirebaseFirestore.instance.collection(sourceCollection).doc(sourceId).get();
          if (sourceDoc.exists) {
            merged = _mergeFromData(merged, sourceDoc.data() ?? const <String, dynamic>{});
          }
        } on FirebaseException {
          // Ignore non-readable source collections (for example submission-only docs).
        }
      }

      return merged;
    }

    Future<_ResolvedServiceProfile?> searchByTitle(String collection) async {
      final title = widget.title.trim();
      if (title.isEmpty) return null;
      final snap = await FirebaseFirestore.instance
          .collection(collection)
          .where('title', isEqualTo: title)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return _mergeFromData(resolved, snap.docs.first.data());
    }

    if (widget.postId.trim().isNotEmpty) {
      final bySource = await fromDocument(widget.postType.trim(), widget.postId.trim());
      if (bySource != null) resolved = bySource;
    }

    if (missingCore()) {
      final probes = <Future<_ResolvedServiceProfile?>>[
        searchByTitle('jobs'),
        searchByTitle('market_items'),
        searchByTitle('business_profiles'),
        searchByTitle('verified_professionals'),
        searchByTitle('announcements'),
      ];
      for (final probe in probes) {
        final candidate = await probe;
        if (candidate == null) continue;
        resolved = candidate;
        if (!missingCore()) break;
      }
    }

    return resolved;
  }

  _ResolvedServiceProfile _mergeFromData(_ResolvedServiceProfile base, Map<String, dynamic> data) {
    String first(List<dynamic> values) {
      for (final value in values) {
        final text = value == null ? '' : value.toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return _ResolvedServiceProfile(
      title: first([data['title'], base.title]),
      category: first([data['category'], base.category]),
      description: first([data['description'], data['body'], base.description]),
      providerName: first([data['providerName'], data['authorName'], data['ownerName'], data['name'], base.providerName]),
      city: first([
        [data['city'], data['country']].where((e) => (e ?? '').toString().trim().isNotEmpty).join(', '),
        data['city'],
        base.city,
      ]),
      phone: first([data['phone'], data['authorPhone'], base.phone]),
      email: first([data['email'], data['businessEmail'], data['contactEmail'], base.email]),
      website: first([data['website'], data['webSite'], data['businessWebsite'], base.website]),
      userId: first([
        data['userId'],
        data['providerUid'],
        data['ownerUid'],
        data['authorUid'],
        data['uid'],
        data['ownerId'],
        data['submittedByUid'],
        base.userId,
      ]),
      imageUrl: first([data['imageUrl'], data['photoUrl'], (data['photoUrls'] is List && (data['photoUrls'] as List).isNotEmpty) ? data['photoUrls'][0] : '', base.imageUrl]),
    );
  }

  Future<void> _submitReview({
    required String targetId,
    required double rating,
    required String comment,
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      throw Exception('You must be signed in to submit a review.');
    }

    final targetKey = _reviewTargetKey(targetId);
    final reviewsRef = FirebaseFirestore.instance.collection('Reviews');
    final summariesRef = FirebaseFirestore.instance.collection('ReviewSummaries');
    final reviewDoc = reviewsRef.doc();
    final summaryDoc = summariesRef.doc(targetKey);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final summarySnap = await tx.get(summaryDoc);
      final data = summarySnap.data();
      final oldCount = (data?['reviewCount'] ?? 0) is num ? (data?['reviewCount'] ?? 0) as num : 0;
      final oldTotal = (data?['ratingTotal'] ?? 0) is num ? (data?['ratingTotal'] ?? 0) as num : 0;

      final newCount = oldCount.toInt() + 1;
      final newTotal = oldTotal.toDouble() + rating;
      final newAverage = newTotal / newCount;

      tx.set(reviewDoc, {
        'targetType': 'provider',
        'targetId': targetId,
        'targetKey': targetKey,
        'reviewerUid': authUser.uid,
        'reviewerName': (authUser.displayName ?? authUser.email ?? 'Member').trim(),
        'reviewerContact': (authUser.email ?? '').trim(),
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(summaryDoc, {
        'targetType': 'provider',
        'targetId': targetId,
        'targetKey': targetKey,
        'reviewCount': newCount,
        'ratingTotal': newTotal,
        'averageRating': newAverage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _openReviewDialog({
    required String targetId,
    required String subjectLabel,
  }) async {
    if (!AccessControl.ensureVerified(context, actionLabel: 'Review Service')) {
      return;
    }

    double selectedRating = 5;
    final commentController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF061E12),
              title: const Text('Leave a Review', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;
                      return IconButton(
                        onPressed: () => setDialogState(() => selectedRating = value.toDouble()),
                        icon: Icon(
                          selectedRating >= value ? Icons.star : Icons.star_border,
                          color: const Color(0xFFF59E0B),
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      labelStyle: TextStyle(color: Colors.white70),
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
                    final trimmed = commentController.text.trim();
                    if (trimmed.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Please add a comment before submitting.')),
                      );
                      return;
                    }

                    try {
                      await _submitReview(targetId: targetId, rating: selectedRating, comment: trimmed);
                      if (!mounted) return;
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Thanks. Your review for $subjectLabel was submitted.')),
                      );
                    } catch (error) {
                      if (!dialogContext.mounted) return;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Could not submit review: $error')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ResolvedServiceProfile>(
      future: _resolvedFuture,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? _ResolvedServiceProfile(
          title: widget.title,
          category: widget.category,
          description: widget.description,
          providerName: widget.providerName,
          city: widget.city,
          phone: widget.phone,
          email: widget.email,
          website: widget.website,
          userId: widget.userId,
          imageUrl: widget.imageUrl,
        );
        final normalizedWebsite = profile.website.trim().isEmpty
            ? ''
            : (profile.website.startsWith('http://') || profile.website.startsWith('https://')
                ? profile.website
                : 'https://${profile.website}');
        final targetId = _reviewTargetId(profile);
        final targetKey = _reviewTargetKey(targetId);

        return Scaffold(
          backgroundColor: const Color(0xFF061E12),
          appBar: AppBar(
            title: const Text('Service Profile'),
            backgroundColor: const Color(0xFF0E2E1E),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF123222), Color(0xFF0A2418), Color(0xFF1F3F2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF0E2E1E),
                      backgroundImage: profile.imageUrl.trim().isEmpty ? null : NetworkImage(profile.imageUrl),
                      child: profile.imageUrl.trim().isEmpty
                          ? const Icon(Icons.person_outline, color: Color(0xFFF59E0B))
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.providerName.trim().isEmpty ? profile.title : profile.providerName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.title,
                            style: const TextStyle(color: Color(0xFFE8D79B), fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  profile.category,
                                  style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (profile.city.trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A2D),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    profile.city,
                                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('ReviewSummaries').doc(targetKey).snapshots(),
                builder: (context, summarySnapshot) {
                  final summary = summarySnapshot.data?.data() ?? const <String, dynamic>{};
                  final average = (summary['averageRating'] is num) ? (summary['averageRating'] as num).toDouble() : 0.0;
                  final count = (summary['reviewCount'] is num) ? (summary['reviewCount'] as num).toInt() : 0;
                  final reputationScore = (average * 20).clamp(0, 100).toDouble();

                  return Container(
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
                          'Public Reputation',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            Text(
                              'Reputation Score: ${reputationScore.toStringAsFixed(0)}/100',
                              style: const TextStyle(color: Color(0xFFE8D79B), fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${average.toStringAsFixed(1)} • $count reviews',
                              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _openReviewDialog(targetId: targetId, subjectLabel: profile.providerName),
                              icon: const Icon(Icons.rate_review_outlined, size: 16),
                              label: const Text('Leave Review'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
                      'Service Description',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.description.trim().isEmpty
                          ? 'No detailed service description provided yet.'
                          : profile.description,
                      style: const TextStyle(color: Colors.white70, height: 1.45),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Methods',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: const Color(0xFF061E12),
                          ),
                          onPressed: profile.phone.trim().isEmpty
                              ? null
                              : () => _launch(context, Uri.parse('tel:${profile.phone.trim()}'), 'Could not open dialer.'),
                          icon: const Icon(Icons.phone_outlined),
                          label: const Text('Call'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A2D),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: profile.email.trim().isEmpty
                              ? null
                              : () => _launch(context, Uri(scheme: 'mailto', path: profile.email.trim()), 'Could not open email app.'),
                          icon: const Icon(Icons.email_outlined),
                          label: const Text('Email'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF123222),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: normalizedWebsite.isEmpty
                              ? null
                              : () => _launch(context, Uri.parse(normalizedWebsite), 'Could not open website.'),
                          icon: const Icon(Icons.language_outlined),
                          label: const Text('Website'),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E2E1E),
                            foregroundColor: const Color(0xFFF59E0B),
                            side: const BorderSide(color: Color(0xFFF59E0B)),
                          ),
                          onPressed: () async {
                            final providerUid = await _resolveProviderUid(profile);
                            if (!context.mounted) return;
                            if (providerUid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Direct messaging is not available for this listing yet.')),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProviderChatThreadScreen(
                                  providerUid: providerUid,
                                  providerName: profile.providerName.trim().isEmpty ? profile.title : profile.providerName,
                                  postId: widget.postId,
                                  postType: widget.postType,
                                  postTitle: profile.title,
                                  postCategory: profile.category,
                                  providerPhone: profile.phone,
                                  providerEmail: profile.email,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Message'),
                        ),
                      ],
                    ),
                    if (profile.phone.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text('Phone: ${profile.phone}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                    if (profile.email.trim().isNotEmpty)
                      Text('Email: ${profile.email}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (normalizedWebsite.isNotEmpty)
                      Text('Website: $normalizedWebsite', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recent Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('Reviews')
                          .where('targetKey', isEqualTo: targetKey)
                          .orderBy('createdAt', descending: true)
                          .limit(10)
                          .snapshots(),
                      builder: (context, reviewsSnapshot) {
                        final docs = reviewsSnapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Text(
                            'No feedback yet. Be the first to leave a review.',
                            style: TextStyle(color: Colors.white54),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data();
                            final reviewer = (data['reviewerName'] ?? 'Anonymous').toString();
                            final comment = (data['comment'] ?? '').toString();
                            final rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0;
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF123425),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        reviewer,
                                        style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${rating.toStringAsFixed(1)} ★',
                                        style: const TextStyle(color: Color(0xFFE8D79B), fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(comment, style: const TextStyle(color: Colors.white70)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResolvedServiceProfile {
  const _ResolvedServiceProfile({
    required this.title,
    required this.category,
    required this.description,
    required this.providerName,
    required this.city,
    required this.phone,
    required this.email,
    required this.website,
    required this.userId,
    required this.imageUrl,
  });

  final String title;
  final String category;
  final String description;
  final String providerName;
  final String city;
  final String phone;
  final String email;
  final String website;
  final String userId;
  final String imageUrl;
}
