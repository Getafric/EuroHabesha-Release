import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'cash_on_delivery_order_screen.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    // ── የቢዝነሶች እና የሰርቪስ አቅራቢዎች የተሟላ መረጃ ──
    final List<Map<String, dynamic>> jobList = [
      {
        'title': 'Professional Photographer & Videographer',
        'name': 'Getafric Production',
        'location': 'Lyon, France',
        'rating': '4.9 (140 reviews)',
        'phone': 'tel:+33600000000',
        'email': 'getafric@eurohabesha.eu',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/33600000000',
        'description': 'Professional wedding, commercial, and event photography and videography services using Canon EOS 90D and DJI RS 3 Pro equipment across Europe. Capturing your best moments with high-end cinematic quality.',
        'icon': Icons.camera_alt,
        'gallery': [
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1537633552985-df8429e8048b?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1511285560929-80b456fea0bc?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1520854221256-17451cc331bf?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Dawit M.', 'comment': 'Amazing photography work in Lyon! Very professional equipment and great quality.', 'rating': '5.0'},
          {'user': 'Hermela T.', 'comment': 'Getafric Production covered our wedding event. Highly recommended across France!', 'rating': '4.8'},
        ]
      },
      {
        'title': 'Heavy Goods Vehicle Driver',
        'name': 'Getu (PERRENOT FOURCHET)',
        'location': 'Lyon, France',
        'rating': '5.0 (85 reviews)',
        'phone': 'tel:+33611223344',
        'email': 'getu@eurohabesha.eu',
        'website': 'https://www.perrenot.com',
        'whatsapp': 'https://wa.me/33611223344',
        'description': 'Experienced HGV heavy goods vehicle driver specializing in regional and long-distance freight logistics across France, Germany, and neighboring European routes.',
        'icon': Icons.local_shipping,
        'gallery': [
          'https://images.unsplash.com/photo-1519003722824-194d4455a60c?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Transport Manager', 'comment': 'Very reliable and punctual heavy vehicle logistics driver.', 'rating': '5.0'},
        ]
      },
      {
        'title': 'Translator - Amharic / Tigrinya / French',
        'name': 'Selam Translation Services',
        'location': 'Brussels, Belgium',
        'rating': '4.9 (62 reviews)',
        'phone': 'tel:+3220000000',
        'email': 'translator@eurohabesha.eu',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/3220000000',
        'description': 'Certified translation for phone calls, appointments, legal letters, and documents. Rates available per hour or per paper.',
        'icon': Icons.translate,
        'serviceType': 'translator',
        'ratePerHour': '€25/hour',
        'ratePerDocument': 'From €30/document',
        'gallery': [],
        'reviews': [
          {'user': 'Mebratu K.', 'comment': 'Very clear and professional translation support.', 'rating': '5.0'},
        ]
      },
      {
        'title': 'Fashion / Clothes Designer',
        'name': 'Marta Habesha Design',
        'location': 'Frankfurt, Germany',
        'rating': '5.0 (44 reviews)',
        'phone': 'tel:+4915123456789',
        'email': 'designer@eurohabesha.eu',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/4915123456789',
        'description': 'Custom Habesha Kemis, modern cultural dresses, wedding outfits, and made-to-measure clothing. Orders are paid on delivery or arrival.',
        'icon': Icons.checkroom,
        'serviceType': 'designer',
        'gallery': [
          'https://images.unsplash.com/photo-1583391733958-d15317a86976?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Sara T.', 'comment': 'Beautiful custom dress and perfect fitting.', 'rating': '5.0'},
        ]
      },
      {
        'title': 'Catering / Injera & Wot Seller',
        'name': 'Taitu Habesha Catering',
        'location': 'Lyon, France',
        'rating': '4.8 (91 reviews)',
        'phone': 'tel:+33622334455',
        'email': 'catering@eurohabesha.eu',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/33622334455',
        'description': 'Fresh injera, doro wot, tibs, vegan platters, and event catering. Orders are cash on delivery or pay on arrival only.',
        'icon': Icons.restaurant_menu,
        'serviceType': 'catering',
        'menuItems': [
          {'name': 'Injera pack', 'price': '€10'},
          {'name': 'Doro Wot', 'price': '€18'},
          {'name': 'Tibs Tray', 'price': '€25'},
        ],
        'gallery': [
          'https://images.unsplash.com/photo-1544025162-83569c72f1a6?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Dawit A.', 'comment': 'Fresh injera and fast delivery.', 'rating': '4.8'},
        ]
      },
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Jobs & Services', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: jobList.length,
        itemBuilder: (context, index) {
          final job = jobList[index];
          return Card(
            color: cardGreen,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: primaryGold.withOpacity(0.3), width: 1),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Icon(job['icon'], color: primaryGold, size: 32),
              title: Text(job['name']!, style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text(
                '${job['title']}\n📍 ${job['location']} • ⭐ ${job['rating']}', 
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: primaryGold, size: 14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => JobDetailScreen(jobData: job),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── 💡 የተሟላ የቢዝነስ/ሰርቪስ ዲቴይል ገጽ ──
class JobDetailScreen extends StatelessWidget {
  final Map<String, dynamic> jobData;

  const JobDetailScreen({super.key, required this.jobData});

  Future<void> _launchUrl(String urlString, {bool isEmail = false, bool isPhone = false}) async {
    final Uri uri = isEmail 
        ? Uri(scheme: 'mailto', path: urlString)
        : isPhone 
            ? Uri.parse(urlString)
            : Uri.parse(urlString);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    final List<dynamic> galleryImages = jobData['gallery'] ?? [];
    final List<dynamic> reviewsList = jobData['reviews'] ?? [];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(jobData['name'], style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(jobData['icon'], color: primaryGold, size: 40),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(jobData['name'], style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(jobData['title'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildContactActionButton(Icons.phone, 'Call', primaryGold, cardGreen, () {
                  _launchUrl(jobData['phone'], isPhone: true);
                }),
                _buildContactActionButton(Icons.email, 'Email', primaryGold, cardGreen, () {
                  _launchUrl(jobData['email'], isEmail: true);
                }),
                _buildContactActionButton(Icons.language, 'Website', primaryGold, cardGreen, () {
                  _launchUrl(jobData['website']);
                }),
              ],
            ),
            const SizedBox(height: 25),

            if (galleryImages.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Portfolio & Gallery', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
                  Text('(${galleryImages.length} Photos)', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryGold.withOpacity(0.3)),
                        image: DecorationImage(
                          image: NetworkImage(galleryImages[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),
            ],

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardGreen, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About Service & Details', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(jobData['description'], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(jobData['location'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 20),
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(jobData['rating'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Customer Reviews', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...reviewsList.map((rev) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardGreen,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(rev['user'], style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFD700), size: 13),
                          const SizedBox(width: 3),
                          Text(rev['rating'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(rev['comment'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            )),
            const SizedBox(height: 25),

            if (jobData['serviceType'] == 'translator') ...[
              _buildServiceInfoCard([
                'Rate per hour: ${jobData['ratePerHour']}',
                'Rate per document/paper: ${jobData['ratePerDocument']}',
                'Service type: In-person or Phone',
              ], cardGreen, primaryGold),
              const SizedBox(height: 20),
            ],

            if (jobData['serviceType'] == 'catering') ...[
              _buildMenuCard(jobData['menuItems'] ?? [], cardGreen, primaryGold),
              const SizedBox(height: 20),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.phone_in_talk, size: 20),
                    label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      _launchUrl(jobData['whatsapp']);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold, 
                      foregroundColor: primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: const Text('In-app Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: () {
                      // ── 💡 አሁን በቀጥታ ወደ እውነተኛው የቻት ገጽ ይወስዳል ──
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DirectChatScreen(
                            chatName: jobData['name'], 
                            iconData: jobData['icon']
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (jobData['serviceType'] == 'designer' || jobData['serviceType'] == 'catering') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGold,
                    foregroundColor: primaryDarkGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(jobData['serviceType'] == 'designer' ? Icons.straighten : Icons.delivery_dining),
                  label: Text(jobData['serviceType'] == 'designer' ? 'Send Custom Order & Pay on Delivery' : 'Order Food & Pay on Delivery', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CashOnDeliveryOrderScreen(
                          itemType: jobData['serviceType'],
                          itemTitle: jobData['title'],
                          sellerName: jobData['name'],
                          sellerContact: jobData['phone'],
                          price: jobData['serviceType'] == 'catering' ? 'Menu price' : 'Custom quote',
                          sourceData: jobData,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactActionButton(IconData icon, String label, Color goldColor, Color bgColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: goldColor.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: goldColor, size: 16),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard(List<String> lines, Color bgColor, Color goldColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Service Pricing', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final line in lines) Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(List<dynamic> items, Color bgColor, Color goldColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menu', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item['name'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                  Text(item['price'] ?? '', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── 💡 አዲሱ እና እውነተኛው የቻት መጻፊያ ገጽ (Direct Chat Screen) ──
class DirectChatScreen extends StatefulWidget {
  final String chatName;
  final IconData iconData;

  const DirectChatScreen({super.key, required this.chatName, required this.iconData});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();

  // የቻት ታሪኮች
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! How can I help you today?',
      'isMe': false,
      'time': '10:00 AM',
    }
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': 'Now',
      });
    });
    _messageController.clear();

    // (እንደ ምሳሌ፣ መልስ እየተጻፈ መሆኑን ለማሳየት)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'Thank you for reaching out! I will get back to you shortly.',
            'isMe': false,
            'time': 'Now',
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: cardGreen,
              child: Icon(widget.iconData, color: primaryGold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatName, style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('Online', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'];

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? primaryGold : cardGreen,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: Radius.circular(isMe ? 15 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? primaryDarkGreen : Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          msg['time'],
                          style: TextStyle(
                            color: isMe ? primaryDarkGreen.withOpacity(0.6) : Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ── የጽሁፍ መጻፊያ (Keyboard Input) ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardGreen,
              border: Border(top: BorderSide(color: primaryGold.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: primaryGold),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: primaryDarkGreen,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: CircleAvatar(
                    backgroundColor: primaryGold,
                    child: Icon(Icons.send, color: primaryDarkGreen, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
