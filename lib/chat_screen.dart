import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'provider_chat_thread_screen.dart';
import 'registration_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF061E12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E2E1E),
          title: const Text('Messages'),
        ),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create an account to access your messaging center.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF061E12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                    );
                  },
                  child: const Text('Register / Sign In'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E2E1E),
        title: const Text('Messaging Center', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participantIds', arrayContains: uid)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unable to load conversations: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = [...(snapshot.data?.docs ?? [])]
            ..sort((a, b) {
              final aTs = a.data()['updatedAt'];
              final bTs = b.data()['updatedAt'];
              final aMs = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
              final bMs = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
              return bMs.compareTo(aMs);
            });
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No conversations yet. Open any listing and tap Message to start.',
                style: TextStyle(color: Colors.white60),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final names = Map<String, dynamic>.from(data['participantNameMap'] ?? const <String, dynamic>{});
              final providerName = (data['providerName'] ?? names.entries
                  .firstWhere(
                    (entry) => entry.key != uid,
                    orElse: () => const MapEntry<String, dynamic>('', 'Provider'),
                  )
                  .value ?? 'Provider')
                  .toString();
              final lastMsg = (data['lastMsg'] ?? '').toString();
              final postTitle = (data['postTitle'] ?? '').toString();
              final postCategory = (data['postCategory'] ?? '').toString();
              final providerUid = (data['providerUid'] ?? '').toString();
              final providerPhone = (data['providerPhone'] ?? '').toString();
              final providerEmail = (data['providerEmail'] ?? '').toString();
              final postId = (data['postId'] ?? '').toString();
              final postType = (data['postType'] ?? '').toString();

              return Card(
                color: const Color(0xFF0E2E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: ListTile(
                  title: Text(providerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (postTitle.trim().isNotEmpty)
                        Text(
                          postTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      if (postCategory.trim().isNotEmpty)
                        Text(postCategory, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      Text(
                        lastMsg.trim().isEmpty ? 'Tap to open conversation' : lastMsg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFF59E0B)),
                  onTap: providerUid.trim().isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProviderChatThreadScreen(
                                providerUid: providerUid,
                                providerName: providerName,
                                postId: postId,
                                postType: postType,
                                postTitle: postTitle,
                                postCategory: postCategory,
                                providerPhone: providerPhone,
                                providerEmail: providerEmail,
                              ),
                            ),
                          );
                        },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
