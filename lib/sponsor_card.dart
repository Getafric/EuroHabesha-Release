import 'package:flutter/material.dart';

class SponsorCard extends StatelessWidget {
  final String companyName;
  final String slogan;
  final String sponsorLevel; // 'VIP', 'Gold', 'Premium'
  final String industry;
  final String city;
  final String country;
  final String phone;
  final String description;
  final String logoUrl;
  final VoidCallback onContactPressed;

  const SponsorCard({
    super.key,
    required this.companyName,
    required this.slogan,
    required this.sponsorLevel,
    required this.industry,
    required this.city,
    required this.country,
    required this.phone,
    required this.description,
    required this.logoUrl,
    required this.onContactPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    switch (sponsorLevel.toUpperCase()) {
      case 'VIP':
        levelColor = const Color(0xFFF59E0B); // Gold
        break;
      case 'GOLD':
        levelColor = const Color(0xFFF59E0B);
        break;
      case 'PLATINUM':
        levelColor = Colors.cyanAccent;
        break;
      default:
        levelColor = Colors.white70;
    }

    return Card(
      color: const Color(0xFF0E2E1E), // Medium dark emerald card
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: levelColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      shadowColor: levelColor.withValues(alpha: 0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0E2E1E),
              levelColor.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Logo, Company Name, and Level Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF061E12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.business,
                        color: levelColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: levelColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: levelColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              '$sponsorLevel SPONSOR',
                              style: TextStyle(
                                color: levelColor,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        slogan,
                        style: TextStyle(
                          color: levelColor.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sponsoring Domain & Location Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    industry,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, color: Colors.white38, size: 14),
                const SizedBox(width: 2),
                Text(
                  '$city, $country',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 20),

            // Description of what the Sponsor does / provides
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Action row: Contact info & Chat trigger button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk_outlined, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      phone,
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF061E12),
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: onContactPressed,
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text(
                    'Contact Hub',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}