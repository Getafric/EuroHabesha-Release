import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BusinessDirectoryScreen extends StatelessWidget {
  const BusinessDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    // ── የተመዘገቡ የንግድ ተቋማት (Verified Businesses) መረጃ ከነሙሉ አድራሻቸው ──
    final List<Map<String, dynamic>> businessList = [
      {
        'title': 'Authentic Ethiopian Cuisine',
        'name': 'Lucy Habesha Restaurant',
        'location': 'Lyon, France',
        'address': '12 Rue de Marseille, 69007 Lyon, France', // 🗺️ ማፕ የሚከፍትበት አድራሻ
        'rating': '4.9 (320 reviews)',
        'badge': 'Registered', 
        'registration': 'SIRET: 123 456 789 00012', 
        'phone': 'tel:+33400000000',
        'email': 'contact@lucyrestaurant.fr',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/33400000000',
        'description': 'Experience the best authentic Ethiopian and Eritrean traditional food in Lyon. We offer Injera with various Wots, Tibs, and traditional coffee ceremonies. Officially registered and inspected.',
        'icon': Icons.restaurant,
        'gallery': [
          'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1514933651103-005eec06c04b?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1544025162-83569c72f1a6?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Miki C.', 'comment': 'Best Kitfo in town! The vibe is amazing and feels like home.', 'rating': '5.0'},
          {'user': 'Sara K.', 'comment': 'Very clean, professional staff, and delicious food.', 'rating': '4.8'},
        ]
      },
      {
        'title': 'Unisex Hair Salon & Cosmetics',
        'name': 'Konjo Beauty Salon',
        'location': 'Paris, France',
        'address': '45 Boulevard de Sébastopol, 75001 Paris, France', // 🗺️ ማፕ የሚከፍትበት አድራሻ
        'rating': '4.7 (150 reviews)',
        'badge': 'Premium', 
        'registration': 'SIREN: 987 654 321',
        'phone': 'tel:+33122334455',
        'email': 'booking@konjosalon.fr',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/33122334455',
        'description': 'Professional hair styling, braiding, coloring, and cosmetics store tailored for Habesha men and women. Officially registered salon in the heart of Paris.',
        'icon': Icons.spa,
        'gallery': [
          'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1522337660859-02fbefca4702?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Helen T.', 'comment': 'Love my new braids! The staff is officially certified and very polite.', 'rating': '5.0'},
        ]
      },
      {
        'title': 'Grocery & Traditional Spices',
        'name': 'Habesha Supermarket',
        'location': 'Lyon, France',
        'address': '8 Rue Paul Bert, 69003 Lyon, France', // 🗺️ ማፕ የሚከፍትበት አድራሻ
        'rating': '4.8 (85 reviews)',
        'badge': 'Registered', 
        'registration': 'SIRET: 456 789 123 00045',
        'phone': 'tel:+33411223344',
        'email': 'market@eurohabesha.eu',
        'website': 'https://www.eurohabesha.eu',
        'whatsapp': 'https://wa.me/33411223344',
        'description': 'Your one-stop shop for Teff, Berbere, Shiro, and imported traditional items. Fresh Injera available every Tuesday and Friday.',
        'icon': Icons.storefront,
        'gallery': [
          'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
          'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=800&q=80',
        ],
        'reviews': [
          {'user': 'Getu A.', 'comment': 'They have everything I need. Very authentic products!', 'rating': '4.9'},
        ]
      },
    ];

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text('Business Directory', style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: businessList.length,
        itemBuilder: (context, index) {
          final biz = businessList[index];
          return Card(
            color: cardGreen,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: primaryGold.withOpacity(0.3), width: 1),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusinessDetailScreen(businessData: biz),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(biz['icon'], color: primaryGold, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  biz['name']!, 
                                  style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildBusinessBadge(biz['badge']),
                          const SizedBox(height: 8),
                          Text(biz['title']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            '📍 ${biz['location']} • ⭐ ${biz['rating']}', 
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessBadge(String tier) {
    Color badgeColor = tier == 'Premium' ? const Color(0xFFFFD700) : const Color(0xFF64B5F6);
    IconData badgeIcon = tier == 'Premium' ? Icons.store : Icons.domain_verification;
    String label = tier == 'Premium' ? 'Premium Business' : 'Verified Business';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 12),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── 💡 የቢዝነሱ ዝርዝር ገጽ (ከምዝገባ ቁጥር፣ አድራሻ እና ማፕ አዘራር ጋር) ──
class BusinessDetailScreen extends StatelessWidget {
  final Map<String, dynamic> businessData;

  const BusinessDetailScreen({super.key, required this.businessData});

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

  // 🗺️ ጉግል ማፕ በቀጥታ የሚከፍትበት ፈንክሽን (Google Maps Navigation)
  Future<void> _openMap(String address) async {
    final Uri mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch map for address: $address');
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkGreen = const Color(0xFF061E12);
    final Color primaryGold = const Color(0xFFFFD700);
    final Color cardGreen = const Color(0xFF004D40);

    final List galleryImages = businessData['gallery'] ?? [];
    final List reviewsList = businessData['reviews'] ?? [];
    final String address = businessData['address'] ?? 'Address not specified';

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      appBar: AppBar(
        title: Text(businessData['name'], style: TextStyle(color: primaryGold, fontWeight: FontWeight.bold)),
        backgroundColor: primaryDarkGreen,
        iconTheme: IconThemeData(color: primaryGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. የቢዝነስ ስም፣ ባጅ እና የምዝገባ ቁጥር ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: primaryGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(businessData['icon'], color: primaryGold, size: 40),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(businessData['name'], style: TextStyle(color: primaryGold, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      _buildDetailBadge(businessData['badge']),
                      const SizedBox(height: 6),
                      // 💡 የቢዝነስ ምዝገባ ቁጥር (SIRET/SIREN)
                      Row(
                        children: [
                          const Icon(Icons.assignment_turned_in, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(businessData['registration'], style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(businessData['title'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ── 2. የኮንታክት አዝራሮች (spaceBetween የተደረገ) ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionBtn(Icons.phone, 'Call', primaryGold, cardGreen, () => _launchUrl(businessData['phone'], isPhone: true)),
                _buildActionBtn(Icons.email, 'Email', primaryGold, cardGreen, () => _launchUrl(businessData['email'], isEmail: true)),
                _buildActionBtn(Icons.language, 'Website', primaryGold, cardGreen, () => _launchUrl(businessData['website'])),
              ],
            ),
            const SizedBox(height: 25),

            // ── 3. ቢዝነስ ጋለሪ (የምግብ፣ ሱቅ፣ ጸጉር ቤት ፎቶዎች) ──
            if (galleryImages.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Business Gallery', style: TextStyle(color: primaryGold, fontSize: 15, fontWeight: FontWeight.bold)),
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

            // ── 4. ቢዝነስ ማብራሪያ፣ አድራሻ እና ማፕ አዝራር (Get Directions) ──
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
                  const Text('About the Business', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(businessData['description'], style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  // 🗺️ አድራሻ እና ዳይሬክሽን በተን
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFFD700), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address, 
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        // 🗺️ ጉግል ማፕ በቀጥታ ይከፍታል
                        _openMap(address);
                      },
                      child: Text('Get Directions / Map 🗺️', style: TextStyle(color: primaryDarkGreen, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 15),
                      const SizedBox(width: 4),
                      Text(businessData['rating'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 5. የደንበኛ ሪቪው ──
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGold,
                  foregroundColor: primaryDarkGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 20),
                label: const Text('Call for Reservation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                onPressed: () => _launchUrl(businessData['phone'], isPhone: true),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Business messaging is disabled. Reserve Plus and Live Zone will be connected here later.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label, Color goldColor, Color bgColor, VoidCallback onTap) {
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

  Widget _buildDetailBadge(String tier) {
    Color badgeColor = tier == 'Premium' ? const Color(0xFFFFD700) : const Color(0xFF64B5F6);
    IconData badgeIcon = tier == 'Premium' ? Icons.store : Icons.domain_verification;
    String label = tier == 'Premium' ? 'Premium Registered Business' : 'Official Registered Business';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ── 💡 የቢዝነስ የውስጥ ቻት ገጽ (Business Chat Screen) ──
class BusinessDirectChatScreen extends StatefulWidget {
  final String chatName;
  final IconData iconData;

  const BusinessDirectChatScreen({super.key, required this.chatName, required this.iconData});

  @override
  State<BusinessDirectChatScreen> createState() => _BusinessDirectChatScreenState();
}

class _BusinessDirectChatScreenState extends State<BusinessDirectChatScreen> {
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Welcome to our business! How can we serve you today?',
      'isMe': false,
      'time': 'Online',
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
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'We received your message and a representative will reply shortly.',
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: cardGreen, borderRadius: BorderRadius.circular(8)),
              child: Icon(widget.iconData, color: primaryGold, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatName, style: TextStyle(color: primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('Verified Business • Online', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
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
                        Text(msg['text'], style: TextStyle(color: isMe ? primaryDarkGreen : Colors.white, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text(msg['time'], style: TextStyle(color: isMe ? primaryDarkGreen.withOpacity(0.6) : Colors.white54, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardGreen,
              border: Border(top: BorderSide(color: primaryGold.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: primaryGold),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Message Business...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: primaryDarkGreen,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
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