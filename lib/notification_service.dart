import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'navigation_shell.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handler intentionally lightweight. Foreground UI handling is done in app runtime.
}

class NotificationService {
  NotificationService._();

  static bool _initialized = false;
  static FirebaseMessaging? _messaging;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'euro_habesha_updates',
    'Euro Habesha Updates',
    description: 'Announcements, approvals, and new listings.',
    importance: Importance.high,
  );
  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (_initialized) return;

    if (!_isMessagingSupportedPlatform()) {
      _initialized = true;
      return;
    }

    _messaging ??= FirebaseMessaging.instance;
    final messaging = _messaging;
    if (messaging == null) {
      _initialized = true;
      return;
    }

    await _configureLocalNotifications();
    await _requestNotificationPermission();
    await _syncCurrentTokenToFirestore();

    FirebaseMessaging.onMessage.listen((message) async {
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageNavigation);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageNavigation(initialMessage);
    }

    messaging.onTokenRefresh.listen((_) async {
      await _syncCurrentTokenToFirestore();
    });

    FirebaseAuth.instance.authStateChanges().listen((_) async {
      await _syncCurrentTokenToFirestore();
    });

    _initialized = true;
  }

  static Future<void> ensurePermissionAndSync() async {
    if (!_initialized) return;
    if (!_isMessagingSupportedPlatform()) return;
    try {
      await _requestNotificationPermission();
      await _syncCurrentTokenToFirestore();
    } on MissingPluginException catch (error) {
      debugPrint('Notification messaging unavailable: $error');
    } catch (error) {
      debugPrint('Notification sync skipped: $error');
    }
  }

  static bool _isMessagingSupportedPlatform() {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  static Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>;
          _openInboxWithPayload(map);
        } catch (_) {
          _openInbox();
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> _requestNotificationPermission() async {
    final messaging = _messaging;
    if (messaging == null) return;

    NotificationSettings settings;
    try {
      settings = await messaging.getNotificationSettings();
    } on MissingPluginException {
      return;
    }
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      return;
    }

    final context = _navigatorKey?.currentContext;
    if (context != null) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF061E12),
            title: const Text('Enable Notifications', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Allow notifications to receive new jobs, approved posts, and important updates in real time.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Not now', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: const Color(0xFF061E12),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Continue'),
              ),
            ],
          );
        },
      );
    }

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
    } on MissingPluginException catch (_) {
      return;
    }
  }

  static Future<void> _syncCurrentTokenToFirestore() async {
    final messaging = _messaging;
    if (messaging == null) return;

    String? token;
    try {
      token = await messaging.getToken();
    } on MissingPluginException {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (token == null || token.isEmpty || user == null) return;

    await FirebaseFirestore.instance.collection('deviceTokens').doc(token).set({
      'uid': user.uid,
      'email': user.email ?? '',
      'platform': 'flutter',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title']?.toString() ?? 'Euro Habesha';
    final body = message.notification?.body ?? message.data['body']?.toString() ?? 'New update available.';
    final payload = jsonEncode(message.data);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  static void _handleRemoteMessageNavigation(RemoteMessage message) {
    _openInboxWithPayload(message.data);
  }

  static void _openInboxWithPayload(Map<String, dynamic> payload) {
    _openInbox();
  }

  static void _openInbox() {
    final navigatorState = _navigatorKey?.currentState;
    if (navigatorState == null) return;
    navigatorState.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationShell(initialIndex: 4)),
      (route) => false,
    );
  }
}
