import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DementiaLink Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
    zoom: 14.0,
  );

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DementiaLink Maps'),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}