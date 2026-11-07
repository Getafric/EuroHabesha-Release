import 'l10n/app_ui.dart';

import 'package:flutter/material.dart';

import 'app_session.dart';
import 'promotion_settings.dart';

/// Explains the existing pause. Never bypasses or changes its server setting.
class PromotionPauseInfo extends StatelessWidget {
  final PromotionSettings settings;
  const PromotionPauseInfo({super.key, required this.settings});
  @override
  Widget build(BuildContext context) {
    final reason = !settings.requestsEnabled
        ? 'Les nouvelles demandes sont désactivées dans les réglages des promotions.'
        : settings.version != 1
        ? 'Cette configuration nécessite une version compatible de l’application.'
        : 'Le mode payant ou abonnement est activé dans la configuration. '
              'Ce formulaire gratuit ne peut pas envoyer de nouvelle demande dans ce mode.';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              color: Color(0xFFFFD700),
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            const AppText(
              'Vos demandes déjà envoyées restent conservées. '
              'L’historique reste accessible en haut de l’écran.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            if (AppSession.isSuperAdmin) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF061E12),
                ),
                icon: const Icon(Icons.tune),
                label: const AppText('Ouvrir les réglages'),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PromotionSettingsScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
