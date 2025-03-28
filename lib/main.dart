import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/task_service.dart';
import 'services/notification_service.dart';
import 'screens/task_list_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handle background notification taps
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // This will be called even when the app is terminated
  print("Notification tapped in background: ${notificationResponse.payload}");
  // We'll handle the navigation in the app when it starts
}

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase directly in main
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    print("Continuing without Firebase...");
    // The app will continue without Firebase
  }

  // Initialize Notification Service first to handle background notification taps
  try {
    await NotificationService.instance.initialize();

    // Set up background notification handler
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        print("Notification tapped in foreground: ${notificationResponse.payload}");
        // We'll handle the navigation in the running app
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    print("Notification service initialized successfully");
  } catch (e) {
    print("Failed to initialize notification service: $e");
    print("Continuing without notifications...");
  }

  // Initialize Firebase Service with fallback support
  try {
    await FirebaseService.initialize();
  } catch (e) {
    print("Firebase service initialization had issues: $e");
    // The service handles fallback internally
  }

  // Initialize Task Service
  try {
    await TaskService.initialize();
  } catch (e) {
    print("Task service initialization issues: $e");
    // The app will continue and show proper error messages in UI
  }

  // Run the app
  runApp(TaskReminderApp());
}

class TaskReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Reminder',
      theme: ThemeData(
        primaryColor: const Color(0xFF503663),
        scaffoldBackgroundColor: const Color(0xFF503663),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF503663),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          displayLarge: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF77588D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      navigatorKey: GlobalContext.navigatorKey, // Important for accessing context in services
      home: TaskListScreen(),
    );
  }
}

// Global context for accessing navigator key
class GlobalContext {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Add a method to navigate to a specific task when notification is tapped
  static void navigateToTask(String taskId) {
    // This method would navigate to the task details screen
    // For now, just print a message
    print("GlobalContext: Should navigate to task $taskId");

    // Example implementation (uncomment and modify as needed):
    // navigatorKey.currentState?.push(
    //   MaterialPageRoute(
    //     builder: (context) => TaskDetailScreen(taskId: taskId),
    //   ),
    // );
  }
}