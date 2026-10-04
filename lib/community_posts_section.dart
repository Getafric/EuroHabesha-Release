import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityPostsSection extends StatelessWidget {
  const CommunityPostsSection({super.key});
  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('status', isEqualTo: 'published')
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const SizedBox.shrink();
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Community Posts',
                        style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 18,
                            fontWeight: FontWeight.bold))),
                ...docs.map((doc) => _PostCard(doc: doc))
              ]);
        },
      );
}

class _PostCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _PostCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final imageUrl = data['imageUrl']?.toString();
    final user = FirebaseAuth.instance.currentUser;
    return Card(
      color: const Color(0xFF004D40),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['authorName']?.toString() ?? 'Community member',
                style: const TextStyle(
                    color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            if ((data['text']?.toString() ?? '').isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(data['text'].toString(),
                      style:
                          const TextStyle(color: Colors.white, height: 1.4))),
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover))),
            if (user != null)
              Row(
                children: [
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: doc.reference
                        .collection('likes')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, likeSnapshot) {
                      final liked = likeSnapshot.data?.exists == true;
                      return TextButton.icon(
                        onPressed: () async {
                          final ref =
                              doc.reference.collection('likes').doc(user.uid);
                          if (liked) {
                            await ref.delete();
                          } else {
                            await ref.set({
                              'userId': user.uid,
                              'createdAt': FieldValue.serverTimestamp()
                            });
                          }
                        },
                        icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: const Color(0xFFFFD700)),
                        label: const Text('Like',
                            style: TextStyle(color: Colors.white)),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: () => _showComments(context, user),
                    icon: const Icon(Icons.comment_outlined,
                        color: Color(0xFFFFD700)),
                    label: const Text('Comment',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showComments(BuildContext context, User user) async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF061E12),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comments',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              height: 180,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: doc.reference
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  final comments = snapshot.data?.docs ?? [];
                  final commentTiles = comments.map<Widget>((comment) {
                    final commentData = comment.data();
                    return ListTile(
                      title: Text(commentData['text']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(
                          commentData['authorEmail']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white54)),
                    );
                  }).toList();
                  return ListView(children: commentTiles);
                },
              ),
            ),
            TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'Write a comment',
                    hintStyle: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                await doc.reference.collection('comments').add({
                  'text': text,
                  'authorId': user.uid,
                  'authorEmail': user.email,
                  'createdAt': FieldValue.serverTimestamp()
                });
                controller.clear();
              },
              child: const Text('Publish comment'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}
