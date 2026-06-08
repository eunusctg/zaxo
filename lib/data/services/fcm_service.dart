/// Service class for Firebase Cloud Messaging (FCM) push notifications.
///
/// Handles permission requests, token management, foreground and background
/// message handling, local notification display, and notification storage
/// to Firebase Realtime Database.
library;

import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:uuid/uuid.dart';

/// Background message handler — must be a top-level function.
///
/// This is invoked when a message arrives while the app is in the background
/// or terminated. It displays a local notification for data-only messages.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialise Firebase for background isolate.
  // Note: Firebase must already be initialised in main() before any
  // background isolates are spawned.
  await FirebaseMessaging.instance.getInitialMessage();

  // Show a local notification for data messages.
  final notification = message.notification;
  final title = notification?.title ?? 'Zaxo';
  final body = notification?.body ?? 'You have a new message';

  const androidDetails = AndroidNotificationDetails(
    'zaxo_messages',
    'Messages',
    channelDescription: 'Incoming chat messages',
    importance: Importance.max,
    priority: Priority.high,
  );
  const platformDetails = NotificationDetails(android: androidDetails);

  await FlutterLocalNotificationsPlugin().show(
    message.hashCode,
    title,
    body,
    platformDetails,
    payload: jsonEncode(message.data),
  );
}

/// Manages FCM push notifications for Zaxo.
///
/// Responsibilities:
/// - Request notification permissions
/// - Obtain and refresh the FCM registration token
/// - Handle foreground messages and display local notifications
/// - Subscribe / unsubscribe to FCM topics
/// - Store notification records in Firebase Realtime Database
/// - Send notifications via FCM HTTP API (server key)
class FcmService {
  // ── Constants ──────────────────────────────────────────────────────────

  /// FCM server key for sending push notifications via the HTTP v1 API.
  ///
  /// **Security note**: In production, notification sending should be done
  /// from a server-side function. Embedding the server key in the client
  /// is acceptable only for development / prototyping.
  static const String _fcmServerKey =
      'BB23O7Kukqu0Lmd3EIR06SclfmvSEuA7A1NKwvnjdsOV9zNGtEUzvYugIH-MKHQBQLF3V25k61x-2x1w-kwIU7w';

  /// Database reference for stored notifications.
  static const String _notificationsPath = 'notifications';

  // ── Instance state ─────────────────────────────────────────────────────

  FcmService({
    FirebaseMessaging? messaging,
    FirebaseDatabase? database,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _database = database ?? FirebaseDatabase.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FirebaseDatabase _database;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final _uuid = const Uuid();

  String? _token;

  /// The current FCM registration token, or `null` if not yet obtained.
  String? get token => _token;

  // ── Initialization ─────────────────────────────────────────────────────

  /// Initializes the FCM service.
  ///
  /// This should be called once during app startup (after Firebase init).
  /// It performs:
  /// 1. Local notification plugin setup (Android channel + default config)
  /// 2. Notification permission request (Android 13+, iOS)
  /// 3. FCM token retrieval
  /// 4. Foreground message listener registration
  /// 5. Background message handler registration
  /// 6. Token refresh listener
  Future<void> initialize() async {
    try {
      // ── 1. Setup local notifications ────────────────────────────────
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android notification channels.
      await _createNotificationChannels();

      // ── 2. Request permissions ──────────────────────────────────────
      await _requestPermissions();

      // ── 3. Get token ────────────────────────────────────────────────
      _token = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_token');

      // ── 4. Foreground message handler ───────────────────────────────
      // Enable foreground notifications on iOS.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // ── 5. Background handler ───────────────────────────────────────
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // ── 6. Token refresh ────────────────────────────────────────────
      _messaging.onTokenRefresh.listen((newToken) {
        _token = newToken;
        debugPrint('📱 FCM Token refreshed: $newToken');
        // TODO: Update the token in the user's database record.
      });
    } catch (e) {
      debugPrint('❌ FCM initialization error: $e');
    }
  }

  // ── Permissions ────────────────────────────────────────────────────────

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } else {
      // On Android 13+, requestPermission shows the system dialog.
      await _messaging.requestPermission();
    }
  }

  // ── Notification Channels ──────────────────────────────────────────────

  Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    const channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'zaxo_messages',
        'Messages',
        description: 'Incoming chat messages',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'zaxo_calls',
        'Calls',
        description: 'Incoming voice and video calls',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'zaxo_statuses',
        'Statuses',
        description: 'New status updates from contacts',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'zaxo_groups',
        'Groups',
        description: 'Group chat messages',
        importance: Importance.high,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // ── Foreground Message Handler ─────────────────────────────────────────

  /// Handles a message received while the app is in the foreground.
  ///
  /// For notification messages, a local notification is displayed.
  /// The notification data is also stored in the Realtime Database.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Zaxo',
        body: notification.body ?? '',
        data: data,
      );
    } else if (data.isNotEmpty) {
      // Data-only message — display as a local notification.
      _showLocalNotification(
        title: data['title'] as String? ?? 'Zaxo',
        body: data['body'] as String? ?? 'You have a new message',
        data: data,
      );
    }

    // Persist to Realtime Database.
    _storeNotification(message);
  }

  // ── Local Notifications ────────────────────────────────────────────────

  /// Shows a local notification with the given content.
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'zaxo_messages',
      'Messages',
      channelDescription: 'Incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      title.hashCode ^ body.hashCode,
      title,
      body,
      platformDetails,
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Callback when a local notification is tapped by the user.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('📲 Notification tapped: $data');
      // TODO: Navigate to the relevant chat / call screen based on data.
    } catch (e) {
      debugPrint('❌ Error parsing notification payload: $e');
    }
  }

  // ── Token ──────────────────────────────────────────────────────────────

  /// Returns the current FCM token, requesting a new one if needed.
  Future<String?> getToken() async {
    _token ??= await _messaging.getToken();
    return _token;
  }

  // ── Topics ─────────────────────────────────────────────────────────────

  /// Subscribes the device to the given FCM [topic].
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📡 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribes the device from the given FCM [topic].
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('📡 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
    }
  }

  // ── Send Notification ──────────────────────────────────────────────────

  /// Sends a push notification to a specific device via the FCM HTTP API.
  ///
  /// [token] – The target device's FCM registration token.
  /// [title] – Notification title.
  /// [body] – Notification body text.
  /// [data] – Optional data payload delivered to the app.
  ///
  /// The notification is also stored in Firebase Realtime Database under
  /// `notifications/{notificationId}`.
  ///
  /// Returns `true` if the notification was sent successfully.
  Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final now = DateTime.now().toIso8601String();

      // ── Store in Realtime Database ──────────────────────────────────
      final notificationData = {
        'id': notificationId,
        'token': token,
        'title': title,
        'body': body,
        'data': data,
        'createdAt': now,
        'status': 'sent',
      };

      await _database
          .ref(_notificationsPath)
          .child(notificationId)
          .set(notificationData);

      // ── Send via FCM HTTP API ───────────────────────────────────────
      // Using the legacy HTTP API for simplicity. For production, use
      // the FCM HTTP v1 API with OAuth2 tokens from a server.
      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
        );
        request.headers.set('Authorization', 'key=$_fcmServerKey');
        request.headers.set('Content-Type', 'application/json');

        final payload = {
          'to': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
          },
        };

        request.write(jsonEncode(payload));
        final response = await request.close();

        if (response.statusCode == 200) {
          debugPrint('✅ Notification sent to $token');
          return true;
        } else {
          debugPrint('❌ FCM error: ${response.statusCode}');
          await _database
              .ref(_notificationsPath)
              .child(notificationId)
              .update({'status': 'failed'});
          return false;
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('❌ Failed to send notification: $e');
      return false;
    }
  }

  // ── Store Notification ─────────────────────────────────────────────────

  /// Persists a received [RemoteMessage] to the Realtime Database.
  Future<void> _storeNotification(RemoteMessage message) async {
    try {
      final notificationId = message.messageId ?? _uuid.v4();
      final notification = message.notification;
      final data = message.data;

      await _database.ref(_notificationsPath).child(notificationId).set({
        'id': notificationId,
        'title': notification?.title,
        'body': notification?.body,
        'data': data,
        'receivedAt': DateTime.now().toIso8601String(),
        'status': 'received',
      });
    } catch (e) {
      debugPrint('❌ Failed to store notification: $e');
    }
  }
}
