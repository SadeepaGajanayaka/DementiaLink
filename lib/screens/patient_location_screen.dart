import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'map_style.dart';

class PatientLocationScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientLocationScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientLocationScreen> createState() => _PatientLocationScreenState();
}

class _PatientLocationScreenState extends State<PatientLocationScreen> {
  // Location service
  final Location _location = Location();
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Map controller
  GoogleMapController? _mapController;

  // Location data
  LocationData? _patientLocation;
  LocationData? _caregiverLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isTracking = false;

  // Subscription and timer
  StreamSubscription? _locationSubscription;
  Timer? _locationUpdateTimer;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _startLocationUpdateTimer();
  }

  Future<void> _initializeLocationTracking() async {
    try {
      // Initialize location service
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print('Location service not enabled');
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print('Location permission not granted');
          return;
        }
      }

      // First check if we can get the last known location for immediate display
      print('Getting last known location for patient: ${widget.patientId}');

      DataSnapshot snapshot = await _database
          .ref()
          .child('locations')
          .child(widget.patientId)
          .get();

      if (snapshot.exists) {
        print('Found existing location data in Firebase');
        Map<dynamic, dynamic> locationData = snapshot.value as Map<dynamic, dynamic>;

        LocationData lastKnownLocation = LocationData.fromMap({
          'latitude': locationData['latitude'],
          'longitude': locationData['longitude'],
          'accuracy': locationData['accuracy'] ?? 0.0,
          'heading': locationData['heading'] ?? 0.0,
          'speed': locationData['speed'] ?? 0.0,
          'time': locationData['timestamp'] ?? 0,
          'altitude': 0.0,
          'speed_accuracy': 0.0,
          'heading_accuracy': 0.0,
          'altitude_accuracy': 0.0,
        });

        print('Last known location: ${lastKnownLocation.latitude}, ${lastKnownLocation.longitude}');

        if (lastKnownLocation.latitude != null && lastKnownLocation.longitude != null) {
          setState(() {
            _patientLocation = lastKnownLocation;
            _lastUpdateTime = DateTime.now();
            _isTracking = true;
            _updateMarkers();
          });
        }
      } else {
        print('No existing location data found for patient');
      }

      // Get caregiver's current location
      _caregiverLocation = await _location.getLocation();
      print('Caregiver location: ${_caregiverLocation?.latitude}, ${_caregiverLocation?.longitude}');

      // Start listening to patient location updates
      print('Setting up real-time location listener for patient: ${widget.patientId}');
      _locationSubscription = _database
          .ref()
          .child('locations')
          .child(widget.patientId)
          .onValue
          .listen(_handleLocationUpdate, onError: (error) {
        print('Error listening to location updates: $error');
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing location tracking: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLocationUpdate(DatabaseEvent event) {
    print('Location update received from Firebase');
    if (!event.snapshot.exists) {
      print('Snapshot does not exist');
      setState(() {
        _isTracking = false;
      });
      return;
    }

    try {
      Map<dynamic, dynamic> locationData = event.snapshot.value as Map<dynamic, dynamic>;
      print('Raw location data: $locationData');

      double? latitude = locationData['latitude'];
      double? longitude = locationData['longitude'];

      if (latitude == null || longitude == null) {
        print('Invalid coordinates in data');
        return;
      }

      print('Valid location received: $latitude, $longitude');

      LocationData patientLocation = LocationData.fromMap({
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': locationData['accuracy'] ?? 0.0,
        'heading': locationData['heading'] ?? 0.0,
        'speed': locationData['speed'] ?? 0.0,
        'time': locationData['timestamp'] ?? 0,
        'altitude': 0.0,
        'speed_accuracy': 0.0,
        'heading_accuracy': 0.0,
        'altitude_accuracy': 0.0,
      });

      _updatePatientLocation(patientLocation);
    } catch (e) {
      print('Error processing location data: $e');
    }
  }

  void _startLocationUpdateTimer() {
    // Update "last updated" time every second if we have location data
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lastUpdateTime != null && mounted) {
        setState(() {
          // Just trigger a rebuild to update the time display
        });
      }
    });
  }

  void _updatePatientLocation(LocationData? locationData) {
    print('Patient location update received: $locationData');

    // Check if data is valid
    if (locationData == null ||
        locationData.latitude == null ||
        locationData.longitude == null) {
      print('Invalid location data received');
      setState(() {
        _isTracking = false;
      });
      return;
    }

    print('Setting valid location: ${locationData.latitude}, ${locationData.longitude}');

    setState(() {
      _patientLocation = locationData;
      _lastUpdateTime = DateTime.now();
      _isTracking = true;
      _isLoading = false;

      // Update markers
      _updateMarkers();
    });

    // Force camera to move to patient location
    if (_mapController != null) {
      print('Moving camera to patient location');
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(locationData.latitude!, locationData.longitude!),
          15.0, // Zoom level - higher number = more zoomed in
        ),
      );
    } else {
      print('Map controller is null, cannot move camera');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Add patient marker
    if (_patientLocation != null &&
        _patientLocation!.latitude != null &&
        _patientLocation!.longitude != null) {
      print('Adding patient marker at: ${_patientLocation!.latitude}, ${_patientLocation!.longitude}');
      _markers.add(
        Marker(
          markerId: MarkerId('patient_${widget.patientId}'),
          position: LatLng(
            _patientLocation!.latitude!,
            _patientLocation!.longitude!,
          ),
          infoWindow: InfoWindow(
            title: widget.patientName,
            snippet: 'Last updated: ${_getFormattedUpdateTime()}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    // Add caregiver marker
    if (_caregiverLocation != null &&
        _caregiverLocation!.latitude != null &&
        _caregiverLocation!.longitude != null) {
      print('Adding caregiver marker at: ${_caregiverLocation!.latitude}, ${_caregiverLocation!.longitude}');
      _markers.add(
        Marker(
          markerId: const MarkerId('caregiver'),
          position: LatLng(
            _caregiverLocation!.latitude!,
            _caregiverLocation!.longitude!,
          ),
          infoWindow: const InfoWindow(
            title: 'You (Caregiver)',
            snippet: 'Your current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    // Add polyline between caregiver and patient if both locations are available
    _updatePolylines();
  }

  void _updatePolylines() {
    _polylines.clear();

    if (_patientLocation != null &&
        _patientLocation!.latitude != null &&
        _patientLocation!.longitude != null &&
        _caregiverLocation != null &&
        _caregiverLocation!.latitude != null &&
        _caregiverLocation!.longitude != null) {
      print('Adding polyline between caregiver and patient');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('caregiver_to_patient'),
          points: [
            LatLng(_caregiverLocation!.latitude!, _caregiverLocation!.longitude!),
            LatLng(_patientLocation!.latitude!, _patientLocation!.longitude!),
          ],
          color: const Color(0xFF77588D),
          width: 5,
          patterns: [PatternItem.dash(15), PatternItem.gap(10)],
        ),
      );
    }
  }

  String _getFormattedUpdateTime() {
    if (_lastUpdateTime == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(_lastUpdateTime!);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(_lastUpdateTime!);
    }
  }

  Future<void> _updateCaregiverLocation() async {
    print('Updating caregiver location');
    try {
      final location = await _location.getLocation();
      if (location != null &&
          location.latitude != null &&
          location.longitude != null) {
        print('New caregiver location: ${location.latitude}, ${location.longitude}');
        setState(() {
          _caregiverLocation = location;
          _updateMarkers();
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(location.latitude!, location.longitude!),
          ),
        );
      }
    } catch (e) {
      print('Error getting caregiver location: $e');
    }
  }

  @override
  void dispose() {
    print('Disposing PatientLocationScreen');
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF503663), Color(0xFF77588D)],
          ),
        ),
        child: Column(
          children: [
            // Custom app bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                        child: Image.asset(
                          'lib/assets/back_arrow.png',
                          width: 28,
                          height: 28,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Tracking ${widget.patientName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
            ),

            // Map container with rounded corners
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                  child: Stack(
                    children: [
                      // Google Map
                      GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(7.8731, 80.7718), // Default to Sri Lanka center
                          zoom: 8,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        markers: _markers,
                        polylines: _polylines,
                        onMapCreated: (controller) {
                          print('Map created');
                          setState(() {
                            _mapController = controller;
                          });

                          // Apply custom map style
                          controller.setMapStyle(MapStyle.mapStyle);

                          // If we already have the patient location, move to it immediately
                          if (_patientLocation != null &&
                              _patientLocation!.latitude != null &&
                              _patientLocation!.longitude != null) {
                            print('Moving to patient location on map creation: ${_patientLocation!.latitude}, ${_patientLocation!.longitude}');
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                  _patientLocation!.latitude!,
                                  _patientLocation!.longitude!,
                                ),
                                15.0,
                              ),
                            );
                          } else {
                            print('No patient location available on map creation');
                          }
                        },
                      ),

                      // Loading indicator
                      if (_isLoading)
                        Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Patient status card
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Card(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            color: Colors.white,
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Text(
                                    widget.patientName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF503663),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isTracking ? Icons.location_on : Icons.location_off,
                                        color: _isTracking ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isLoading
                                            ? 'Locating patient...'
                                            : !_isTracking
                                            ? 'Not sharing location'
                                            : 'Last update: ${_getFormattedUpdateTime()}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _isTracking ? Colors.green : (_isLoading ? Colors.orange : Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Control buttons
                      Positioned(
                        right: 16,
                        bottom: 100,
                        child: Column(
                          children: [
                            // Center on patient button
                            Container(
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
                                  Icons.person_pin_circle,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                iconSize: 50,
                                onPressed: () {
                                  if (_patientLocation != null &&
                                      _patientLocation!.latitude != null &&
                                      _patientLocation!.longitude != null) {
                                    print('Centering on patient location');
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(
                                          _patientLocation!.latitude!,
                                          _patientLocation!.longitude!,
                                        ),
                                        15.0,
                                      ),
                                    );
                                  } else {
                                    print('Cannot center - patient location not available');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Patient location not available'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            // My location button
                            Container(
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
                                  Icons.my_location,
                                  color: Color(0xFF503663),
                                  size: 30,
                                ),
                                iconSize: 50,
                                onPressed: _updateCaregiverLocation,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contact button
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Emergency call functionality would go here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Emergency call feature will be implemented'),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF503663),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.phone),
                              label: const Text(
                                'Contact Patient',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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