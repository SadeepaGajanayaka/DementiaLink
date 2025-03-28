import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with verbose logging
    print("Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

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
  } catch (e) {
    print("Error initializing Firebase: $e");
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
    return MaterialApp(
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
    );
  }
}
