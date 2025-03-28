// // // lib/services/firebase_service.dart
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// //
// // class FirebaseService {
// //   static FirebaseMessaging messaging = FirebaseMessaging.instance;
// //   static FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
// //
// //   // Initialize Firebase
// //   static Future<void> initialize() async {
// //     // Initialize Firebase
// //     await Firebase.initializeApp();
// //
// //     // Set up local notifications
// //     const AndroidInitializationSettings initializationSettingsAndroid =
// //     AndroidInitializationSettings('@mipmap/ic_launcher');
// //
// //     const DarwinInitializationSettings initializationSettingsIOS =
// //     DarwinInitializationSettings(
// //       requestAlertPermission: true,
// //       requestBadgePermission: true,
// //       requestSoundPermission: true,
// //     );
// //
// //     const InitializationSettings initializationSettings = InitializationSettings(
// //       android: initializationSettingsAndroid,
// //       iOS: initializationSettingsIOS,
// //     );
// //
// //     await localNotifications.initialize(
// //       initializationSettings,
// //       onDidReceiveNotificationResponse: _onNotificationTapped,
// //     );
// //
// //     // Create notification channel for Android
// //     await _createNotificationChannel();
// //
// //     // Request permission for iOS
// //     await messaging.requestPermission(
// //       alert: true,
// //       badge: true,
// //       sound: true,
// //     );
// //
// //     // Handle background messages
// //     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
// //
// //     // Handle foreground messages
// //     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
// //   }
// //
// //   // Create notification channel for Android
// //   static Future<void> _createNotificationChannel() async {
// //     const AndroidNotificationChannel channel = AndroidNotificationChannel(
// //       'task_reminders', // id
// //       'Task Reminders', // title
// //       description: 'Notifications for task reminders', // description
// //       importance: Importance.high,
// //     );
// //
// //     await localNotifications
// //         .resolvePlatformSpecificImplementation<
// //         AndroidFlutterLocalNotificationsPlugin>()
// //         ?.createNotificationChannel(channel);
// //   }
// //
// //   // Get FCM token
// //   static Future<String?> getFCMToken() async {
// //     return await messaging.getToken();
// //   }
// //
// //   // Handle background messages
// //   @pragma('vm:entry-point')
// //   static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //     await Firebase.initializeApp();
// //     _showLocalNotification(message);
// //   }
// //
// //   // Handle foreground messages
// //   static Future<void> _handleForegroundMessage(RemoteMessage message) async {
// //     _showLocalNotification(message);
// //   }
// //
// //   // Show local notification
// //   static Future<void> _showLocalNotification(RemoteMessage message) async {
// //     RemoteNotification? notification = message.notification;
// //     AndroidNotification? android = message.notification?.android;
// //
// //     if (notification != null) {
// //       await localNotifications.show(
// //         notification.hashCode,
// //         notification.title,
// //         notification.body,
// //         NotificationDetails(
// //           android: AndroidNotificationDetails(
// //             'task_reminders',
// //             'Task Reminders',
// //             channelDescription: 'Notifications for task reminders',
// //             importance: Importance.high,
// //             priority: Priority.high,
// //             icon: '@mipmap/ic_launcher',
// //           ),
// //           iOS: const DarwinNotificationDetails(
// //             presentAlert: true,
// //             presentBadge: true,
// //             presentSound: true,
// //           ),
// //         ),
// //         payload: message.data['taskId'],
// //       );
// //     }
// //   }
// //
// //   // Handle notification tap
// //   static void _onNotificationTapped(NotificationResponse response) {
// //     if (response.payload != null) {
// //       final taskId = response.payload;
// //       // You can navigate to task details screen here
// //       print('Tapped on notification for task: $taskId');
// //
// //       // Example:
// //       // Navigator.of(GlobalContext.navigatorKey.currentContext!).push(
// //       //   MaterialPageRoute(
// //       //     builder: (context) => TaskDetailsScreen(taskId: taskId!),
// //       //   ),
// //       // );
// //     }
// //   }
// // }
// // lib/services/firebase_service.dart
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class FirebaseService {
//   static FirebaseMessaging messaging = FirebaseMessaging.instance;
//   static FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
//
//   // Initialize Firebase
//   static Future<void> initialize() async {
//     // Initialize Firebase
//     await Firebase.initializeApp();
//
//     // Set up local notifications
//     const AndroidInitializationSettings initializationSettingsAndroid =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//
//     const DarwinInitializationSettings initializationSettingsIOS =
//     DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//
//     const InitializationSettings initializationSettings = InitializationSettings(
//       android: initializationSettingsAndroid,
//       iOS: initializationSettingsIOS,
//     );
//
//     await localNotifications.initialize(
//       initializationSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );
//
//     // Create notification channel for Android
//     await _createNotificationChannel();
//
//     // Request permission for iOS
//     await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     // Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//
//     // Handle foreground messages
//     FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//   }
//
//   // Create notification channel for Android
//   static Future<void> _createNotificationChannel() async {
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'task_reminders', // id
//       'Task Reminders', // title
//       description: 'Notifications for task reminders', // description
//       importance: Importance.high,
//     );
//
//     await localNotifications
//         .resolvePlatformSpecificImplementation
//     AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   // Get FCM token
//   static Future<String?> getFCMToken() async {
//     return await messaging.getToken();
//   }
//
//   // Handle background messages
//   @pragma('vm:entry-point')
//   static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     await Firebase.initializeApp();
//     _showLocalNotification(message);
//   }
//
//   // Handle foreground messages
//   static Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     _showLocalNotification(message);
//   }
//
//   // Show local notification - modified to avoid using problematic APIs
//   static Future<void> _showLocalNotification(RemoteMessage message) async {
//     RemoteNotification? notification = message.notification;
//
//     if (notification != null) {
//       await localNotifications.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'task_reminders',
//             'Task Reminders',
//             channelDescription: 'Notifications for task reminders',
//             importance: Importance.high,
//             priority: Priority.high,
//             // Removed icon to avoid any potential conflicts
//             // You can add it back if needed after confirming compatibility
//           ),
//           iOS: const DarwinNotificationDetails(
//             presentAlert: true,
//             presentBadge: true,
//             presentSound: true,
//           ),
//         ),
//         payload: message.data['taskId'],
//       );
//     }
//   }
//
//   // Handle notification tap
//   static void _onNotificationTapped(NotificationResponse response) {
//     if (response.payload != null) {
//       final taskId = response.payload;
//       // You can navigate to task details screen here
//       print('Tapped on notification for task: $taskId');
//
//       // Example:
//       // Navigator.of(GlobalContext.navigatorKey.currentContext!).push(
//       //   MaterialPageRoute(
//       //     builder: (context) => TaskDetailsScreen(taskId: taskId!),
//       //   ),
//       // );
//     }
//   }
// }

// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize Firebase
  static Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

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
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
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

  // Get FCM token
  static Future<String?> getFCMToken() async {
    return await messaging.getToken();
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
          android: AndroidNotificationDetails(
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

      // Example:
      // Navigator.of(GlobalContext.navigatorKey.currentContext!).push(
      //   MaterialPageRoute(
      //     builder: (context) => TaskDetailsScreen(taskId: taskId!),
      //   ),
      // );
    }
  }
}