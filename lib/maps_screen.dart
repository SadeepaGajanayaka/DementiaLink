import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  // Google Maps controller
  GoogleMapController? _mapController;

  // Location data
  final Location _location = Location();
  LocationData? _currentLocation;
  bool _liveLocationEnabled = false;

  // Tab selection state
  bool _safeZoneSelected = true;

  // Initial camera position (Sri Lanka - Centered on the island)
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(7.8731, 80.7718), // Center of Sri Lanka
    zoom: 8, // Zoom out to see more of the island
  );

  // Firebase reference
  late final DatabaseReference _locationRef;

  @override
  void initState() {
    super.initState();
    _locationRef = FirebaseDatabase.instance.ref().child('locations');
    // We'll position to Sri Lanka first, then try to get current location
    Future.delayed(Duration(milliseconds: 500), () {
      _moveToSriLanka();
    });
  }

  // Function to ensure map is positioned to Sri Lanka
  void _moveToSriLanka() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
    }
  }

  // Get user's current location but don't move camera by default
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check location permission
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location without moving camera
    _currentLocation = await _location.getLocation();

    // Don't automatically move camera to current location
    // This ensures Sri Lanka stays in view
  }

  // Method to center on user's location when explicitly requested
  void _centerOnCurrentLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  // Toggle live location tracking
  void _toggleLiveLocation(bool value) {
    setState(() {
      _liveLocationEnabled = value;
    });

    if (_liveLocationEnabled) {
      _location.onLocationChanged.listen((LocationData currentLocation) {
        setState(() {
          _currentLocation = currentLocation;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Purple gradient app bar with location tracking title
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF77588D), Color(0xFF503663)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      // Back button and title
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              // Back functionality
                            },
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Location Tracking',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Brain icon
                          Container(
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),

                      // Search bar
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.location_on,
                                color: Colors.amber[700],
                              ),
                            ),
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search Here........',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expanded map view with rounded corners and UI elements as overlays
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF77588D), Color(0xFF503663)],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      // Map background
                      GoogleMap(
                        initialCameraPosition: _initialCameraPosition,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        padding: const EdgeInsets.only(top: 10),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          if (_currentLocation != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLng(
                                LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                              ),
                            );
                          }
                        },
                      ),

                      // UI elements on top of map - MOVED TO TOP
                      Positioned(
                        top: 30, // Moved a tiny bit lower
                        left: 0,
                        right: 0,
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.85, // Increased width from 75% to 85% of screen width
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Safe Zone / Red Alert tabs with selection behavior
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        topRight: Radius.circular(15),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        // Safe Zone Alert
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _safeZoneSelected = true;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: _safeZoneSelected
                                                    ? const Color(0xFFD9D9D9)
                                                    : Colors.white,
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(15),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Safe Zone Alert',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _safeZoneSelected
                                                        ? Colors.black87
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Red Alert
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _safeZoneSelected = false;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                              decoration: BoxDecoration(
                                                color: !_safeZoneSelected
                                                    ? const Color(0xFFD9D9D9)
                                                    : Colors.white,
                                                borderRadius: const BorderRadius.only(
                                                  topRight: Radius.circular(15),
                                                ),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Red Alert',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: !_safeZoneSelected
                                                        ? Colors.black87
                                                        : Colors.black54,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Live location toggle - connected to tabs above with increased height
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF503663),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(15),
                                        bottomRight: Radius.circular(15),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Moderately increased vertical padding
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Live Location',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Switch(
                                          value: _liveLocationEnabled,
                                          onChanged: _toggleLiveLocation,
                                          activeColor: Colors.white,
                                          activeTrackColor: const Color(0xFF6246A3),
                                          inactiveTrackColor: Colors.grey[700],
                                          inactiveThumbColor: Colors.white,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Compass/Navigation button (right middle position as in screenshot)
                      Positioned(
                        right: 16,
                        top: MediaQuery.of(context).size.height * 0.4, // Keep this position
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.navigation,
                              size: 24,
                            ),
                            onPressed: _centerOnCurrentLocation,
                          ),
                        ),
                      ),

                      // Target location button (below compass, as in screenshot)
                      Positioned(
                        right: 16,
                        top: MediaQuery.of(context).size.height * 0.465, // Small space, not pasted together
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF77588D),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _getCurrentLocation,
                          ),
                        ),
                      ),

                      // Connect button (bottom right corner)
                      Positioned(
                        bottom: 20,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF77588D),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                // Handle connect action
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Connect',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}