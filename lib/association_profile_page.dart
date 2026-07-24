import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AssociationProfilePage extends StatefulWidget {
  final String associationId;
  final Map<String, dynamic> data;

  const AssociationProfilePage({
    super.key,
    required this.associationId,
    required this.data,
  });

  @override
  State<AssociationProfilePage> createState() => _AssociationProfilePageState();
}

class _AssociationProfilePageState extends State<AssociationProfilePage> {
  final PageController _pageController = PageController();
  final TextEditingController _commentController = TextEditingController();
  int _currentPage = 0;
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildProjects(Map<String, dynamic> data) {
    final raw = data['activeProjects'];
    final name = (data['legalName'] ?? 'Association').toString();
    final address = (data['exactAddress'] ?? 'Address unavailable').toString();
    final rating = (data['rating'] ?? 0).toDouble();
    final reviews = (data['reviewCount'] ?? 0) as int;

    if (raw is List && raw.isNotEmpty) {
      return raw.map((item) {
        final text = item.toString();
        return {
          'title': text,
          'provider': name,
          'location': address,
          'rating': rating,
          'reviews': reviews,
          'icon': _iconForProject(text),
        };
      }).toList();
    }

    return [
      {
        'title': 'Community Outreach Project',
        'provider': name,
        'location': address,
        'rating': rating,
        'reviews': reviews,
        'icon': Icons.volunteer_activism_outlined,
      },
      {
        'title': 'Youth Mentorship Program',
        'provider': name,
        'location': address,
        'rating': rating,
        'reviews': reviews,
        'icon': Icons.school_outlined,
      },
      {
        'title': 'Culture & Language Workshop',
        'provider': name,
        'location': address,
        'rating': rating,
        'reviews': reviews,
        'icon': Icons.translate_outlined,
      },
      {
        'title': 'Family Support Desk',
        'provider': name,
        'location': address,
        'rating': rating,
        'reviews': reviews,
        'icon': Icons.support_agent_outlined,
      },
    ];
  }

  List<List<Map<String, dynamic>>> _chunkProjects(List<Map<String, dynamic>> cards) {
    if (cards.isEmpty) return [];
    final pages = <List<Map<String, dynamic>>>[];
    for (var i = 0; i < cards.length; i += 4) {
      final end = (i + 4) > cards.length ? cards.length : i + 4;
      pages.add(cards.sublist(i, end));
    }
    return pages;
  }

  IconData _iconForProject(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('job')) return Icons.work_outline;
    if (lower.contains('legal')) return Icons.gavel_outlined;
    if (lower.contains('education') || lower.contains('school')) return Icons.school_outlined;
    if (lower.contains('event')) return Icons.event_outlined;
    if (lower.contains('women')) return Icons.groups_2_outlined;
    if (lower.contains('health')) return Icons.health_and_safety_outlined;
    if (lower.contains('youth')) return Icons.emoji_people_outlined;
    return Icons.campaign_outlined;
  }

  Future<void> _openExternal(String rawUrl) async {
    final url = rawUrl.trim();
    if (url.isEmpty) return;

    final normalized = url.startsWith('http://') || url.startsWith('https://') ? url : 'https://$url';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _toggleFollow({required bool isFollowing}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to follow this association.')),
      );
      return;
    }

    final associationRef = FirebaseFirestore.instance.collection('associations').doc(widget.associationId);
    final followerRef = associationRef.collection('followers').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final associationSnap = await txn.get(associationRef);
      final followerSnap = await txn.get(followerRef);
      final currentCount = (associationSnap.data()?['followerCount'] ?? 0) as int;

      if (isFollowing && followerSnap.exists) {
        txn.delete(followerRef);
        txn.update(associationRef, {'followerCount': currentCount > 0 ? currentCount - 1 : 0});
      } else if (!isFollowing && !followerSnap.exists) {
        final displayName = (user.displayName ?? user.email?.split('@').first ?? 'User').trim();
        txn.set(followerRef, {
          'uid': user.uid,
          'displayName': displayName,
          'email': user.email ?? '',
          'followedAt': FieldValue.serverTimestamp(),
        });
        txn.update(associationRef, {'followerCount': currentCount + 1});
      }
    });
  }

  Future<void> _submitComment() async {
    if (_isSubmittingComment) return;
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to comment.')),
      );
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final displayName = (user.displayName ?? user.email?.split('@').first ?? 'User').trim();
      await FirebaseFirestore.instance
          .collection('associations')
          .doc(widget.associationId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'displayName': displayName,
        'email': user.email ?? '',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('associations').doc(widget.associationId).snapshots(),
      builder: (context, associationSnapshot) {
        final liveData = associationSnapshot.data?.data() ?? widget.data;
        final cards = _buildProjects(liveData);
        final chunkedProjects = _chunkProjects(cards);

        final legalName = (liveData['legalName'] ?? 'Association').toString();
        final description = (liveData['description'] ?? '').toString();
        final address = (liveData['exactAddress'] ?? '').toString();
        final email = (liveData['email'] ?? '').toString();
        final phone = (liveData['contactPhone'] ?? '').toString();
        final verified = liveData['verifiedTick'] == true;
        final verificationStatus = (liveData['verificationStatus'] ?? 'pending').toString();
        final followerCount = (liveData['followerCount'] ?? 0) as int;

        final links = (liveData['links'] is Map)
            ? Map<String, dynamic>.from(liveData['links'] as Map)
            : <String, dynamic>{};

        final logoUrl = (liveData['logoDownloadUrl'] ?? '').toString();
        final coverUrl = (liveData['coverDownloadUrl'] ?? '').toString();
        final logo64 = (liveData['logoImageBase64'] ?? '').toString();
        final cover64 = (liveData['coverImageBase64'] ?? '').toString();

        Uint8List? logoBytes;
        Uint8List? coverBytes;

        if (logo64.isNotEmpty) {
          try {
            logoBytes = base64Decode(logo64);
          } catch (_) {}
        }
        if (cover64.isNotEmpty) {
          try {
            coverBytes = base64Decode(cover64);
          } catch (_) {}
        }

        final ImageProvider<Object>? logoImage = logoUrl.isNotEmpty
          ? NetworkImage(logoUrl) as ImageProvider<Object>
          : (logoBytes == null ? null : MemoryImage(logoBytes) as ImageProvider<Object>);
        final ImageProvider<Object>? coverImage = coverUrl.isNotEmpty
          ? NetworkImage(coverUrl) as ImageProvider<Object>
          : (coverBytes == null ? null : MemoryImage(coverBytes) as ImageProvider<Object>);

        final followerStream = (user == null)
            ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
            : FirebaseFirestore.instance
                .collection('associations')
                .doc(widget.associationId)
                .collection('followers')
                .doc(user.uid)
                .snapshots();

        return Scaffold(
          backgroundColor: const Color(0xFF061E12),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFF0E2E1E),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: const Color(0xFF164A32)),
                      if (coverImage != null)
                        Image(
                          image: coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xAA061E12)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: const Color(0xFF0E2E1E),
                          backgroundImage: logoImage,
                          child: logoImage == null ? const Icon(Icons.apartment, color: Colors.white70, size: 38) : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              legalName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.verified, color: Color(0xFF2196F3), size: 22),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: verified ? const Color(0xFF0B7A55) : const Color(0xFF7A5A0B),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            verificationStatus == 'verified' ? 'Verified Association' : 'Pending Verification',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          '$followerCount followers',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: followerStream,
                          builder: (context, followerSnapshot) {
                            final isFollowing = followerSnapshot.data?.exists == true;
                            return ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing ? const Color(0xFF0E2E1E) : const Color(0xFFF59E0B),
                                foregroundColor: isFollowing ? Colors.white : const Color(0xFF061E12),
                              ),
                              onPressed: () => _toggleFollow(isFollowing: isFollowing),
                              icon: Icon(isFollowing ? Icons.check_circle_outline : Icons.person_add_alt_1),
                              label: Text(isFollowing ? 'Following' : 'Follow Association'),
                            );
                          },
                        ),
                      ),
                      if (!verified) ...[
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Your documents have been submitted. We will verify your credentials within 24 hours.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _sectionCard(
                        title: 'Mission',
                        child: Text(
                          description.isEmpty ? 'No description provided yet.' : description,
                          style: const TextStyle(color: Colors.white70, height: 1.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Contact',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _lineItem(Icons.location_on_outlined, address.isEmpty ? 'Address unavailable' : address),
                            const SizedBox(height: 8),
                            _lineItem(Icons.email_outlined, email.isEmpty ? 'Email unavailable' : email),
                            const SizedBox(height: 8),
                            _lineItem(Icons.phone_outlined, phone.isEmpty ? 'Phone unavailable' : phone),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        title: 'Website & Social',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _linkChip('Website', links['website']?.toString() ?? '', Icons.language_outlined),
                            _linkChip('Facebook', links['facebook']?.toString() ?? '', Icons.facebook),
                            _linkChip('TikTok', links['tiktok']?.toString() ?? '', Icons.music_note_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Active Projects / Posts',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 360,
                        child: chunkedProjects.isEmpty
                            ? const Center(
                                child: Text('No active projects yet.', style: TextStyle(color: Colors.white60)),
                              )
                            : PageView.builder(
                                controller: _pageController,
                                onPageChanged: (value) {
                                  setState(() {
                                    _currentPage = value;
                                  });
                                },
                                itemCount: chunkedProjects.length,
                                itemBuilder: (context, pageIndex) {
                                  final items = chunkedProjects[pageIndex];
                                  return GridView.builder(
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.only(top: 6),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.05,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0E2E1E),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.white12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(item['icon'] as IconData, color: const Color(0xFFF59E0B), size: 16),
                                                ),
                                                const Spacer(),
                                                const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${(item['rating'] as double).toStringAsFixed(1)} (${item['reviews']})',
                                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              item['title'].toString(),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            const Spacer(),
                                            Text(
                                              item['provider'].toString(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(color: Color(0xFFBFD6CC), fontSize: 12),
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, color: Colors.white54, size: 12),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    item['location'].toString(),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 6),
                      if (chunkedProjects.length > 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(chunkedProjects.length, (index) {
                            final selected = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 7,
                              width: selected ? 16 : 7,
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFFF59E0B) : Colors.white30,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            );
                          }),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Community Comments',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              maxLines: 2,
                              minLines: 1,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Write a comment...',
                                hintStyle: const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF0E2E1E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSubmittingComment ? null : _submitComment,
                            child: const Text('Post'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('associations')
                            .doc(widget.associationId)
                            .collection('comments')
                            .orderBy('createdAt', descending: true)
                            .limit(50)
                            .snapshots(),
                        builder: (context, commentsSnapshot) {
                          final comments = commentsSnapshot.data?.docs ?? [];
                          if (comments.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No comments yet.', style: TextStyle(color: Colors.white60)),
                            );
                          }

                          return ListView.separated(
                            itemCount: comments.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final data = comments[index].data();
                              final author = (data['displayName'] ?? 'User').toString();
                              final text = (data['text'] ?? '').toString();
                              return Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E2E1E),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(text, style: const TextStyle(color: Colors.white70, height: 1.35)),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E2E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _lineItem(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _linkChip(String label, String url, IconData icon) {
    final hasValue = url.trim().isNotEmpty;
    return ActionChip(
      backgroundColor: hasValue ? const Color(0xFF123626) : const Color(0xFF2A2A2A),
      avatar: Icon(icon, color: hasValue ? const Color(0xFFF59E0B) : Colors.white38, size: 18),
      label: Text(
        label,
        style: TextStyle(
          color: hasValue ? Colors.white : Colors.white38,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: hasValue ? () => _openExternal(url) : null,
    );
  }
}
