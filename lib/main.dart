import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'maps_screen.dart'; // Import for LocationTrackingScreen

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
        primaryColor: const Color(0xFF6A4D7A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6A4D7A),
        ),
      ),
      home: const MapScreen(),
      routes: {
        '/location_tracking': (context) => const LocationTrackingScreen(),
      },
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Center on Sri Lanka
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(7.8731, 80.7718), // Sri Lanka center
    zoom: 8.0,
  );

  GoogleMapController? _mapController;

  // Exact map style matching the screenshot
  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f8f8f8"
      }
    ]
  },
  // Map style JSON continues...
]
  ''';

  @override
  void initState() {
    super.initState();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Apply the exact custom style
    _mapController!.setMapStyle(_mapStyle);

    // Optional: Move to Colombo specifically if you want
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
          zoom: 12.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: false,
          ),
          Positioned(
            top: 40,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF6A4D7A),
              child: const Icon(Icons.navigation),
              onPressed: () {
                Navigator.pushNamed(context, '/location_tracking');
              },
            ),
          ),
        ],
      ),
    );
  }
}
