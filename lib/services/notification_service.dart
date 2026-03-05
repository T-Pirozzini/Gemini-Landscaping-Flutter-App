import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gemini_landscaping_app/screens/utility_screens/equipment_detail_page.dart';

/// Handles FCM token management, permission requests, and notification display.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  /// Global navigator key — set this on MaterialApp to enable notification navigation.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Initialize notifications — call once after Firebase.initializeApp().
  Future<void> initialize() async {
    // Request permission (iOS requires explicit permission, Android 13+ too)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return; // User denied — nothing we can do
    }

    // Initialize local notifications for foreground display
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'equipment_alerts',
      'Equipment Alerts',
      description: 'Notifications for equipment issues and repairs',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Save FCM token to Firestore
    await _saveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((_) => _saveToken());

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if the app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure navigator is ready
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _navigateToEquipment(initialMessage.data['equipmentId']),
      );
    }
  }

  /// Save the current FCM token to the user's Firestore document.
  Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  /// Display a local notification when a message arrives in the foreground.
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'equipment_alerts',
          'Equipment Alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['equipmentId'],
    );
  }

  /// Handle when user taps a notification that opened the app from background.
  void _handleNotificationOpen(RemoteMessage message) {
    _navigateToEquipment(message.data['equipmentId']);
  }

  /// Handle when user taps a local notification (foreground).
  void _onNotificationTap(NotificationResponse response) {
    _navigateToEquipment(response.payload);
  }

  /// Navigate to the equipment detail page for the given equipment ID.
  void _navigateToEquipment(String? equipmentId) {
    if (equipmentId == null || equipmentId.isEmpty) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => EquipmentDetailPage(equipmentId: equipmentId),
      ),
    );
  }
}
