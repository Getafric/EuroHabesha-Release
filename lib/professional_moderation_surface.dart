import 'package:flutter/material.dart';

/// Surface utilisable depuis une route ou une section du panneau admin.
/// EH_MODERATION_MATERIAL_V1
class ProfessionalModerationSurface extends StatelessWidget {
  const ProfessionalModerationSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      body: SafeArea(child: child),
    );
  }
}
