import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  // Google Maps controller
  GoogleMapController? _mapController;

  // Location data
  Location _location = Location();
  LocationData? _currentLocation;
  bool _liveLocationEnabled = false;

  // Initial camera position (New York)
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.7128, -74.0060),
    zoom: 11,
  );

  // Firebase reference
  late DatabaseReference _locationRef;

  @override
  void initState() {
    super.initState();
    _locationRef = FirebaseDatabase.instance.ref().child('locations');
    _getCurrentLocation();
  }

  // Get user's current location
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

    // Get current location
    _currentLocation = await _location.getLocation();

    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  // Send location to Firebase when live tracking is enabled
  void _sendLocationToFirebase() {
    if (_liveLocationEnabled && _currentLocation != null) {
      _locationRef.push().set({
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
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
        _sendLocationToFirebase();

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
                              Navigator.pop(context);
                            },
                          ),
                          const Text(
                            'Location Tracking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
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

            // Tab selection (Safe Zone Alert / Red Alert)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        'Safe Zone Alert',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Red Alert',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live location toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.deepPurple[800],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _liveLocationEnabled,
                    onChanged: _toggleLiveLocation,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.deepPurple[400],
                  ),
                ],
              ),
            ),

            // Google Map
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
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

                  // Navigation button (bottom right)
                  Positioned(
                    right: 16,
                    bottom: 120,
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
                        icon: const Icon(Icons.navigation),
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                  ),

                  // Center position button (bottom right)
                  Positioned(
                    right: 16,
                    bottom: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
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
                        ),
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                  ),

                  // Connect button (bottom center)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle connect action
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Connect',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}