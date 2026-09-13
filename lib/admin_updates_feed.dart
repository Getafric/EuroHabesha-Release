import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminUpdatesFeed extends StatelessWidget {
  const AdminUpdatesFeed({super.key});

  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('adminAnnouncements').orderBy('createdAt', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: primaryGold)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Official Updates', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            ...docs.map((doc) => _AdminUpdateCard(doc: doc)),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }
}

class _AdminUpdateCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _AdminUpdateCard({required this.doc});

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  Future<void> _like(BuildContext context) async {
    if (AppSession.isGuest) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final likeRef = doc.reference.collection('likes').doc(user.uid);
    final existing = await likeRef.get();
    if (existing.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({'userId': user.uid, 'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<void> _comment(BuildContext context) async {
    if (AppSession.isGuest) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: primaryDarkGreen,
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comment', style: TextStyle(color: primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write detailed feedback, report a bug, or share your thoughts...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: cardGreen,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold, minimumSize: const Size(double.infinity, 48)),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  return;
                }
                await doc.reference.collection('comments').add({
                  'text': text,
                  'authorId': user.uid,
                  'authorEmail': AppSession.email,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                await doc.reference.update({'commentsCount': FieldValue.increment(1)});
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Post Comment', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final message = data['message'] as String? ?? '';
    final likes = data['likesCount'] ?? 0;
    final comments = data['commentsCount'] ?? 0;
    final mediaUrl = data['mediaUrl']?.toString();

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
          const Row(
            children: [
              Icon(Icons.verified, color: primaryGold, size: 18),
              SizedBox(width: 6),
              Text('Euro Habesha Official', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          if (message.isNotEmpty) Text(message, style: const TextStyle(color: Colors.white, height: 1.45)),
          if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: CachedNetworkImage(imageUrl: mediaUrl, width: double.infinity, height: 180, fit: BoxFit.cover)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _like(context),
                icon: const Icon(Icons.thumb_up_alt_outlined, color: primaryGold, size: 18),
                label: Text('$likes', style: const TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: () => _comment(context),
                icon: const Icon(Icons.mode_comment_outlined, color: primaryGold, size: 18),
                label: Text('$comments', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
