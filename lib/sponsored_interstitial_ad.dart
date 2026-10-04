import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'business_screen.dart';
import 'events_screen.dart';
import 'marketplace_screen.dart';

class SponsoredInterstitialAd {
  SponsoredInterstitialAd._();

  // Maximum une publicité plein écran par session.
  static bool _shownThisSession = false;

  static Future<void> showIfAvailable(
    BuildContext context,
  ) async {
    if (_shownThisSession) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sponsoredBanners')
          .where('status', isEqualTo: 'active')
          .get();

      if (!context.mounted) return;

      final now = DateTime.now();

      final available = snapshot.docs.where((doc) {
        final data = doc.data();

        final startsAt = data['startsAt'];
        final endsAt = data['endsAt'];

        if (startsAt is Timestamp && now.isBefore(startsAt.toDate())) {
          return false;
        }

        if (endsAt is Timestamp && now.isAfter(endsAt.toDate())) {
          return false;
        }

        return true;
      }).toList();

      if (available.isEmpty) return;

      final index = DateTime.now().millisecondsSinceEpoch % available.length;

      final data = available[index].data();

      _shownThisSession = true;

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return _SponsoredInterstitialDialog(
            data: data,
          );
        },
      );
    } catch (_) {
      // Une publicité ne doit jamais bloquer l'accueil.
    }
  }
}

class _SponsoredInterstitialDialog extends StatelessWidget {
  const _SponsoredInterstitialDialog({
    required this.data,
  });

  final Map<String, dynamic> data;

  static const Color darkGreen = Color(0xFF061E12);
  static const Color cardGreen = Color(0xFF004D40);
  static const Color gold = Color(0xFFFFD700);

  void _openOffer(BuildContext context) {
    final targetType =
        (data['targetType'] ?? 'business').toString().toLowerCase();

    final targetRoute =
        (data['targetRoute'] ?? '').toString().trim().toLowerCase();

    final rawTargetData = data['targetData'] ?? data['targetBusinessData'];

    final targetData = rawTargetData is Map
        ? Map<String, dynamic>.from(rawTargetData)
        : <String, dynamic>{};

    Navigator.of(context).pop();

    // EVENT : ouvre directement l'événement choisi.
    if (targetType == 'event' ||
        targetRoute == '/event' ||
        targetRoute == '/events') {
      if (targetData.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(
              eventData: targetData,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EventsScreen(),
          ),
        );
      }

      return;
    }

    // MARKETPLACE : ouvre directement le produit choisi.
    if (targetType == 'marketplace' || targetRoute == '/marketplace') {
      if (targetData.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: targetData,
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MarketplaceScreen(),
          ),
        );
      }

      return;
    }

    // BUSINESS / RESTAURANT.
    if (targetData.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BusinessDetailScreen(
            businessData: targetData,
          ),
        ),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BusinessDirectoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName =
        data['businessName']?.toString().trim().isNotEmpty == true
            ? data['businessName'].toString()
            : data['targetBusinessName']?.toString().trim().isNotEmpty == true
                ? data['targetBusinessName'].toString()
                : data['title']?.toString().trim().isNotEmpty == true
                    ? data['title'].toString()
                    : 'Euro Habesha';

    final description =
        data['description']?.toString().trim().isNotEmpty == true
            ? data['description'].toString()
            : data['body']?.toString() ?? '';

    final promotion = data['promotion']?.toString().trim().isNotEmpty == true
        ? data['promotion'].toString()
        : data['discountText']?.toString() ?? '';

    final promoCode = data['promoCode']?.toString() ?? '';

    final imageUrl = data['imageUrl']?.toString() ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 35,
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 440,
          maxHeight: 680,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: darkGreen,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: gold.withValues(alpha: 0.75),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 270,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _imagePlaceholder();
                          },
                        )
                      : _imagePlaceholder(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          darkGreen.withValues(
                            alpha: 0.95,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SPONSORED',
                      style: TextStyle(
                        color: darkGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: Colors.black.withValues(
                      alpha: 0.65,
                    ),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  4,
                  22,
                  22,
                ),
                child: Column(
                  children: [
                    Text(
                      businessName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (promotion.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        promotion,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (promoCode.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cardGreen,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: gold.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Text(
                          'CODE: $promoCode',
                          style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openOffer(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: darkGreen,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'View Offer',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Maybe later',
                        style: TextStyle(
                          color: Colors.white60,
                        ),
                      ),
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

  Widget _imagePlaceholder() {
    return Container(
      color: cardGreen,
      child: const Center(
        child: Icon(
          Icons.campaign_outlined,
          color: gold,
          size: 70,
        ),
      ),
    );
  }
}
