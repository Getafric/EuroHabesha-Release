import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'business_order_detail_screen.dart';
import 'cash_on_delivery_order_screen.dart';
import 'admin_invitation_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const Color primaryDarkGreen =
      BusinessOrderDetailScreen.primaryDarkGreen;
  static const Color primaryGold = BusinessOrderDetailScreen.primaryGold;
  static const Color cardGreen = Color(0xFF004D40);

  Future<void> _markAsRead(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    await reference.update({
      'read': true,
    });
  }

  Future<void> _markAllAsRead(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final document in snapshot.docs) {
      final data = document.data();
      final type = data['type']?.toString().trim() ?? '';

      if (type != 'message' && data['read'] != true) {
        batch.update(document.reference, {
          'read': true,
        });
      }
    }
    await batch.commit();
  }

  String _formatTime(dynamic value) {
    if (value is! Timestamp) {
      return '';
    }

    final date = value.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l’instant';
    }

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;

      case 'chat':
      case 'message':
        return Icons.chat_bubble_outline;

      case 'comment':
      case 'reply':
        return Icons.comment_outlined;

      case 'post':
        return Icons.article_outlined;

      case 'event':
        return Icons.event_outlined;

      case 'professional':
        return Icons.business_center_outlined;

      case 'follow':
        return Icons.person_add_alt_1_outlined;

      case 'association':
        return Icons.groups_outlined;

      case 'admin':
      case 'approval':
        return Icons.verified_outlined;

      default:
        return Icons.notifications_none;
    }
  }

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> notification,
  ) async {
    final routeType = notification['routeType']?.toString().trim() ?? '';

    final resourceId =
        notification['resourceId']?.toString().trim().isNotEmpty == true
            ? notification['resourceId'].toString().trim()
            : notification['orderId']?.toString().trim() ?? '';

    if (!context.mounted) {
      return;
    }

    switch (routeType) {
      case 'adminInvite':
        if (resourceId.isEmpty) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminInvitationScreen(
              invitationId: resourceId,
            ),
          ),
        );
        break;

      case 'sellerOrder':
        if (resourceId.isEmpty) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BusinessOrderDetailScreen(
              orderId: resourceId,
            ),
          ),
        );
        break;

      case 'buyerOrder':
        if (resourceId.isEmpty) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CashOnDeliveryOrderTrackingScreen(
              orderId: resourceId,
            ),
          ),
        );
        break;
      case 'chat':
      case 'message':
        if (resourceId.isEmpty) {
          return;
        }

        final chatDocument = await FirebaseFirestore.instance
            .collection('chats')
            .doc(resourceId)
            .get();

        String title = 'Conversation';

        if (chatDocument.exists) {
          final chat = chatDocument.data() ?? {};
          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

          final participantNames = Map<String, dynamic>.from(
            chat['participantNames'] ?? {},
          );

          final otherNames = participantNames.entries
              .where((entry) => entry.key != currentUserId)
              .map((entry) => entry.value.toString().trim())
              .where((name) => name.isNotEmpty)
              .toList();

          if (otherNames.isNotEmpty) {
            title = otherNames.first;
          } else {
            final storedTitle = chat['title']?.toString().trim() ?? '';

            if (storedTitle.isNotEmpty) {
              title = storedTitle;
            }
          }
        }

        if (!context.mounted) {
          return;
        }

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              chatId: resourceId,
              title: title,
            ),
          ),
        );
        break;

      default:
        // Les autres destinations globales seront branchées
        // progressivement : chat, commentaire, événement, etc.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: primaryDarkGreen,
        body: Center(
          child: Text(
            'Vous devez être connecté.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: primaryGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryDarkGreen,
        iconTheme: const IconThemeData(
          color: primaryGold,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.done_all,
              color: Colors.white70,
            ),
            tooltip: 'Tout marquer comme lu',
            onPressed: () => _markAllAsRead(user.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where(
              'recipientId',
              isEqualTo: user.uid,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Impossible de charger les notifications.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGold,
              ),
            );
          }

          final documents = snapshot.data!.docs.where((document) {
            final type = document.data()['type']?.toString().trim() ?? '';

            return type != 'message';
          }).toList();

          documents.sort((a, b) {
            final aTime = a.data()['createdAt'];
            final bTime = b.data()['createdAt'];

            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }

            if (aTime is Timestamp) {
              return -1;
            }

            if (bTime is Timestamp) {
              return 1;
            }

            return 0;
          });

          if (documents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    color: Colors.white38,
                    size: 55,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Aucune notification',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              final notification = document.data();

              final isUnread = notification['read'] != true;

              final title =
                  notification['title']?.toString().trim() ?? 'Euro Habesha';

              final body = notification['body']?.toString().trim() ?? '';

              final type = notification['type']?.toString().trim() ?? 'general';

              final createdAt = notification['createdAt'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isUnread
                      ? cardGreen.withValues(alpha: 0.8)
                      : cardGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUnread
                        ? primaryGold.withValues(
                            alpha: 0.5,
                          )
                        : Colors.transparent,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: primaryGold.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      _notificationIcon(type),
                      color: primaryGold,
                    ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(
                      color: isUnread ? Colors.white : Colors.white70,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      body,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(createdAt),
                        style: TextStyle(
                          color: primaryGold.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: primaryGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  onTap: () async {
                    if (isUnread) {
                      await _markAsRead(
                        document.reference,
                      );
                    }

                    if (!context.mounted) {
                      return;
                    }

                    await _openNotification(
                      context,
                      notification,
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
