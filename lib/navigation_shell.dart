import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'home_screen.dart';
import 'jobs_screen.dart';
import 'chat_screen.dart';
import 'market_screen.dart';
import 'profile_screen.dart';
import 'registration_screen.dart';
import 'admin_post_page.dart';
import 'session_state.dart';
import 'access_control.dart';
import 'events_screen.dart';
import 'catering_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  Timer? _guestPromptTimer;
  bool _hasShownGuestPrompt = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _scheduleGuestPrompt();
  }

  @override
  void dispose() {
    _guestPromptTimer?.cancel();
    super.dispose();
  }

  void _scheduleGuestPrompt() {
    final hasAuthSession = FirebaseAuth.instance.currentUser != null;
    if (!SessionState.isGuest || hasAuthSession) return;
    _guestPromptTimer?.cancel();
    _guestPromptTimer = Timer(const Duration(seconds: 5), () {
      final stillHasAuthSession = FirebaseAuth.instance.currentUser != null;
      if (!mounted || _hasShownGuestPrompt || !SessionState.isGuest || stillHasAuthSession) return;
      _hasShownGuestPrompt = true;
      _showCreateAccountPrompt();
    });
  }

  void _showCreateAccountPrompt() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF061E12),
          titlePadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  'Create Free Account',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close, color: Colors.white70),
              ),
            ],
          ),
          content: const Text(
            'Create a free account to access this service.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Maybe later', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: const Color(0xFF061E12),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistrationScreen()),
                );
              },
              child: const Text('Create Free Account'),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(
        onOpenSearch: () => _switchTab(1),
        onOpenEvents: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          );
        },
        onOpenMarket: () => _switchTab(3),
      ),
      const JobsScreen(searchOnly: true),
      const ChatScreen(),
      const MarketScreen(),
      const ProfileScreen(),
    ];
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _selectDrawerTab(int index) {
    Navigator.of(context).pop();
    _switchTab(index);
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFF59E0B)),
      title: Text(label, style: const TextStyle(color: Color(0xFFF5C542))),
      onTap: onTap,
    );
  }

  void _openAddPostSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E2E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create & Publish',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: Color(0xFFF59E0B)),
                  title: const Text('Open Publishing Center', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Jobs, events, and announcements', style: TextStyle(color: Colors.white60)),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final navigator = Navigator.of(context);
                    final canOpen = await AccessControl.ensureAdminAccess(
                      context,
                      actionLabel: 'Open Admin Panel',
                    );
                    if (!canOpen || !mounted) return;
                    navigator.push(
                      MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.work_outline, color: Color(0xFFF59E0B)),
                  title: const Text('Open Jobs & Services', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Post or browse jobs', style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _switchTab(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_menu, color: Color(0xFFF59E0B)),
                  title: const Text('Open Catering Services', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Business profiles, menus, and order requests', style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CateringScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0A2418),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF123222), Color(0xFF0A2418)]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF081B12),
                      border: Border.all(color: const Color(0xFFF5C542), width: 1.2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/branding/euro_habesha_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.brightness_5_outlined,
                          color: Color(0xFFF5C542),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'EURO ',
                          style: GoogleFonts.cinzel(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        TextSpan(
                          text: 'HABESHA',
                          style: GoogleFonts.cinzel(
                            color: const Color(0xFFF5C542),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => _selectDrawerTab(0),
            ),
            _drawerItem(
              icon: Icons.work_outline,
              label: 'Jobs & Services',
              onTap: () => _selectDrawerTab(1),
            ),
            _drawerItem(
              icon: Icons.chat_bubble_outline,
              label: 'Messages',
              onTap: () => _selectDrawerTab(2),
            ),
            _drawerItem(
              icon: Icons.storefront_outlined,
              label: 'Market',
              onTap: () => _selectDrawerTab(3),
            ),
            _drawerItem(
              icon: Icons.restaurant_menu,
              label: 'Catering Services',
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CateringScreen()),
                );
              },
            ),
            _drawerItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => _selectDrawerTab(4),
            ),
            const Divider(color: Colors.white24, height: 20),
            _drawerItem(
              icon: Icons.work_outline,
              label: 'Jobs & Services',
              onTap: () => _selectDrawerTab(1),
            ),
            _drawerItem(
              icon: Icons.storefront_outlined,
              label: 'Market',
              onTap: () => _selectDrawerTab(3),
            ),
            _drawerItem(
              icon: Icons.campaign_outlined,
              label: 'Publishing Center',
              onTap: () async {
                Navigator.of(context).pop();
                final navigator = Navigator.of(context);
                final canOpen = await AccessControl.ensureAdminAccess(
                  context,
                  actionLabel: 'Open Admin Panel',
                );
                if (!canOpen || !mounted) return;
                navigator.push(
                  MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: _buildScreens(),
            ),
            if (_currentIndex != 0)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 6),
                    child: Material(
                      color: const Color(0xFF0A2418).withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: _openDrawer,
                        icon: const Icon(Icons.menu, color: Color(0xFFF5C542)),
                        tooltip: 'Menu',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddPostSheet,
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: const Color(0xFF061E12),
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        maintainBottomViewPadding: true,
        child: BottomNavigationBar(
          currentIndex: _currentIndex <= 4 ? _currentIndex : 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF0A2418),
          selectedItemColor: const Color(0xFFF59E0B),
          unselectedItemColor: Colors.white70,
          onTap: _switchTab,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Jobs'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), activeIcon: Icon(Icons.storefront), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
