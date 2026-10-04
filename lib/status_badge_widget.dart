import 'package:flutter/material.dart';

class StatusBadgeWidget extends StatelessWidget {
  final bool isVerified;
  final String? subscriptionTier; // 'pro', 'vip', null
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    this.isVerified = false,
    this.subscriptionTier,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleanTier = subscriptionTier?.trim().toLowerCase();
    final hasPro = cleanTier == 'pro';
    final hasVip = cleanTier == 'vip';

    if (!isVerified && !hasPro && !hasVip) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (isVerified)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00E676).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: const Color(0xFF00E676).withValues(alpha: 0.5),
                  width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle,
                    color: const Color(0xFF00E676), size: compact ? 11 : 13),
                const SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    color: const Color(0xFF00E676),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (hasVip)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond,
                    color: const Color(0xFFFFD700), size: compact ? 11 : 13),
                const SizedBox(width: 3),
                Text(
                  'VIP',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else if (hasPro)
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 6 : 8, vertical: compact ? 2 : 3),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF64B5F6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium,
                    color: const Color(0xFF64B5F6), size: compact ? 11 : 13),
                const SizedBox(width: 3),
                Text(
                  'PRO',
                  style: TextStyle(
                    color: const Color(0xFF64B5F6),
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
