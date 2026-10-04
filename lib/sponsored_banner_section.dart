import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TopSponsoredBanner extends StatefulWidget {
  const TopSponsoredBanner({super.key});

  @override
  State<TopSponsoredBanner> createState() => _TopSponsoredBannerState();
}

class _TopSponsoredBannerState extends State<TopSponsoredBanner> {
  static const _darkGreen = Color(0xFF061E12);
  static const _cardGreen = Color(0xFF073B2B);
  static const _gold = Color(0xFFFFD700);

  final PageController _pageController = PageController();

  Timer? _autoSlideTimer;
  int _currentPage = 0;

  final Set<String> _dismissedBannerIds = {};
  String _boostText(
    BuildContext context, {
    required String fr,
    required String en,
    required String de,
    required String it,
    required String am,
    required String ti,
  }) {
    switch (context.locale.languageCode) {
      case 'fr':
        return fr;
      case 'de':
        return de;
      case 'it':
        return it;
      case 'am':
        return am;
      case 'ti':
        return ti;
      default:
        return en;
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  bool _isActive(Map<String, dynamic> data) {
    final now = DateTime.now();

    final startsAt = data['startsAt'] as Timestamp?;
    final endsAt = data['endsAt'] as Timestamp?;

    if (startsAt != null && now.isBefore(startsAt.toDate())) {
      return false;
    }

    if (endsAt != null && now.isAfter(endsAt.toDate())) {
      return false;
    }

    return true;
  }

  void _startAutoSlide(int count) {
    _autoSlideTimer?.cancel();

    if (count <= 1) return;

    _autoSlideTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!mounted || !_pageController.hasClients) return;

        final nextPage = (_currentPage + 1) % count;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _showBannerDetails(
    Map<String, dynamic> data,
  ) {
    final businessName =
        data['businessName']?.toString().trim().isNotEmpty == true
            ? data['businessName'].toString()
            : data['targetBusinessName']?.toString().trim().isNotEmpty == true
                ? data['targetBusinessName'].toString()
                : data['title']?.toString().trim().isNotEmpty == true
                    ? data['title'].toString()
                    : 'Offre spéciale';

    final description =
        data['description']?.toString().trim().isNotEmpty == true
            ? data['description'].toString()
            : data['body']?.toString() ?? '';

    final promotion = data['promotion']?.toString().trim().isNotEmpty == true
        ? data['promotion'].toString()
        : data['discountText']?.toString() ?? '';

    final promoCode = data['promoCode']?.toString() ?? '';
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: _gold,
            ),
          ),
          title: Text(
            businessName,
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              if (promotion.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  promotion,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
              if (promoCode.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Code : $promoCode',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Fermer',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('sponsoredBanners')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final banners = snapshot.data!.docs
            .where((doc) {
              return _isActive(doc.data()) &&
                  !_dismissedBannerIds.contains(doc.id);
            })
            .take(4)
            .toList();

        if (banners.isEmpty) {
          _autoSlideTimer?.cancel();

          return Container(
            color: _darkGreen,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SizedBox(
              height: 150,
              child: _buildBoostBanner(),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startAutoSlide(banners.length);
          }
        });

        return Container(
          color: _darkGreen,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (index) {
                    if (!mounted) return;

                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final banner = banners[index];

                    return _buildBanner(
                      banner.id,
                      banner.data(),
                    );
                  },
                ),
              ),
              if (banners.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    banners.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 250,
                      ),
                      width: index == _currentPage ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                      ),
                      decoration: BoxDecoration(
                        color: index == _currentPage ? _gold : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBanner(
    String bannerId,
    Map<String, dynamic> data,
  ) {
    final businessName =
        data['businessName']?.toString().trim().isNotEmpty == true
            ? data['businessName'].toString()
            : data['title']?.toString().trim().isNotEmpty == true
                ? data['title'].toString()
                : 'Boostez votre visibilité';

    final description =
        data['description']?.toString().trim().isNotEmpty == true
            ? data['description'].toString()
            : 'Faites découvrir votre activité à la communauté.';

    final promotion = data['promotion']?.toString().trim() ?? '';

    final imageUrl = data['imageUrl']?.toString().trim() ?? '';

    return GestureDetector(
      onTap: () => _showBannerDetails(data),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _cardGreen,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _gold.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const ColoredBox(
                    color: _cardGreen,
                  );
                },
              )
            else
              const ColoredBox(
                color: _cardGreen,
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xF0000000),
                    Color(0xB3000000),
                    Color(0x33000000),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                46,
                10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.campaign_rounded,
                        color: _gold,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SPONSORED',
                        style: TextStyle(
                          color: _gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    businessName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          promotion.isNotEmpty ? promotion : 'En savoir plus',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 7,
              right: 7,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Fermer',
                  iconSize: 18,
                  onPressed: () {
                    setState(() {
                      _dismissedBannerIds.add(bannerId);

                      if (_currentPage > 0) {
                        _currentPage--;
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoostBanner() {
    final title = _boostText(
      context,
      fr: 'Boostez votre visibilité',
      en: 'Boost your visibility',
      de: 'Steigern Sie Ihre Sichtbarkeit',
      it: 'Aumenta la tua visibilità',
      am: 'ታይነትዎን ያሳድጉ',
      ti: 'ተራእዩነትኩም ኣዕብዩ',
    );

    final subtitle = _boostText(
      context,
      fr: 'Avec Euro Habesha',
      en: 'With Euro Habesha',
      de: 'Mit Euro Habesha',
      it: 'Con Euro Habesha',
      am: 'ከ Euro Habesha ጋር',
      ti: 'ምስ Euro Habesha',
    );

    final description = _boostText(
      context,
      fr: 'Faites découvrir votre activité à toute la communauté.',
      en: 'Show your business to the whole community.',
      de: 'Präsentieren Sie Ihr Unternehmen der ganzen Community.',
      it: 'Fai conoscere la tua attività a tutta la comunità.',
      am: 'ንግድዎን ለመላው ማህበረሰብ ያስተዋውቁ።',
      ti: 'ንግድኹም ንብዘሎ ማሕበረሰብ ኣፍልጡ።',
    );

    final buttonText = _boostText(
      context,
      fr: 'En savoir plus',
      en: 'Learn more',
      de: 'Mehr erfahren',
      it: 'Scopri di più',
      am: 'ተጨማሪ ይወቁ',
      ti: 'ተወሳኺ ፍለጡ',
    );

    final sponsoredText = _boostText(
      context,
      fr: 'SPONSORISÉ',
      en: 'SPONSORED',
      de: 'GESPONSERT',
      it: 'SPONSORIZZATO',
      am: 'ስፖንሰር',
      ti: 'ስፖንሰር',
    );

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/advertisement-request',
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _gold.withValues(alpha: 0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B513D),
                    Color(0xFF073B2B),
                    Color(0xFF061E12),
                    Color(0xFF020C08),
                  ],
                ),
              ),
            ),
            Positioned(
              right: -18,
              top: -20,
              child: Icon(
                Icons.campaign_rounded,
                size: 165,
                color: _gold.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              right: 20,
              top: 17,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  sponsoredText,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: _gold,
                    size: 18,
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
