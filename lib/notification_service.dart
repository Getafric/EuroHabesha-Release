import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'business_order_detail_screen.dart';
import 'cash_on_delivery_order_screen.dart';
import 'chat_screen.dart';
import 'admin_invitation_screen.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  GlobalKey<NavigatorState>? _navigatorKey;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'euro_habesha_high_importance',
    'Euro Habesha Notifications',
    description: 'Notifications importantes de Euro Habesha',
    importance: Importance.max,
  );

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;

    await _initializeLocalNotifications();
    await _requestPermission();
    await registerCurrentToken();

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(
      _saveToken,
      onError: (_) {},
    );

    await _foregroundSubscription?.cancel();
    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    await _openedSubscription?.cancel();
    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleMessageTap(initialMessage);
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload == null || payload.trim().isEmpty) {
          return;
        }

        _handleLocalPayload(payload);
      },
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> registerCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final token = await _messaging.getToken();

    if (token == null || token.trim().isEmpty) {
      return;
    }

    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || token.trim().isEmpty) {
      return;
    }

    final tokenId = _safeTokenId(token);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(tokenId)
        .set({
      'token': token,
      'platform': _platformName(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // On garde aussi l'ancien champ pour compatibilité avec le code existant.
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _safeTokenId(String token) {
    return token
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }

  String _platformName() {
    return ThemeData().platform.name;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;

    final title = notification?.title ??
        message.data['title']?.toString() ??
        'Euro Habesha';

    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    final payload = _buildPayload(message.data);

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  String _buildPayload(Map<String, dynamic> data) {
    final routeType = data['routeType']?.toString() ?? '';
    final resourceId = data['resourceId']?.toString() ??
        data['orderId']?.toString() ??
        data['chatId']?.toString() ??
        data['postId']?.toString() ??
        '';

    return '$routeType|$resourceId';
  }

  void _handleLocalPayload(String payload) {
    final parts = payload.split('|');

    final routeType = parts.isNotEmpty ? parts.first : '';
    final resourceId = parts.length > 1 ? parts[1] : '';

    _openDestination(
      routeType: routeType,
      resourceId: resourceId,
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;

    final routeType = data['routeType']?.toString() ?? '';

    final resourceId = data['resourceId']?.toString() ??
        data['orderId']?.toString() ??
        data['chatId']?.toString() ??
        data['postId']?.toString() ??
        '';

    _openDestination(
      routeType: routeType,
      resourceId: resourceId,
    );
  }

  void _openDestination({
    required String routeType,
    required String resourceId,
  }) {
    final navigator = _navigatorKey?.currentState;

    if (navigator == null) {
      return;
    }

    switch (routeType) {
      case 'sellerOrder':
        if (resourceId.isEmpty) {
          navigator.pushNamedAndRemoveUntil('/app', (route) => false);
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (_) => BusinessOrderDetailScreen(
              orderId: resourceId,
            ),
          ),
        );
        break;

      case 'buyerOrder':
        if (resourceId.isEmpty) {
          navigator.pushNamedAndRemoveUntil('/app', (route) => false);
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (_) => CashOnDeliveryOrderTrackingScreen(
              orderId: resourceId,
            ),
          ),
        );
        break;
      case 'chat':
      case 'message':
        if (resourceId.isEmpty) {
          navigator.pushNamedAndRemoveUntil('/app', (route) => false);
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              chatId: resourceId,
              title: 'Conversation',
            ),
          ),
        );
        break;
      case 'adminInvite':
        if (resourceId.isEmpty) {
          navigator.pushNamedAndRemoveUntil('/app', (route) => false);
          return;
        }

        navigator.push(
          MaterialPageRoute(
            builder: (_) => AdminInvitationScreen(
              invitationId: resourceId,
            ),
          ),
        );
        break;

      case 'home':
        navigator.pushNamedAndRemoveUntil('/app', (route) => false);
        break;

      default:
        navigator.pushNamedAndRemoveUntil('/app', (route) => false);
        break;
    }
  }
}
