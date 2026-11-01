import 'package:flutter/material.dart';

/// Decorative plan badge. Never a paid identity-verification checkmark.
class ProfessionalMembershipBadge extends StatelessWidget {
  const ProfessionalMembershipBadge({
    super.key,
    required this.tier,
    this.size = 64,
  });
  final String tier;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Illustration de la formule ${tier.toUpperCase()}',
      child: CustomPaint(
        painter: _MembershipBadgePainter(tier),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            tier == 'vip' ? Icons.diamond_outlined : Icons.star_rounded,
            color: tier == 'vip'
                ? const Color(0xFFFFD700)
                : const Color(0xFF173D32),
            size: size * .49,
          ),
        ),
      ),
    );
  }
}

class _MembershipBadgePainter extends CustomPainter {
  const _MembershipBadgePainter(this.tier);
  final String tier;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    final path = Path();
    if (tier == 'silver') {
      path.addOval(rect.deflate(2));
    } else if (tier == 'gold') {
      path.moveTo(w * .5, 2);
      path.lineTo(w - 2, h * .25);
      path.lineTo(w - 2, h * .75);
      path.lineTo(w * .5, h - 2);
      path.lineTo(2, h * .75);
      path.lineTo(2, h * .25);
      path.close();
    } else {
      path.moveTo(w * .29, 2);
      path.lineTo(w * .71, 2);
      path.lineTo(w - 2, h * .34);
      path.lineTo(w * .5, h - 2);
      path.lineTo(2, h * .34);
      path.close();
    }
    final colors = tier == 'silver'
        ? const [Color(0xFFF3F5F7), Color(0xFF6F7D87), Color(0xFFDEE4E8)]
        : tier == 'gold'
        ? const [Color(0xFFFFEE96), Color(0xFFB98300), Color(0xFFFFD700)]
        : const [Color(0xFF08735D), Color(0xFF061E12)];
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(rect),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = tier == 'silver'
            ? const Color(0xFFDEE4E8)
            : const Color(0xFFFFD700),
    );
  }

  @override
  bool shouldRepaint(covariant _MembershipBadgePainter oldDelegate) =>
      oldDelegate.tier != tier;
}
