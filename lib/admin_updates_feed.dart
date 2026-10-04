import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'admin_announcement_screen.dart';
import 'app_session.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminUpdatesFeed extends StatelessWidget {
  const AdminUpdatesFeed({super.key});

  static const Color primaryGold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('adminAnnouncements')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: primaryGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.campaign_rounded,
                      color: primaryGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      switch (context.locale.languageCode) {
                        'fr' => 'Actualités officielles',
                        'am' => 'ይፋዊ ዜናዎች',
                        'ti' => 'ወግዓዊ ሓበሬታ',
                        _ => 'Official Updates',
                      },
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    switch (context.locale.languageCode) {
                      'fr' => 'Voir tout',
                      'am' => 'ሁሉንም ይመልከቱ',
                      'ti' => 'ኩሉ ርአ',
                      _ => 'View all',
                    },
                    style: const TextStyle(
                      color: primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...docs.map(
              (doc) => _AdminUpdateCard(doc: doc),
            ),
            const SizedBox(height: 18),
          ],
        );
      },
    );
  }
}

class _AdminUpdateCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  const _AdminUpdateCard({
    required this.doc,
  });

  static const Color primaryGold = Color(0xFFFFD700);
  static const Color cardGreen = Color(0xFF004D40);
  Future<void> _deleteOfficialUpdate(
    BuildContext context,
  ) async {
    if (!AppSession.isSuperAdmin) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardGreen,
          title: const Text(
            'Delete Official Update?',
            style: TextStyle(
              color: primaryGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This will permanently delete this update, '
            'its comments, replies, likes and poll votes.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final data = doc.data();

      final mediaStoragePath = data['mediaStoragePath']?.toString().trim();

      // Likes de la publication.
      final postLikes = await doc.reference.collection('likes').get();

      for (final like in postLikes.docs) {
        await like.reference.delete();
      }

      // Votes du sondage.
      final votes = await doc.reference.collection('votes').get();

      for (final vote in votes.docs) {
        await vote.reference.delete();
      }

      // Commentaires + likes des commentaires.
      final comments = await doc.reference.collection('comments').get();

      for (final comment in comments.docs) {
        final commentLikes = await comment.reference.collection('likes').get();

        for (final like in commentLikes.docs) {
          await like.reference.delete();
        }

        await comment.reference.delete();
      }

      // Supprime ensuite la publication principale.
      await doc.reference.delete();

      // Supprime enfin le média associé dans Storage.
      if (mediaStoragePath != null && mediaStoragePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.ref(mediaStoragePath).delete();
        } catch (_) {
          // La publication reste supprimée même si
          // le fichier Storage n'existe déjà plus.
        }
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Official update deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $error',
          ),
        ),
      );
    }
  }

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

    try {
      final existing = await likeRef.get();

      if (existing.exists) {
        await likeRef.delete();
      } else {
        await likeRef.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Like could not be updated: $error',
          ),
        ),
      );
    }
  }

  Future<void> _openComments(
    BuildContext context,
  ) async {
    if (AppSession.isGuest || FirebaseAuth.instance.currentUser == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(
        announcementRef: doc.reference,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();

    final message = data['message']?.toString() ?? '';
    final mediaUrl = data['mediaUrl']?.toString();
    final postType = data['postType']?.toString() ?? 'announcement';
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified,
                color: primaryGold,
                size: 17,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Euro Habesha Official',
                  style: TextStyle(
                    color: primaryGold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (AppSession.isSuperAdmin)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 20,
                  ),
                  color: cardGreen,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminAnnouncementScreen(
                            announcementId: doc.id,
                          ),
                        ),
                      );
                    }

                    if (value == 'delete') {
                      await _deleteOfficialUpdate(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: primaryGold,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Edit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 19,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 5),
          if (postType != 'poll')
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    message,
                    maxLines: mediaUrl != null && mediaUrl.isNotEmpty ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.30,
                    ),
                  ),
                ),
                if (mediaUrl != null && mediaUrl.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      width: 90,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          if (postType == 'poll') ...[
            if (message.isNotEmpty) ...[
              Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.30,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _OfficialPoll(
              announcementRef: doc.reference,
              data: data,
            ),
          ],
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LikeButton(
                announcementRef: doc.reference,
                onPressed: () => _like(context),
              ),
              const SizedBox(width: 2),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: doc.reference.collection('comments').snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;

                  return TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => _openComments(context),
                    icon: const Icon(
                      Icons.mode_comment_outlined,
                      color: primaryGold,
                      size: 17,
                    ),
                    label: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> announcementRef;

  final VoidCallback onPressed;

  const _LikeButton({
    required this.announcementRef,
    required this.onPressed,
  });

  static const Color primaryGold = Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: announcementRef.collection('likes').snapshots(),
      builder: (context, likesSnapshot) {
        final likes = likesSnapshot.data?.docs ?? [];

        final liked = user != null &&
            likes.any(
              (like) => like.id == user.uid,
            );

        return TextButton.icon(
          onPressed: onPressed,
          icon: Icon(
            liked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
            color: primaryGold,
            size: 18,
          ),
          label: Text(
            '${likes.length}',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> announcementRef;

  const _CommentsSheet({
    required this.announcementRef,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  static const Color primaryDarkGreen = Color(0xFF061E12);

  static const Color primaryGold = Color(0xFFFFD700);

  static const Color cardGreen = Color(0xFF004D40);

  final TextEditingController _controller = TextEditingController();

  bool _sending = false;
  String? _replyToCommentId;
  String? _replyToName;

  void _startReply({
    required String commentId,
    required String authorName,
  }) {
    setState(() {
      _replyToCommentId = commentId;
      _replyToName = authorName;
    });

    _controller.clear();
    FocusScope.of(context).requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToName = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_sending) return;

    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();

    if (user == null || text.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      String authorName = 'Member';
      String? authorPhotoUrl;
      bool authorVerified = false;
      String? authorSubscriptionTier;

      final profileSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profile = profileSnapshot.data();

      if (profile != null) {
        final savedName = profile['displayName']?.toString().trim() ?? '';

        if (savedName.isNotEmpty && !savedName.contains('@')) {
          authorName = savedName;
        }

        final savedPhoto = profile['photoUrl']?.toString().trim() ?? '';

        if (savedPhoto.isNotEmpty) {
          authorPhotoUrl = savedPhoto;
        }

        authorVerified = profile['isVerified'] == true ||
            profile['verificationStatus'] == 'approved';

        final tier = profile['subscriptionTier']?.toString().toLowerCase();

        if (profile['subscriptionActive'] == true &&
            (tier == 'pro' || tier == 'vip')) {
          authorSubscriptionTier = tier;
        }
      }

      if (authorName == 'Member') {
        final firebaseName = user.displayName?.trim() ?? '';

        if (firebaseName.isNotEmpty && !firebaseName.contains('@')) {
          authorName = firebaseName;
        }
      }

      await widget.announcementRef.collection('comments').add({
        'text': text,
        'authorId': user.uid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'authorVerified': authorVerified,
        'authorSubscriptionTier': authorSubscriptionTier,
        'parentCommentId': _replyToCommentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _controller.clear();
      _cancelReply();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Comment could not be posted: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(
        bottom: keyboard,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: const BoxDecoration(
          color: primaryDarkGreen,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                8,
                8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        color: primaryGold,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Colors.white12,
              height: 1,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: widget.announcementRef
                    .collection('comments')
                    .orderBy(
                      'createdAt',
                      descending: true,
                    )
                    .limit(100)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primaryGold,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Comments could not be loaded.',
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                    );
                  }

                  final comments = snapshot.data?.docs ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No comments yet.\nBe the first to comment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white54,
                        ),
                      ),
                    );
                  }

                  final parentComments = comments.where((comment) {
                    final parentId =
                        comment.data()['parentCommentId']?.toString().trim() ??
                            '';
                    return parentId.isEmpty;
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: parentComments.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Colors.white10,
                    ),
                    itemBuilder: (context, index) {
                      final commentDoc = parentComments[index];
                      final data = commentDoc.data();
                      final replies = comments.where((reply) {
                        final parentId = reply
                                .data()['parentCommentId']
                                ?.toString()
                                .trim() ??
                            '';
                        return parentId == commentDoc.id;
                      }).toList();

                      Widget buildComment({
                        required Map<String, dynamic> commentData,
                        required String commentId,
                        required bool isReply,
                      }) {
                        final commentText =
                            commentData['text']?.toString() ?? '';

                        final commentAuthorName = commentData['authorName']
                                    ?.toString()
                                    .trim()
                                    .isNotEmpty ==
                                true
                            ? commentData['authorName'].toString().trim()
                            : 'Member';

                        final photoUrl =
                            commentData['authorPhotoUrl']?.toString().trim() ??
                                '';

                        final verified = commentData['authorVerified'] == true;

                        final tier = commentData['authorSubscriptionTier']
                            ?.toString()
                            .toLowerCase();
                        final commentRef = widget.announcementRef
                            .collection('comments')
                            .doc(commentId);
                        final currentUser = FirebaseAuth.instance.currentUser;
                        final authorId =
                            commentData['authorId']?.toString() ?? '';

                        final isOwnComment =
                            currentUser != null && authorId == currentUser.uid;
                        final canModerateComment = AppSession.isSuperAdmin;
                        return Padding(
                          padding: EdgeInsets.only(
                            left: isReply ? 38 : 0,
                            top: isReply ? 8 : 0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: isReply ? 15 : 18,
                                backgroundColor: cardGreen,
                                backgroundImage: photoUrl.isNotEmpty
                                    ? CachedNetworkImageProvider(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        color: primaryGold,
                                        size: isReply ? 16 : 19,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            commentAuthorName,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: primaryGold,
                                              fontSize: isReply ? 12 : 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (verified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            color: primaryGold,
                                            size: 15,
                                          ),
                                        ],
                                        if (tier == 'pro' || tier == 'vip') ...[
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryGold.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tier!.toUpperCase(),
                                              style: const TextStyle(
                                                color: primaryGold,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (isOwnComment ||
                                            canModerateComment) ...[
                                          const Spacer(),
                                          PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            iconSize: 19,
                                            color: cardGreen,
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.white54,
                                              size: 19,
                                            ),
                                            onSelected: (value) async {
                                              if (value == 'edit') {
                                                final editController =
                                                    TextEditingController(
                                                  text: commentText,
                                                );

                                                final newText =
                                                    await showDialog<String>(
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          cardGreen,
                                                      title: const Text(
                                                        'Edit comment',
                                                        style: TextStyle(
                                                          color: primaryGold,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      content: TextField(
                                                        controller:
                                                            editController,
                                                        autofocus: true,
                                                        minLines: 2,
                                                        maxLines: 6,
                                                        maxLength: 2000,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                          hintText:
                                                              'Write your comment...',
                                                          hintStyle: TextStyle(
                                                            color:
                                                                Colors.white38,
                                                          ),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                dialogContext);
                                                          },
                                                          child: const Text(
                                                            'Cancel',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .white70,
                                                            ),
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            final text =
                                                                editController
                                                                    .text
                                                                    .trim();

                                                            if (text
                                                                .isNotEmpty) {
                                                              Navigator.pop(
                                                                  dialogContext,
                                                                  text);
                                                            }
                                                          },
                                                          child: const Text(
                                                            'Save',
                                                            style: TextStyle(
                                                              color:
                                                                  primaryGold,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                editController.dispose();

                                                if (newText != null &&
                                                    newText != commentText) {
                                                  await commentRef.update({
                                                    'text': newText,
                                                    'editedAt': FieldValue
                                                        .serverTimestamp(),
                                                  });
                                                }
                                              }

                                              if (value == 'delete') {
                                                await commentRef.delete();
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              if (isOwnComment)
                                                const PopupMenuItem<String>(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.edit_outlined,
                                                        color:
                                                            Colors.blueAccent,
                                                        size: 19,
                                                      ),
                                                      SizedBox(width: 8),
                                                      Text(
                                                        'Edit',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete_outline,
                                                      color: Colors.redAccent,
                                                      size: 19,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      commentText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            _startReply(
                                              commentId: isReply
                                                  ? (commentData[
                                                              'parentCommentId']
                                                          ?.toString() ??
                                                      commentId)
                                                  : commentId,
                                              authorName: commentAuthorName,
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(0, 28),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          icon: const Icon(
                                            Icons.reply,
                                            color: primaryGold,
                                            size: 15,
                                          ),
                                          label: const Text(
                                            'Reply',
                                            style: TextStyle(
                                              color: primaryGold,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        StreamBuilder<
                                            QuerySnapshot<
                                                Map<String, dynamic>>>(
                                          stream: commentRef
                                              .collection('likes')
                                              .snapshots(),
                                          builder: (context, likeSnapshot) {
                                            final user = FirebaseAuth
                                                .instance.currentUser;
                                            final likes =
                                                likeSnapshot.data?.docs ?? [];

                                            final liked = user != null &&
                                                likes.any((like) =>
                                                    like.id == user.uid);

                                            return InkWell(
                                              onTap: user == null
                                                  ? null
                                                  : () async {
                                                      final likeRef = commentRef
                                                          .collection('likes')
                                                          .doc(user.uid);

                                                      if (liked) {
                                                        await likeRef.delete();
                                                      } else {
                                                        await likeRef.set({
                                                          'userId': user.uid,
                                                          'createdAt': FieldValue
                                                              .serverTimestamp(),
                                                        });
                                                      }
                                                    },
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 5,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      liked
                                                          ? Icons.thumb_up_alt
                                                          : Icons
                                                              .thumb_up_alt_outlined,
                                                      color: liked
                                                          ? primaryGold
                                                          : Colors.white54,
                                                      size: 16,
                                                    ),
                                                    if (likes.isNotEmpty) ...[
                                                      const SizedBox(width: 5),
                                                      Text(
                                                        '${likes.length}',
                                                        style: TextStyle(
                                                          color: liked
                                                              ? primaryGold
                                                              : Colors.white54,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildComment(
                            commentData: data,
                            commentId: commentDoc.id,
                            isReply: false,
                          ),
                          for (final reply in replies)
                            buildComment(
                              commentData: reply.data(),
                              commentId: reply.id,
                              isReply: true,
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                12,
                12,
              ),
              decoration: const BoxDecoration(
                color: cardGreen,
                border: Border(
                  top: BorderSide(
                    color: Colors.white12,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_replyToCommentId != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.reply,
                            color: primaryGold,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Replying to ${_replyToName ?? 'Member'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _cancelReply,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              hintText: _replyToCommentId != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                              hintStyle: const TextStyle(
                                color: Colors.white38,
                              ),
                              filled: true,
                              fillColor: primaryDarkGreen,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sending ? null : _sendComment,
                          style: IconButton.styleFrom(
                            backgroundColor: primaryGold,
                          ),
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryDarkGreen,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: primaryDarkGreen,
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficialPoll extends StatelessWidget {
  const _OfficialPoll({
    required this.announcementRef,
    required this.data,
  });

  final DocumentReference<Map<String, dynamic>> announcementRef;
  final Map<String, dynamic> data;

  static const Color primaryDarkGreen = Color(0xFF061E12);
  static const Color primaryGold = Color(0xFFFFD700);

  Future<void> _vote(
    BuildContext context,
    String optionId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || AppSession.isGuest) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    final latest = await announcementRef.get();

    if (!latest.exists || latest.data()?['pollClosed'] == true) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This poll is closed.'),
        ),
      );
      return;
    }

    await announcementRef.collection('votes').doc(user.uid).set({
      'userId': user.uid,
      'optionId': optionId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _closePoll(BuildContext context) async {
    if (!AppSession.isSuperAdmin) return;

    await announcementRef.update({
      'pollClosed': true,
      'pollClosedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Poll closed.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = data['pollQuestion']?.toString().trim() ?? '';

    final closed = data['pollClosed'] == true;

    final rawOptions = data['pollOptions'];

    final options = rawOptions is List
        ? rawOptions
            .whereType<Map>()
            .map(
              (option) => Map<String, dynamic>.from(option),
            )
            .toList()
        : <Map<String, dynamic>>[];

    if (question.isEmpty || options.length < 2) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: announcementRef.collection('votes').snapshots(),
      builder: (context, snapshot) {
        final votes = snapshot.data?.docs ?? [];
        final totalVotes = votes.length;

        final currentUser = FirebaseAuth.instance.currentUser;

        String? myOptionId;

        if (currentUser != null) {
          for (final vote in votes) {
            if (vote.id == currentUser.uid) {
              myOptionId = vote.data()['optionId']?.toString();
              break;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: primaryDarkGreen,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primaryGold.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.poll_outlined,
                    color: primaryGold,
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final option in options) ...[
                Builder(
                  builder: (context) {
                    final optionId = option['id']?.toString() ?? '';

                    final label = option['label']?.toString() ?? '';

                    final optionVotes = votes.where((vote) {
                      return vote.data()['optionId']?.toString() == optionId;
                    }).length;

                    final percentage =
                        totalVotes == 0 ? 0.0 : optionVotes / totalVotes;

                    final selected = myOptionId == optionId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: closed || optionId.isEmpty
                            ? null
                            : () => _vote(
                                  context,
                                  optionId,
                                ),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected ? primaryGold : Colors.white24,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color:
                                        selected ? primaryGold : Colors.white54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: selected
                                            ? primaryGold
                                            : Colors.white,
                                        fontWeight: selected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${(percentage * 100).round()}%',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 5,
                                  backgroundColor: Colors.white12,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    primaryGold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              Row(
                children: [
                  Text(
                    '$totalVotes vote${totalVotes == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  if (closed) ...[
                    const SizedBox(width: 10),
                    const Text(
                      '• Closed',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (AppSession.isSuperAdmin && !closed)
                    TextButton.icon(
                      onPressed: () => _closePoll(context),
                      icon: const Icon(
                        Icons.lock_outline,
                        color: primaryGold,
                        size: 17,
                      ),
                      label: const Text(
                        'Close poll',
                        style: TextStyle(
                          color: primaryGold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
