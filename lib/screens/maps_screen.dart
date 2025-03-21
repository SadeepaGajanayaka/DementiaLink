import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'map_style.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'connect_patient_screen.dart';
import 'connection_requests_screen.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  // Google Maps controller
  GoogleMapController? _mapController;

  // Location data and services
  final Location _location = Location();
  LocationData? _currentLocation;
  final LocationService _locationService = LocationService();
  bool _liveLocationEnabled = false;

  // Authentication service
  final AuthService _authService = AuthService();
  bool _isCaregiver = false;
  bool _isLoading = true;

  // Tab selection state
  bool _safeZoneSelected = true;

  // Map markers for patient locations
  final Map<String, Marker> _patientMarkers = {};

  // Currently connected patients (for caregiver view)
  List<Map<String, dynamic>> _connectedPatients = [];

  // Currently connected caregivers (for patient view)
  List<Map<String, dynamic>> _connectedCaregivers = [];

  // Connection status message
  String? _connectionStatusMessage;

  // Initial camera position (Sri Lanka - Centered on the island)
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(7.8731, 80.7718), // Center of Sri Lanka
    zoom: 8, // Zoom out to see more of the island
  );

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize location service
      await _locationService.initialize();

      // Check user role
      await _checkUserRole();

      // Get current location
      await _getCurrentLocation();

      // Start location sharing for patients
      if (!_isCaregiver) {
        await _locationService.startSharingLocation();
        _loadConnectedCaregivers();
      } else {
        _loadConnectedPatients();
      }

      // Update state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error initializing services: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if the current user is a caregiver
  Future<void> _checkUserRole() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final userData = await _authService.getUserData(userId);
        if (mounted) {
          setState(() {
            _isCaregiver = userData['role'] == 'caregiver';
          });
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  // Load connected patients (for caregiver view)
  void _loadConnectedPatients() {
    _locationService.getConnectedPatients().listen((snapshot) {
      final patients = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['patientName'] ?? 'Unknown Patient',
          'email': data['patientEmail'] ?? 'No email',
          'status': data['status'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _connectedPatients = patients;
        });

        // Start tracking each patient's location
        for (final patient in patients) {
          if (patient['status'] == 'active') {
            _trackPatientLocation(patient['id'], patient['name']);
          }
        }
      }
    });
  }

  // Load connected caregivers (for patient view)
  void _loadConnectedCaregivers() {
    _locationService.getConnectedCaregivers().listen((snapshot) {
      final caregivers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['caregiverName'] ?? 'Unknown Caregiver',
          'email': data['caregiverEmail'] ?? 'No email',
          'status': data['status'],
        };
      }).toList();

      if (mounted) {
        setState(() {
          _connectedCaregivers = caregivers;

          // Update connection status message
          if (caregivers.isNotEmpty) {
            final activeCaregivers = caregivers.where((c) => c['status'] == 'active').toList();
            if (activeCaregivers.isNotEmpty) {
              _connectionStatusMessage = "Connected with ${activeCaregivers.length} ${activeCaregivers.length == 1 ? 'caregiver' : 'caregivers'}";
            } else {
              _connectionStatusMessage = "Not connected with any caregivers";
            }
          } else {
            _connectionStatusMessage = "Not connected with any caregivers";
          }
        });
      }
    });
  }

  // Track a patient's location in real-time
  void _trackPatientLocation(String patientId, String patientName) {
    _locationService.getUserLocationStream(patientId).listen((locationData) {
      if (locationData.isEmpty ||
          locationData['latitude'] == null ||
          locationData['longitude'] == null) {
        return;
      }

      final latLng = LatLng(
        locationData['latitude'],
        locationData['longitude'],
      );

      if (mounted) {
        setState(() {
          _patientMarkers[patientId] = Marker(
            markerId: MarkerId(patientId),
            position: latLng,
            infoWindow: InfoWindow(
              title: patientName,
              snippet: 'Last updated: ${_formatTimestamp(locationData['timestamp'])}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          );
        });
      }
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final DateTime dateTime = timestamp is int
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.now();

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
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

    // Get current location
    _currentLocation = await _location.getLocation();

    if (_mapController != null && _currentLocation != null) {
      // Only center map on current location if no patient markers
      if (_patientMarkers.isEmpty) {
        _centerOnCurrentLocation();
      }
    }
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

        if (_mapController != null && _patientMarkers.isEmpty) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            ),
          );
        }
      });
    }
  }

  // Show connection requests screen (for patient)
  void _showConnectionRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConnectionRequestsScreen(),
      ),
    );
  }

  // Connect with a patient (for caregiver)
  void _connectWithPatient() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return const ConnectPatientScreen();
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    ).then((patientEmail) {
      // Handle returned patient email if needed
      if (patientEmail != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to: $patientEmail'),
            backgroundColor: const Color(0xFF503663),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Clean up location services
    if (!_isCaregiver) {
      _locationService.stopSharingLocation();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Applying the gradient to the entire screen background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF503663), Color(0xFF77588D)],
          ),
        ),
        child: Column(
          children: [
            // App bar without its own gradient now
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Back button and title
                    Row(
                      children: [
                        // Custom back arrow image
                        GestureDetector(
                          onTap: () {
                            // Back functionality - Navigate to dashboard
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Location Tracking',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Brain icon - using the specified asset with larger size
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Search bar with Google Maps icon
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
                          // Google Maps icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.map,
                              color: Colors.grey[700],
                              size: 26,
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
                          // Microphone icon in black
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.mic,
                              color: Colors.black, // Changed to black
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded map view with rounded corners and UI elements as overlays
            Expanded(
              child: Stack(
                children: [
                  // Map with rounded corners
                  Padding(
                    padding: const EdgeInsets.only(top: 2), // Small offset to ensure no gap
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                      child: _isLoading
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                          : GoogleMap(
                        initialCameraPosition: _initialCameraPosition,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        markers: Set<Marker>.of(_patientMarkers.values),
                        padding: const EdgeInsets.only(top: 10),
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
                    ),
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
                                                color: Colors.black, // Changed to black
                                                fontSize: 16, // Increased font size
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
                                                color: Colors.black, // Changed to black
                                                fontSize: 16, // Increased font size
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
                                      children: [
                                        // Location pin icon next to "Live Location" text
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isCaregiver
                                              ? 'Track Patient'
                                              : _connectionStatusMessage ?? 'Live Location',
                                          style: const TextStyle(
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

                  // Connected Patients/Caregivers List (if any)
                  if (_isCaregiver && _connectedPatients.isNotEmpty)
                    Positioned(
                      top: 130,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connected Patients',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _connectedPatients.length,
                                itemBuilder: (context, index) {
                                  final patient = _connectedPatients[index];
                                  return Container(
                                    margin: EdgeInsets.only(right: 10),
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: patient['status'] == 'active'
                                          ? Color(0xFFECE5F1)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: patient['status'] == 'active'
                                            ? Color(0xFF77588D)
                                            : Colors.grey,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          patient['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: patient['status'] == 'active'
                                                ? Color(0xFF503663)
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          patient['status'] == 'active' ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: patient['status'] == 'active'
                                                ? Color(0xFF77588D)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Original position but with reduced spacing between buttons
                  // First circle (Navigation button)
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).size.height * 0.4, // Keep original position
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
                          size: 30,
                        ),
                        iconSize: 50,
                        onPressed: _centerOnCurrentLocation,
                      ),
                    ),
                  ),

                  // Second circle (Target location button) - moved closer to the first one
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).size.height * 0.46, // Reduced distance from 0.485 to 0.46
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
                          size: 30,
                        ),
                        iconSize: 50,
                        onPressed: _getCurrentLocation,
                      ),
                    ),
                  ),

                  // Connection actions button (bottom right corner)
                  // Only show for caregiver (Connect) or patient (View Requests)
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
                          onTap: _isCaregiver ? _connectWithPatient : _showConnectionRequests,
                          borderRadius: BorderRadius.circular(30),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCaregiver ? Icons.person_add : Icons.notifications,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCaregiver ? 'Connect Patient' : 'Connection Requests',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
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
