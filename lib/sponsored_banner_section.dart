import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'business_screen.dart';

class SponsoredBannerSection extends StatelessWidget {
  const SponsoredBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = Timestamp.now();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('sponsoredBanners').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        final banners = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data();
          final startsAt = data['startsAt'] as Timestamp?;
          final endsAt = data['endsAt'] as Timestamp?;
          return (startsAt == null || !startsAt.toDate().isAfter(now.toDate())) && (endsAt == null || !endsAt.toDate().isBefore(now.toDate()));
        }).toList();
        if (banners.isEmpty) return const SizedBox.shrink();
        return Column(children: banners.map((doc) => _SponsoredBannerCard(doc: doc)).toList());
      },
    );
  }
}

class _SponsoredBannerCard extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _SponsoredBannerCard({required this.doc});
  @override
  State<_SponsoredBannerCard> createState() => _SponsoredBannerCardState();
}

class _SponsoredBannerCardState extends State<_SponsoredBannerCard> {
  bool dismissed = false;
  bool isClaimed = false;

  void _claimOffer(BuildContext context, Map<String, dynamic> data) {
    final promoCode = data['promoCode']?.toString() ?? '';
    if (promoCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: promoCode));
    }
    setState(() => isClaimed = true);
    widget.doc.reference.update({'claimsCount': FieldValue.increment(1)});

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎉 Promo Code $promoCode Claimed and Copied to Clipboard!'),
      backgroundColor: const Color(0xFF004D40),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'View Business',
        textColor: const Color(0xFFFFD700),
        onPressed: () => _openTarget(context, data),
      ),
    ));
  }

  void _openTarget(BuildContext context, Map<String, dynamic> data) {
    final targetBizData = data['targetBusinessData'] is Map ? Map<String, dynamic>.from(data['targetBusinessData']) : null;
    if (targetBizData != null && targetBizData.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BusinessDetailScreen(businessData: targetBizData),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BusinessDirectoryScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (dismissed) return const SizedBox.shrink();
    final data = widget.doc.data();
    final imageUrl = data['imageUrl']?.toString();
    final title = data['title']?.toString() ?? 'Sponsored promotion';
    final body = data['body']?.toString() ?? '';
    final promo = data['promoCode']?.toString();
    final discountText = data['discountText']?.toString() ?? (data['discountPercent'] != null ? '${data['discountPercent']}% OFF' : '');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF174A3D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTarget(context, data),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Photo if uploaded
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (ctx, url, err) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('SPONSORED AD', style: TextStyle(color: Color(0xFF061E12), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      if (discountText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(discountText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Dismiss Banner',
                        onPressed: () => setState(() => dismissed = true),
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(title, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 19, fontWeight: FontWeight.bold)),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                  ],
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      if (promo != null && promo.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF061E12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFD700)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.confirmation_number_outlined, color: Color(0xFFFFD700), size: 16),
                              const SizedBox(width: 6),
                              Text('Code: $promo', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF061E12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => _claimOffer(context, data),
                        icon: Icon(isClaimed ? Icons.check_circle : Icons.local_offer, size: 16),
                        label: Text(isClaimed ? 'Claimed ✅' : 'Claim Offer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
