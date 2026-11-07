import 'l10n/app_ui.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPromptService {
  static const String _legacyPromptedKey = 'review_prompt_shown_v1';
  static const String _neverShowKey = 'review_prompt_never_show_v2';
  static const String _countKey = 'review_prompt_count_v2';
  static const String _lastShownKey = 'review_prompt_last_shown_v2';
  static const Duration _minimumInterval = Duration(days: 7);
  static bool _dialogInProgress = false;

  static Future<void> maybeShowReviewPrompt(BuildContext context) async {
    if (_dialogInProgress) return;
    _dialogInProgress = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Respect users who already tapped the review button in the old version.
      if ((prefs.getBool(_legacyPromptedKey) ?? false) ||
          (prefs.getBool(_neverShowKey) ?? false)) {
        return;
      }

      final count = prefs.getInt(_countKey) ?? 0;
      if (count >= 2) return;
      final lastMillis = prefs.getInt(_lastShownKey);
      if (lastMillis != null) {
        final lastShown = DateTime.fromMillisecondsSinceEpoch(lastMillis);
        if (DateTime.now().difference(lastShown) < _minimumInterval) return;
      }
      if (!context.mounted) return;

      // Count a prompt as soon as it is displayed, even when dismissed.
      await prefs.setInt(_countKey, count + 1);
      await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
      if (!context.mounted) return;

      final result = await showDialog<_ReviewChoice>(
        context: context,
        builder: (dialogContext) => const _ReviewDialog(),
      );
      if (result == _ReviewChoice.never) {
        await prefs.setBool(_neverShowKey, true);
        return;
      }
      if (result != _ReviewChoice.rate) return;

      // Do not prompt again after the user chooses the store/review action.
      await prefs.setBool(_legacyPromptedKey, true);
      final review = InAppReview.instance;
      try {
        if (await review.isAvailable()) {
          await review.requestReview();
        } else {
          await review.openStoreListing();
        }
      } catch (error) {
        debugPrint('Unable to open app review: $error');
      }
    } finally {
      _dialogInProgress = false;
    }
  }
}

enum _ReviewChoice { later, never, rate }

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  bool _neverShowAgain = false;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFFFD700);
    const darkGreen = Color(0xFF061E12);
    const cardGreen = Color(0xFF004D40);

    return AlertDialog(
      backgroundColor: cardGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: gold, width: 0.7),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      title: Column(
        children: [
          Image.asset(
            'assets/images/euro_habesha_logo.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.star_rounded, color: gold, size: 70),
          ),
          const SizedBox(height: 14),
          AppText(
            'review.title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
              fontSize: 23,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText(
            'review.message'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: darkGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(_ReviewChoice.rate),
              icon: const Icon(Icons.star_rounded),
              label: AppText(
                'review.rate_us'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pop(_neverShowAgain ? _ReviewChoice.never : _ReviewChoice.later),
            child: AppText(
              'review.later'.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: gold,
            checkColor: darkGreen,
            controlAffinity: ListTileControlAffinity.leading,
            title: const AppText(
              'Ne plus afficher ce message',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            value: _neverShowAgain,
            onChanged: (value) =>
                setState(() => _neverShowAgain = value ?? false),
          ),
        ],
      ),
    );
  }
}
