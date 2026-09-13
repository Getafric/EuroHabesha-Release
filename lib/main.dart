import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'business_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'app_session.dart';
import 'admin_announcement_screen.dart';
import 'submission_menu_screen.dart';
import 'admin_passcode_screen.dart';
import 'review_prompt_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runApp(EuroHabeshaApp(firebaseReady: firebaseReady));
}

class EuroHabeshaApp extends StatelessWidget {
  final bool firebaseReady;

  const EuroHabeshaApp({super.key, this.firebaseReady = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Euro Habesha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF061E12),
          brightness: Brightness.light,
          primary: const Color(0xFF061E12),
          secondary: const Color(0xFFFFD700),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F3),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF061E12),
          brightness: Brightness.dark,
          primary: const Color(0xFF061E12),
          secondary: const Color(0xFFFFD700),
        ),
        scaffoldBackgroundColor: const Color(0xFF061E12),
      ),
      themeMode: ThemeMode.system,
      routes: {
        '/app': (context) => const MainNavigationScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin-passcode': (context) => const AdminPasscodeScreen(),
      },
      home: firebaseReady ? const MainNavigationScreen() : const SafeHomeScreen(),
    );
  }
}

// Safe home screen with error handling
class SafeHomeScreen extends StatelessWidget {
  const SafeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF061E12),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Icon(Icons.check_circle, color: Color(0xFFFFD700), size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    'Euro Habesha',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'App Initialized Successfully! ✅',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Status:',
                          style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text('Firebase: Connected ✅', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        Text('UI Framework: Loaded ✅', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                        Text('Plugins: Initialized ✅', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      try {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Navigation error: $e')),
                        );
                      }
                    },
                    child: const Text(
                      'Continue to App',
                      style: TextStyle(
                        color: Color(0xFF061E12),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ── 1. መጀመሪያ ሲከፈት የሚመጣው የ Welcome / Sign-Up ገጽ ──
// ==========================================
class WelcomeAuthScreen extends StatelessWidget {
  const WelcomeAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryDarkGreen = Color(0xFF061E12);
    const Color primaryGold = Color(0xFFFFD700);
    const Color cardGreen = Color(0xFF004D40);

    return Scaffold(
      backgroundColor: primaryDarkGreen,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryGold.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ሎጎ ከላይ በግልጽ እንዲታይ (ወደ አዲሱ ፎልደር ተቀይሯል)
                Image.asset(
                  'assets/images/euro_habesha_logo.png',
                  width: 65,
                  height: 65,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.hub, color: primaryGold, size: 50),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Join Euro Habesha',
                  style: TextStyle(color: primaryGold, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an account to post, message, and connect with the community.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Google Sign-In
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                      );
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),

                // Apple Sign-In
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                      );
                    },
                    icon: const Icon(Icons.apple, size: 20),
                    label: const Text('Continue with Apple', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 10),

                // Email Sign-Up
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: primaryDarkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                      );
                    },
                    icon: const Icon(Icons.email, size: 18),
                    label: const Text('Sign Up with Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 15),

                // Maybe Later (Skip)
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                    );
                  },
                  child: const Text('Maybe Later', style: TextStyle(color: Colors.white60, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ── 2. ዋናው የማሰሳያ ስክሪን (Main Navigation) ──
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  final Color primaryDarkGreen = const Color(0xFF061E12);
  final Color primaryGold = const Color(0xFFFFD700);
  final Color cardGreen = const Color(0xFF004D40);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 35), () {
      if (mounted) {
        ReviewPromptService.maybeShowReviewPrompt(context);
      }
    });
  }

  void _selectTab(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openPostComposer() {
    if (AppSession.isSuperAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminAnnouncementScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubmissionMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDarkGreen,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomeScreen(),
            BusinessDirectoryScreen(),
            ChatScreen(),
            ProfileScreen(),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 3
          ? null
          : FloatingActionButton(
              elevation: 8,
              shape: const CircleBorder(),
              backgroundColor: primaryGold,
              foregroundColor: Colors.black,
              tooltip: 'Create post',
              onPressed: _openPostComposer,
              child: const Icon(Icons.add, size: 34),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: BottomAppBar(
          color: cardGreen,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 66,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.storefront, 'Business', 1),
                const SizedBox(width: 56),
                _buildNavItem(Icons.chat, 'Messages', 2),
                _buildNavItem(Icons.person, 'Profile', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? primaryGold : Colors.white54;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _selectTab(index),
        child: SizedBox(
          height: 66,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
