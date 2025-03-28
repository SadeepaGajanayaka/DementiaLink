// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static FirebaseMessaging? _messaging;
  static FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _fallbackMode = false;

  // Getter for messaging with fallback handling
  static FirebaseMessaging get messaging {
    if (_fallbackMode) {
      throw Exception('Firebase is in fallback mode - messaging not available');
    }
    return _messaging!;
  }

  // Initialize Firebase
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      print("FirebaseService: Attempting to initialize Firebase");

      // Initialize Firebase
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;

      // Set up local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      await _createNotificationChannel();

      // Request permission for iOS
      if (_messaging != null) {
        await _messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      }

      _initialized = true;
      _fallbackMode = false;
      print("FirebaseService: Firebase initialized successfully");

    } catch (e) {
      print("FirebaseService: Failed to initialize Firebase - $e");
      print("FirebaseService: Continuing in fallback mode without Firebase");
      _fallbackMode = true;
      _initialized = true;
    }
  }

  // Create notification channel for Android
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'task_reminders', // id
      'Task Reminders', // title
      description: 'Notifications for task reminders', // description
      importance: Importance.high,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  // Get FCM token with fallback
  static Future<String?> getFCMToken() async {
    if (!_initialized) {
      await initialize();
    }

    if (_fallbackMode) {
      print("FirebaseService: Using device ID as token in fallback mode");
      return null;
    }

    try {
      return await _messaging?.getToken();
    } catch (e) {
      print("FirebaseService: Error getting FCM token - $e");
      return null;
    }
  }

  // Handle background messages
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    _showLocalNotification(message);
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _showLocalNotification(message);
  }

  // Show local notification - modified to avoid using problematic APIs
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['taskId'],
      );
    }
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final taskId = response.payload;
      // You can navigate to task details screen here
      print('Tapped on notification for task: $taskId');
    }
  }
}