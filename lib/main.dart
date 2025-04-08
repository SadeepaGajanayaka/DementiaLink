import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'controllers/community_controller.dart';
import 'controllers/messaging_controller.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with verbose logging
    print("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Initialize notification service
    await NotificationService().initialize();

    // Check if a user is already logged in
    User? currentUser = FirebaseAuth.instance.currentUser;
    print("Current user at app start: ${currentUser?.uid ?? 'Not logged in'}");

    // Sign in anonymously if no user is logged in
    if (currentUser == null) {
      print("No user logged in, attempting anonymous sign-in");
      try {
        UserCredential userCred = await FirebaseAuth.instance.signInAnonymously();
        print("Anonymous sign-in successful: ${userCred.user?.uid}");
      } catch (e) {
        print("Anonymous sign-in failed: $e");
      }
    }

    // Start listening for notifications
    NotificationService().startListening();
  } catch (e) {
    print("Error initializing app: $e");
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommunityController()),
        ChangeNotifierProvider(create: (_) => MessagingController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DementiaLink',
        theme: ThemeData(
          primaryColor: const Color(0xFF503663),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5D4E77),
            primary: const Color(0xFF503663),
          ),
          useMaterial3: true,
          fontFamily: 'SF Pro Display',
        ),
        home: const SplashScreen(),
        builder: (context, child) {
          // Use a builder to access the global context for notifications
          return GestureDetector(
            onTap: () {
              // Hide keyboard when tapping outside of text fields
              FocusScope.of(context).unfocus();
            },
            child: child!,
          );
        },
      ),
    );
  }
}