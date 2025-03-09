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

          // Search bar at the top
          Positioned(
            top: 40,
            left: 10,
            right: 10,
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
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
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
                        const SizedBox(width: 15),
                        Icon(
                          Icons.location_on,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Here........',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.mic,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 15),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Menu button on the right
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
                    ),
                    onPressed: () {
                      // Menu functionality
                    },
                  ),
                ),
              ],
            ),
          ),

          // Compass in bottom right
          Positioned(
            bottom: 130,
            right: 16,
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
                onPressed: () {
                  // Compass functionality
                },
              ),
            ),
          ),

          // Bottom navigation bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              color: const Color(0xFF503663),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Home button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF77588D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Hospital button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF77588D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Color(0xFF90EE90), // Light green
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hospital',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Friend's Place button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF77588D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.lightBlueAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Friend's\nPlace",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Add button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
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