import 'package:flutter/material.dart';

class AuthComponents {
  static void showAuthBottomSheet(BuildContext context) {
    const Color cardGreen = Color(0xFF004D40);
    const Color primaryGold = Color(0xFFFFD700);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: cardGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ሎጎ (በአዶ የተወከለ)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryGold, width: 1.5),
                ),
                child: const Icon(Icons.public, color: primaryGold, size: 40),
              ),
              const SizedBox(height: 20),
              
              const Text(
                'Join Euro Habesha',
                style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              const Text(
                'Create an account to post,\nmessage, and connect with the\ncommunity.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 30),

              // ── Google Button ──
              _buildAuthButton(
                icon: Icons.g_mobiledata, 
                label: 'Continue with Google', 
                bgColor: Colors.white, 
                textColor: Colors.black, 
                iconColor: Colors.black,
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // ── Apple Button ──
              _buildAuthButton(
                icon: Icons.apple, 
                label: 'Continue with Apple', 
                bgColor: Colors.black, 
                textColor: Colors.white, 
                iconColor: Colors.white,
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // ── Email Button ──
              _buildAuthButton(
                icon: Icons.email, 
                label: 'Sign Up with Email', 
                bgColor: primaryGold, 
                textColor: Colors.black, 
                iconColor: Colors.black,
                onTap: () {},
              ),
              const SizedBox(height: 25),

              // ── Maybe Later ──
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAuthButton({
    required IconData icon, 
    required String label, 
    required Color bgColor, 
    required Color textColor, 
    required Color iconColor,
    required VoidCallback onTap
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
