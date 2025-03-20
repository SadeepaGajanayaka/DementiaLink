import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'models/storage_provider.dart';
import 'screens/home_screen.dart';
import 'utils/ThumbnailManager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create StorageProvider early to allow cleanup
  final storageProvider = StorageProvider();

  // Wait for database initialization
  while (!storageProvider.isInitialized) {
    await Future.delayed(Duration(milliseconds: 100));
  }

  // Cleanup expired deleted photos
  await storageProvider.cleanupExpiredDeletedPhotos();

  runApp(
    ChangeNotifierProvider.value(
      value: storageProvider,
      child: ThumbnailManager(
        child: MaterialApp(
          title: 'Memory Journal',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            scaffoldBackgroundColor: Color(0xFF503663),
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: HomeScreen(),
        ),
      ),
    ),
  );
}