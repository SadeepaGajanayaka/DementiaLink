import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'map_style.dart';

class SafeZoneScreen extends StatefulWidget {
  const SafeZoneScreen({Key? key}) : super(key: key);

  @override
  State<SafeZoneScreen> createState() => _SafeZoneScreenState();
}

class _SafeZoneScreenState extends State<SafeZoneScreen> {
  // Google Maps controller
  GoogleMapController? _mapController;

  // Location data
  final Location _location = Location();
  LocationData? _currentLocation;

  // Initial camera position (using the same position from maps_screen.dart)
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(7.8731, 80.7718), // Center of Sri Lanka
    zoom: 8, // Zoom out to see more of the island
  );

  @override
  void initState() {
    super.initState();
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

    // Update camera to user's location
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        // Map
        GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;

          // Apply the custom map style
          _mapController!.setMapStyle(MapStyle.mapStyle);

          if (_currentLocation != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
              ),
            );
          }
        },
      ),

      // Search bar at the top - matches screenshot exactly
      Positioned(
        top: 10,
        left: 10,
        right: 10,
        child: SafeArea(
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Search field
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.location_on,
                        color: Colors.amber[700],
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search Here........',
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.black54),
                            contentPadding: EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.mic,
                        color: Colors.black54,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Brain icon on right - deep purple color from screenshot
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF503663),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () {
                    // Brain icon functionality
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // Compass button - match screenshot position
      Positioned(
        bottom: 100,
        right: 16,
        child: Container(
          width: 48,
          height: 48,
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
              color: Colors.black87,
            ),
            onPressed: () {
              // Navigation functionality
              if (_currentLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                  ),
                );
              }
            },
          ),
        ),
      ),

      // Target/My location button - match screenshot position
      Positioned(
        bottom: 160,
        right: 16,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF503663), // Purple color as in screenshot
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
              size: 24,
              color: Colors.white,
            ),
            onPressed: () {
              _getCurrentLocation();
              if (_currentLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                  ),
                );
              }
            },
          ),
        ),
      ),

      // Bottom navigation bar - EXACTLY match the screenshot
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SizedBox(
          height: 80,
          child: Container(
            color: const Color(0xFF503663),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Home button - exactly as in screenshot with vertical rectangle
                SizedBox(
                  width: 70,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFF503663),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.purple[700],
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hospital button
                SizedBox(
                  width: 70,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFF503663),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green[600],
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Hospital',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Friend's Place button
                SizedBox(
                  width: 70,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFF503663),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.blue[400],
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 0),
                      const Text(
                        "Friend's",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      const Text(
                        "Place",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Add button
                SizedBox(
                  width: 70,
                  height: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 55,
                        decoration: BoxDecoration(
                          color: const Color(0xFF503663),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.black87,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}