import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewPromptService {
  static const String _promptedKey = 'review_prompt_shown_v1';

  static Future<void> maybeShowReviewPrompt(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) ?? false) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final shouldOpenStore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF004D40),
        title: const Text('Enjoying Euro Habesha?', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        content: const Text('Rate us on the store and help the community grow.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rate Us', style: TextStyle(color: Color(0xFF061E12), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldOpenStore != true) {
      return;
    }

    final review = InAppReview.instance;
    if (await review.isAvailable()) {
      await review.requestReview();
    } else {
      await review.openStoreListing();
    }
    await prefs.setBool(_promptedKey, true);
  }
}
