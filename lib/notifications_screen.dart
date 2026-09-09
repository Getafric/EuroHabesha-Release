import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    // ── የኖቲፊኬሽን ዳታ (Dummy Data) ──
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'New Message from Dr. Selamawit',
        'subtitle': 'Hello, your appointment is confirmed...',
        'time': '2 mins ago',
        'icon': Icons.chat_bubble,
        'color': Colors.blueAccent,
        'isUnread': true,
      },
      {
        'title': 'Event Reminder',
        'subtitle': 'Ethiopian New Year Mega Concert is tomorrow!',
        'time': '1 hour ago',
        'icon': Icons.event,
        'color': primaryGold,
        'isUnread': true,
      },
      {
        'title': 'System Update',
        'subtitle': 'Welcome to Euro Habesha! Complete your profile.',
        'time': '1 day ago',
        'icon': Icons.system_update_alt,
        'color': Colors.greenAccent,
        'isUnread': false,
      },
      {
        'title': 'Marketplace Alert',
        'subtitle': 'Your item "iPhone 13 Pro" has a new view.',
        'time': '2 days ago',
        'icon': Icons.storefront,
        'color': Colors.orangeAccent,
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white54),
            tooltip: 'Mark all as read',
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final bool isUnread = notif['isUnread'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isUnread ? cardGreen.withOpacity(0.8) : cardGreen.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isUnread ? primaryGold.withOpacity(0.5) : Colors.transparent),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: notif['color'].withOpacity(0.2),
                child: Icon(notif['icon'], color: notif['color'], size: 20),
              ),
              title: Text(
                notif['title'],
                style: TextStyle(
                  color: isUnread ? Colors.white : Colors.white70,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(notif['subtitle'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(notif['time'], style: TextStyle(color: primaryGold.withOpacity(0.7), fontSize: 10)),
                  const SizedBox(height: 5),
                  if (isUnread)
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryGold, shape: BoxShape.circle)),
                ],
              ),
              onTap: () {
                // ኖቲፊኬሽኑ ሲነካ የሚሰራው
              },
            ),
          );
        },
      ),
    );
  }
}
