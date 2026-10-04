import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_session.dart';

Future<void> openDirectChat({
  required BuildContext context,
  required String otherUserId,
  required String otherUserName,
  bool professionalAutoReply = false,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null || AppSession.isGuest) {
    Navigator.pushNamed(context, '/login');
    return;
  }

  final targetUid = otherUserId.trim();

  if (targetUid.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This member cannot receive messages yet.'),
      ),
    );
    return;
  }

  if (targetUid == user.uid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You cannot message yourself.'),
      ),
    );
    return;
  }

  final ids = [user.uid, targetUid]..sort();
  final chatId = '${ids[0]}_${ids[1]}';

  final myName = AppSession.displayName.trim().isNotEmpty
      ? AppSession.displayName.trim()
      : 'Member';

  final targetName =
      otherUserName.trim().isNotEmpty ? otherUserName.trim() : 'Member';

  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  try {
    final myPhotoUrl = AppSession.photoUrl.trim();

    final chatData = <String, dynamic>{
      'participants': [user.uid, targetUid],
      'participantNames': {
        user.uid: myName,
        targetUid: targetName,
      },
      'participantPhotos': {
        user.uid: myPhotoUrl,
      },
      'chatType': professionalAutoReply ? 'professional' : 'direct',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (professionalAutoReply) {
      chatData['professionalId'] = targetUid;
      chatData['professionalAutoReplyEnabled'] = true;
    }

    await chatRef.set(
      chatData,
      SetOptions(merge: true),
    );

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          chatId: chatId,
          title: targetName,
        ),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Conversation could not be opened: $error',
        ),
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text('Messages',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        foregroundColor: primaryGold,
        elevation: 0,
      ),
      body: AppSession.isGuest || user == null
          ? _buildSignInRequired(context)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: user.uid)
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryGold));
                }

                if (snapshot.hasError) {
                  debugPrint('CHAT LIST FIRESTORE ERROR: ${snapshot.error}');

                  return _buildMessage(
                    'Could not load messages.\n\n${snapshot.error}',
                  );
                }

                final chats = snapshot.data?.docs ?? [];
                if (chats.isEmpty) {
                  return _buildMessage(
                      'No messages yet. Conversations will appear here instantly.');
                }

                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final chatDoc = chats[index];
                    final chat = chatDoc.data();
                    final participantNames = Map<String, dynamic>.from(
                        chat['participantNames'] ?? {});
                    final title = participantNames.entries
                            .where((entry) => entry.key != user.uid)
                            .map((entry) => entry.value.toString())
                            .firstOrNull ??
                        chat['title']?.toString() ??
                        'Conversation';
                    final lastMessage =
                        chat['lastMessage']?.toString() ?? 'Tap to open chat';
                    final participantPhotos = Map<String, dynamic>.from(
                      chat['participantPhotos'] ?? {},
                    );

                    final otherPhotoUrl = participantPhotos.entries
                            .where((entry) => entry.key != user.uid)
                            .map((entry) => entry.value.toString().trim())
                            .where((url) => url.isNotEmpty)
                            .firstOrNull ??
                        '';

                    final updatedAt = chat['updatedAt'] as Timestamp?;

                    String timeText = '';
                    if (updatedAt != null) {
                      final date = updatedAt.toDate();
                      final now = DateTime.now();

                      if (date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day) {
                        timeText =
                            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                      } else {
                        timeText =
                            '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                      }
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: primaryGold.withValues(alpha: 0.20),
                        radius: 25,
                        backgroundImage: otherPhotoUrl.isNotEmpty
                            ? NetworkImage(otherPhotoUrl)
                            : null,
                        child: otherPhotoUrl.isEmpty
                            ? Text(
                                title.isNotEmpty ? title[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: primaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing:
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: chatDoc.reference
                            .collection('messages')
                            .snapshots(),
                        builder: (context, messageSnapshot) {
                          final messages = messageSnapshot.data?.docs ?? [];

                          final unreadCount = messages.where((messageDoc) {
                            final data = messageDoc.data();

                            final senderId = data['senderId']?.toString() ?? '';

                            final readBy = List<String>.from(
                              data['readBy'] ?? const <String>[],
                            );

                            return senderId != user.uid &&
                                !readBy.contains(user.uid);
                          }).length;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (timeText.isNotEmpty)
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    color: unreadCount > 0
                                        ? primaryGold
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: unreadCount > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              if (unreadCount > 0)
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 22,
                                    minHeight: 22,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: primaryGold,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: primaryDarkGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white38,
                                  size: 14,
                                ),
                            ],
                          );
                        },
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatThreadScreen(
                              chatId: chatDoc.id,
                              title: title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSignInRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, color: primaryGold, size: 56),
            const SizedBox(height: 14),
            const Text('Sign in to use messages',
                style: TextStyle(
                    color: primaryGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
                'Guest users can browse, but messaging needs a verified account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryGold),
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Sign In / Register',
                  style: TextStyle(
                      color: primaryDarkGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 15)),
      ),
    );
  }
}

class ChatThreadScreen extends StatefulWidget {
  final String chatId;
  final String title;

  const ChatThreadScreen(
      {super.key, required this.chatId, required this.title});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
  }

  Future<void> _markMessagesAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final messages = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in messages.docs) {
        final data = doc.data();
        final senderId = data['senderId']?.toString() ?? '';

        final readBy = List<String>.from(
          data['readBy'] ?? const <String>[],
        );

        if (senderId != user.uid && !readBy.contains(user.uid)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([user.uid]),
          });
        }
      }

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      batch.set(
        chatRef,
        {
          'unreadCounts': {
            user.uid: 0,
          },
        },
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (error) {
      debugPrint('MARK MESSAGES READ ERROR: $error');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _messageController.text.trim();
    if (user == null || text.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    try {
      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      await chatRef.collection('messages').add({
        'senderId': user.uid,
        'senderEmail': user.email,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [user.uid],
      });
      await chatRef.set({
        'lastMessage': text,
        'lastSenderId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'participants': FieldValue.arrayUnion([user.uid]),
        'participantNames': {
          user.uid: AppSession.displayName,
        },
        'participantPhotos': {
          user.uid: AppSession.photoUrl,
        },
      }, SetOptions(merge: true));
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Message failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(
                color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(color: primaryGold),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: primaryGold));
                }
                final messages = snapshot.data?.docs ?? [];
                if (messages.isEmpty) {
                  return const Center(
                      child: Text('Start the conversation.',
                          style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data();
                    final isMe = message['senderId'] == user?.uid;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isMe ? primaryGold : cardGreen,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(message['text']?.toString() ?? '',
                            style: TextStyle(
                                color: isMe ? primaryDarkGreen : Colors.white,
                                height: 1.35)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              color: cardGreen,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: primaryDarkGreen,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: primaryGold),
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(Icons.send, color: primaryDarkGreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
