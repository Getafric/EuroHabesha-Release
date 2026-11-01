import 'advertisement_request_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'nearby_screen.dart';
import 'business_screen.dart';
import 'appointment_notification_detail_screen.dart';
import 'dart:convert';
import 'dart:async';
import 'business_table_reservations_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'business_order_detail_screen.dart';
import 'cash_on_delivery_order_screen.dart';
import 'chat_screen.dart';
import 'admin_invitation_screen.dart';

import 'table_reservation_notification_detail_screen.dart';

/// Réception FCM et affichage local des notifications Euro Habesha.
/// IMPORTANT : l'envoi des notifications lors d'une réservation nécessite
/// un déclencheur serveur distinct (Cloud Functions, par exemple).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<void>? _authSubscription;
  String? _lastAuthUid;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'euro_habesha_high_importance',
    'Euro Habesha Notifications',
    description: 'Notifications importantes de Euro Habesha',
    importance: Importance.max,
  );

  // Canal séparé : les notifications existantes gardent leur configuration.
  static const AndroidNotificationChannel _restaurantChannel =
      AndroidNotificationChannel(
    'euro_habesha_restaurant_v1',
    'Euro Habesha - Restaurants',
    description: 'Nouvelles réservations et commandes',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('euro_habesha_notification'),
  );

  static const AndroidNotificationChannel _campaignChannel = AndroidNotificationChannel(
    'euro_habesha_local_offers_v1', 'Euro Habesha — Offres locales',
    description: 'Offres et découvertes locales choisies dans vos préférences',
    importance: Importance.defaultImportance, playSound: false,
  );

  Future<void> initialize({required GlobalKey<NavigatorState> navigatorKey}) async {
    _navigatorKey = navigatorKey;
    if (_initialized) return;
    _initialized = true;
    await _initializeLocalNotifications();
    await _requestPermission();
    await registerCurrentToken();
    _lastAuthUid = FirebaseAuth.instance.currentUser?.uid;
    await _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges()
        .asyncMap<void>((user) async {
      final uid = user?.uid;
      if (_lastAuthUid != null && _lastAuthUid != uid) {
        try { await _messaging.deleteToken(); } catch (_) { /* Rebind below. */ }
      }
      _lastAuthUid = uid;
      if (uid != null && FirebaseAuth.instance.currentUser?.uid == uid) {
        await registerCurrentToken();
      }
    }).listen((_) {}, onError: (_) {});

    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen(_saveToken, onError: (_) {});

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
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.trim().isNotEmpty) {
          _handleLocalPayload(payload);
        }
      },
    );
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_restaurantChannel);
    await androidPlugin?.createNotificationChannel(_campaignChannel);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> registerCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await _messaging.getToken();
    if (token == null || token.trim().isEmpty) return;
    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token.trim().isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('fcmTokens')
        .doc(_safeTokenId(token)).set({
      'token': token,
      'platform': _platformName(),
      'localCampaignsV1': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('registerLocalCampaignDevice').call({'token': token})
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Existing booking notifications work before campaign deployment too.
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> unregisterLocalCampaignDevice() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('registerLocalCampaignDevice')
          .call({'token': token, 'revoke': true})
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Signing out must remain possible if the network is unavailable.
    }
  }

  String _safeTokenId(String token) => token
      .replaceAll('/', '_').replaceAll('\\', '_').replaceAll('.', '_')
      .replaceAll('#', '_').replaceAll('[', '_').replaceAll(']', '_');

  String _platformName() => ThemeData().platform.name;

  bool _isRestaurantNotification(Map<String, dynamic> data) {
    final type = (data['routeType'] ?? data['type'] ?? '').toString();
    return type == 'tableReservation' ||
        type == 'restaurantReservation' ||
        type == 'reservation' ||
        type == 'sellerOrder';
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ?? 'Euro Habesha';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    final restaurant = _isRestaurantNotification(message.data);
    final campaign = message.data['routeType'] == 'localCampaign';
    final channel = campaign ? _campaignChannel : restaurant ? _restaurantChannel : _channel;

    BigPictureStyleInformation? picture;
    final imageUrl = message.data['campaignImageUrl']?.toString() ?? '';
    if (campaign && imageUrl.startsWith('https://firebasestorage.googleapis.com/')) {
      try {
        final bytes = await NetworkAssetBundle(Uri.parse(imageUrl)).load('')
            .timeout(const Duration(seconds: 5));
        if (bytes.lengthInBytes <= 8 * 1024 * 1024) {
          picture = BigPictureStyleInformation(ByteArrayAndroidBitmap(
              bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)));
        }
      } catch (_) {
        // The notification text is still shown when the image is unavailable.
      }
    }
    await _localNotifications.show(
      message.messageId?.hashCode ?? message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: campaign ? Importance.defaultImportance : Importance.max,
          priority: campaign ? Priority.defaultPriority : Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: picture,
          playSound: !campaign,
          sound: restaurant
              ? const RawResourceAndroidNotificationSound('euro_habesha_notification')
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !campaign,
        ),
      ),
      payload: _buildPayload(message.data),
    );
  }

  String _buildPayload(Map<String, dynamic> data) => jsonEncode(data);

  void _handleLocalPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        openNotification(Map<String, dynamic>.from(decoded));
        return;
      }
    } catch (_) {
      // Compatibilité avec les anciennes notifications au format type|id.
    }
    final parts = payload.split('|');
    openNotification({
      'routeType': parts.isNotEmpty ? parts[0] : '',
      'resourceId': parts.length > 1 ? parts[1] : '',
    });
  }

  void _handleMessageTap(RemoteMessage message) => openNotification(message.data);

  Future<void> openNotification(Map<String, dynamic> data) async {
    final routeType = (data['routeType'] ?? data['type'] ?? '').toString();
    final resourceId = (data['resourceId'] ?? data['reservationId'] ??
        data['orderId'] ?? data['chatId'] ?? data['postId'] ?? '').toString();
    // Un lancement à froid peut précéder le premier rendu du Navigator.
    for (var attempt = 0; attempt < 20 && _navigatorKey?.currentState == null; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) return;
    switch (routeType) {
      case 'advertisementRequest':
        if (!RegExp(r'^[A-Za-z0-9_-]{1,150}$').hasMatch(resourceId)) return;
        navigator.push(MaterialPageRoute(builder: (_) =>
          AdvertisementRequestStatusScreen(requestId: resourceId)));
        break;
      case 'localCampaign':
        final destination = (data['campaignDestination'] ?? '').toString();
        if (destination == 'business') {
          final id = (data['businessId'] ?? '').toString();
          if (!RegExp(r'^[A-Za-z0-9_-]{1,150}$').hasMatch(id)) return;
          try {
            final doc = await FirebaseFirestore.instance
                .collection('businesses').doc(id).get();
            if (!navigator.mounted) return;
            if (!doc.exists || !['published', 'approved']
                .contains(doc.data()?['status'])) {
              ScaffoldMessenger.of(navigator.context).showSnackBar(
                const SnackBar(content: Text('Ce commerce n’est plus disponible.')));
              return;
            }
            navigator.push(MaterialPageRoute(builder: (_) =>
                BusinessDetailScreen(businessData: normalizeBusinessForDetail(doc))));
          } catch (_) {
            if (!navigator.mounted) return;
            ScaffoldMessenger.of(navigator.context).showSnackBar(
              const SnackBar(content: Text('Impossible d’ouvrir ce commerce.')));
          }
        } else {
          final category = const {
            'nearbyRestaurants': 'Restaurants',
            'nearbyBusinesses': 'Commerces', 'nearbyEvents': 'Événements',
          }[destination];
          if (category == null) return;
          navigator.push(MaterialPageRoute(builder: (_) => NearbyScreen(
            initialCategory: category, useSavedCampaignCity: true)));
        }
        break;
      case 'appointment':
        final appointmentId = (data['appointmentId'] ?? resourceId).toString();
        final source = (data['sourceCollection'] ?? '').toString();
        final businessId = (data['businessId'] ?? '').toString();
        if (appointmentId.isEmpty || businessId.isEmpty ||
            !['businessSubmissions', 'jobSubmissions', 'businesses', 'jobs'].contains(source)) {
          return;
        }
        if (FirebaseAuth.instance.currentUser == null) {
          navigator.pushNamedAndRemoveUntil('/login', (_) => false);
          return;
        }
        navigator.push(MaterialPageRoute(builder: (_) =>
            AppointmentNotificationDetailScreen(
              businessId: businessId, sourceCollection: source,
              appointmentId: appointmentId,
            )));
        break;
      case 'tableReservation':
      case 'restaurantReservation':
      case 'reservation':
        final businessId = (data['businessId'] ?? '').toString();
        final source = (data['sourceCollection'] ?? '').toString();
        if (resourceId.isEmpty || businessId.isEmpty ||
            !['businessSubmissions', 'jobSubmissions'].contains(source)) {
          navigator.pushNamedAndRemoveUntil('/app', (_) => false);
          return;
        }
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          navigator.pushNamedAndRemoveUntil('/login', (_) => false);
          return;
        }
        try {
          final business = await FirebaseFirestore.instance
              .collection(source).doc(businessId).get();
          final owner = business.data();
          final isOwner = owner != null &&
              (owner['ownerId'] == user.uid || owner['submittedBy'] == user.uid);
          if (_navigatorKey?.currentState == null) return;
          if (isOwner) {
            navigator.push(MaterialPageRoute(builder: (_) =>
                BusinessTableReservationsScreen(
                    businessId: businessId, sourceCollection: source)));
          } else {
            navigator.push(MaterialPageRoute(builder: (_) =>
                TableReservationNotificationDetailScreen(
                    businessId: businessId,
                    sourceCollection: source,
                    reservationId: resourceId)));
          }
        } catch (error) {
          debugPrint('Notification réservation: $error');
          navigator.pushNamedAndRemoveUntil('/app', (_) => false);
        }
        break;
      case 'sellerOrder':
        if (resourceId.isNotEmpty) {
          navigator.push(MaterialPageRoute(builder: (_) =>
              BusinessOrderDetailScreen(orderId: resourceId)));
        }
        break;
      case 'buyerOrder':
        if (resourceId.isNotEmpty) {
          navigator.push(MaterialPageRoute(builder: (_) =>
              CashOnDeliveryOrderTrackingScreen(orderId: resourceId)));
        }
        break;
      case 'chat':
      case 'message':
        if (resourceId.isNotEmpty) {
          navigator.push(MaterialPageRoute(builder: (_) =>
              ChatThreadScreen(chatId: resourceId, title: 'Conversation')));
        }
        break;
      case 'adminInvite':
        if (resourceId.isNotEmpty) {
          navigator.push(MaterialPageRoute(builder: (_) =>
              AdminInvitationScreen(invitationId: resourceId)));
        }
        break;
      default:
        navigator.pushNamedAndRemoveUntil('/app', (_) => false);
    }
  }
}
