import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/task_service.dart';
import 'screens/task_list_screen.dart';

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
}