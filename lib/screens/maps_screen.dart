import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'map_style.dart';
import 'connect.dart';
import 'safe_zone.dart';

// LocationService class for handling all location tracking functionality
class LocationService {
  final Location _location = Location();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<LocationData>? _locationSubscription;
  bool _isTracking = false;
  String? _connectedPatientId;

  // Initialize location service and request permissions
  Future<bool> initialize() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    // Check location permission
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    // Configure location settings for better accuracy
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000, // Update every 10 seconds
      distanceFilter: 5, // Minimum movement in meters to trigger update
    );

    return true;
  }

  // Start sharing location for patients
  Future<bool> startSharingLocation() async {
    if (_isTracking) return true;

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Determine if user is a patient
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.get('role') != 'patient') {
        print('Only patients can share location');
        return false;
      }

      _isTracking = true;

      // Start listening to location changes
      _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
        if (locationData.latitude == null || locationData.longitude == null) return;

        // Update location in Firebase Realtime Database
        _database.ref().child('locations').child(userId).set({
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'accuracy': locationData.accuracy,
          'speed': locationData.speed,
          'heading': locationData.heading,
          'timestamp': ServerValue.timestamp,
          'battery': locationData.battery,
        });

        print('Location updated: ${locationData.latitude}, ${locationData.longitude}');
      });

      return true;
    } catch (e) {
      print('Error starting location sharing: $e');
      return false;
    }
  }

  // Stop sharing location
  Future<void> stopSharingLocation() async {
    _isTracking = false;
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // Remove location data when stopping sharing (optional)
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _database.ref().child('locations').child(userId).remove();
    }
  }

  // Connect to a patient for caregivers
  Future<bool> connectToPatient(String patientEmail) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Verify user is a caregiver
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.get('role') != 'caregiver') {
        print('Only caregivers can connect to patients');
        return false;
      }

      // Find patient by email
      QuerySnapshot patientQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: patientEmail)
          .where('role', isEqualTo: 'patient')
          .limit(1)
          .get();

      if (patientQuery.docs.isEmpty) {
        print('No patient found with that email');
        return false;
      }

      String patientId = patientQuery.docs.first.id;

      // Store connection in Firebase
      await _database.ref().child('connections').child(userId).child(patientId).set(true);
      _connectedPatientId = patientId;

      // Also store in Firestore for persistence
      await _firestore.collection('users').doc(userId).collection('connections').doc(patientId).set({
        'email': patientEmail,
        'connected_at': FieldValue.serverTimestamp(),
        'active': true
      });

      return true;
    } catch (e) {
      print('Error connecting to patient: $e');
      return false;
    }
  }

  // Get location updates for a connected patient (for caregivers)
  Stream<LocationData?> getPatientLocationStream(String patientId) {
    try {
      final StreamController<LocationData?> controller = StreamController<LocationData?>();

      // Listen to location updates from Firebase Realtime Database
      _database.ref().child('locations').child(patientId).onValue.listen((event) {
        if (event.snapshot.value == null) {
          controller.add(null);
          return;
        }

        Map<dynamic, dynamic> locationData = event.snapshot.value as Map<dynamic, dynamic>;

        controller.add(LocationData.fromMap({
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
          'battery': locationData['battery'] ?? 0.0,
        }));
      }, onError: (error) {
        print('Error getting patient location: $error');
        controller.addError(error);
      });

      return controller.stream;
    } catch (e) {
      print('Error setting up patient location stream: $e');
      return Stream.value(null);
    }
  }

  // Get list of connected patients for a caregiver
  Future<List<Map<String, dynamic>>> getConnectedPatients() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      // Get connections from Firestore
      QuerySnapshot connections = await _firestore
          .collection('users')
          .doc(userId)
          .collection('connections')
          .where('active', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> patients = [];

      for (var doc in connections.docs) {
        String patientId = doc.id;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Get patient profile information
        DocumentSnapshot patientDoc = await _firestore.collection('users').doc(patientId).get();
        if (patientDoc.exists) {
          Map<String, dynamic> patientData = patientDoc.data() as Map<String, dynamic>;
          patients.add({
            'id': patientId,
            'email': data['email'],
            'name': patientData['name'] ?? 'Unknown Patient',
            'photoUrl': patientData['photoUrl'] ?? '',
          });
        }
      }

      return patients;
    } catch (e) {
      print('Error getting connected patients: $e');
      return [];
    }
  }

  // Disconnect from a patient
  Future<bool> disconnectFromPatient(String patientId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // Remove connection in Realtime Database
      await _database.ref().child('connections').child(userId).child(patientId).remove();

      // Update connection status in Firestore
      await _firestore.collection('users').doc(userId).collection('connections').doc(patientId).update({
        'active': false,
        'disconnected_at': FieldValue.serverTimestamp(),
      });

      if (_connectedPatientId == patientId) {
        _connectedPatientId = null;
      }

      return true;
    } catch (e) {
      print('Error disconnecting from patient: $e');
      return false;
    }
  }

  // Get current location once (not streaming)
  Future<LocationData?> getCurrentLocation() async {
    try {
      return await _location.getLocation();
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Check if a patient has shared location
  Future<bool> isPatientSharingLocation(String patientId) async {
    try {
      DataSnapshot snapshot = await _database.ref().child('locations').child(patientId).get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking if patient is sharing location: $e');
      return false;
    }
  }

  // Get last known location for a patient
  Future<LocationData?> getLastKnownPatientLocation(String patientId) async {
    try {
      DataSnapshot snapshot = await _database.ref().child('locations').child(patientId).get();

      if (!snapshot.exists) return null;

      Map<dynamic, dynamic> locationData = snapshot.value as Map<dynamic, dynamic>;

      return LocationData.fromMap({
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
        'battery': locationData['battery'] ?? 0.0,
      });
    } catch (e) {
      print('Error getting last known patient location: $e');
      return null;
    }
  }

  // Dispose resources
  void dispose() {
    _locationSubscription?.cancel();
  }
}

extension on LocationData {
  get battery => null;
}

// PatientLocationScreen for caregivers to view patient location
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
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LocationData? _patientLocation;
  LocationData? _caregiverLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _isTracking = false;
  StreamSubscription<LocationData?>? _locationSubscription;
  Timer? _locationUpdateTimer;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _initializeLocationTracking();
    _startLocationUpdateTimer();
  }

  Future<void> _initializeLocationTracking() async {
    // First check if we can get the last known location for immediate display
    LocationData? lastKnownLocation = await _locationService.getLastKnownPatientLocation(widget.patientId);
    if (lastKnownLocation != null &&
        lastKnownLocation.latitude != null &&
        lastKnownLocation.longitude != null) {
      setState(() {
        _patientLocation = lastKnownLocation;
        _lastUpdateTime = DateTime.now();
        _updateMarkers();
      });
    }

    // Get caregiver's current location
    await _locationService.initialize();
    _caregiverLocation = await _locationService.getCurrentLocation();

    // Start listening to patient location updates
    _locationSubscription = _locationService
        .getPatientLocationStream(widget.patientId)
        .listen(_updatePatientLocation);

    // Check if patient is sharing location
    bool isSharing = await _locationService.isPatientSharingLocation(widget.patientId);
    setState(() {
      _isTracking = isSharing;
      _isLoading = false;
    });
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
    if (locationData == null ||
        locationData.latitude == null ||
        locationData.longitude == null) {
      setState(() {
        _isTracking = false;
      });
      return;
    }

    setState(() {
      _patientLocation = locationData;
      _lastUpdateTime = DateTime.now();
      _isTracking = true;
      _isLoading = false;
      _updateMarkers();
    });

    // Move camera to patient location
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(locationData.latitude!, locationData.longitude!),
        16.0,
      ),
    );
  }

  void _updateMarkers() {
    _markers.clear();

    // Add patient marker
    if (_patientLocation != null &&
        _patientLocation!.latitude != null &&
        _patientLocation!.longitude != null) {
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
    final location = await _locationService.getCurrentLocation();
    if (location != null &&
        location.latitude != null &&
        location.longitude != null) {
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
  }

  @override
  void dispose() {
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
                          _mapController = controller;

                          // Apply custom map style
                          controller.setMapStyle(MapStyle.mapStyle);

                          // If we already have the patient location, move to it
                          if (_patientLocation != null &&
                              _patientLocation!.latitude != null &&
                              _patientLocation!.longitude != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                  _patientLocation!.latitude!,
                                  _patientLocation!.longitude!,
                                ),
                                16.0,
                              ),
                            );
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
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(
                                          _patientLocation!.latitude!,
                                          _patientLocation!.longitude!,
                                        ),
                                        16.0,
                                      ),
                                    );
                                  } else {
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

// Enhanced MapsScreen with role-based functionality
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
  final LocationService _locationService = LocationService();
  LocationData? _currentLocation;
  bool _liveLocationEnabled = false;

  // Tab selection state
  bool _safeZoneSelected = true;

  // Role and connection states
  bool _isLoading = true;
  bool _isCaregiver = false;
  bool _isSharingLocation = false;
  List<Map<String, dynamic>> _connectedPatients = [];

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
    _initialize();
  }

  // Initialize the screen based on user role
  Future<void> _initialize() async {
    try {
      // Initialize location service
      await _locationService.initialize();

      // Get current location
      _currentLocation = await _location.getLocation();

      // Check if user is a caregiver
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();

      bool isCaregiver = userDoc.exists && userDoc.get('role') == 'caregiver';

      // If caregiver, get connected patients
      List<Map<String, dynamic>> patients = [];
      if (isCaregiver) {
        patients = await _locationService.getConnectedPatients();
      } else {
        // If patient, check if already sharing location
        String userId = FirebaseAuth.instance.currentUser!.uid;
        DataSnapshot snapshot = await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child(userId)
            .get();

        bool isSharingLocation = snapshot.exists;

        // If already sharing, restart the service
        if (isSharingLocation) {
          await _locationService.startSharingLocation();
        }

        setState(() {
          _isSharingLocation = isSharingLocation;
        });
      }

      setState(() {
        _isCaregiver = isCaregiver;
        _connectedPatients = patients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing: $e');
      setState(() {
        _isLoading = false;
      });
    }
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

  // Toggle patient location sharing
  Future<void> _toggleLocationSharing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isSharingLocation) {
        await _locationService.stopSharingLocation();
        success = true;
      } else {
        success = await _locationService.startSharingLocation();
      }

      if (success) {
        setState(() {
          _isSharingLocation = !_isSharingLocation;
        });
      }
    } catch (e) {
      print('Error toggling location sharing: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Connect to a patient for caregivers
  Future<void> _connectToPatient() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return const ConnectScreen();
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _isLoading = true;
      });

      try {
        bool success = await _locationService.connectToPatient(result);

        if (success) {
          // Refresh connected patients list
          List<Map<String, dynamic>> patients = await _locationService.getConnectedPatients();

          setState(() {
            _connectedPatients = patients;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully connected to patient: $result'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to connect to patient: $result'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print('Error connecting to patient: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error connecting to patient: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // View a specific patient's location
  void _viewPatientLocation(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientLocationScreen(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }

  // Disconnect from a patient
  Future<void> _disconnectFromPatient(String patientId, String patientName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success = await _locationService.disconnectFromPatient(patientId);

      if (success) {
        // Refresh connected patients list
        List<Map<String, dynamic>> patients = await _locationService.getConnectedPatients();

        setState(() {
          _connectedPatients = patients;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Disconnected from $patientName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disconnect from $patientName'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error disconnecting from patient: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disconnecting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                          child: Image.asset(
                            'lib/assets/images/brain_icon.png',
                            width: 50,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.psychology,
                              color: Colors.white,
                              size: 40,
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
                            child: Image.asset(
                              'lib/assets/google-maps.png',
                              width: 26,
                              height: 26,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.map,
                                color: Color(0xFF503663),
                                size: 26,
                              ),
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

            // Main content area based on user role
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
                  : _isCaregiver
                  ? _buildCaregiverView()
                  : _buildPatientView(),
            ),
          ],
        ),
      ),
    );
  }

  // View for patients to enable/disable location sharing
  Widget _buildPatientView() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              _isSharingLocation ? Icons.location_on : Icons.location_off,
              size: 80,
              color: _isSharingLocation ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 24),
            // Status text
            Text(
              _isSharingLocation
                  ? 'Your location is being shared with your caregiver'
                  : 'Your location is not being shared',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _isSharingLocation ? Colors.green : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isSharingLocation
                  ? 'Your caregiver can see your real-time location on their map'
                  : 'Enable location sharing to allow your caregiver to see your location',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            // Toggle button
            ElevatedButton(
              onPressed: _toggleLocationSharing,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSharingLocation ? Colors.red : const Color(0xFF503663),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                _isSharingLocation ? 'STOP SHARING LOCATION' : 'START SHARING LOCATION',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.privacy_tip,
                    color: Color(0xFF503663),
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Privacy Note',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF503663),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your location data is encrypted and only shared with your authorized caregivers. You can stop sharing at any time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // View for caregivers to manage connected patients
  Widget _buildCaregiverView() {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Connected Patients',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF503663),
              ),
            ),
          ),

          // Patients list
          Expanded(
            child: _connectedPatients.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No connected patients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connect to a patient to see their location',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _connectedPatients.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final patient = _connectedPatients[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF77588D),
                      radius: 30,
                      backgroundImage: patient['photoUrl'] != null && patient['photoUrl'].isNotEmpty
                          ? NetworkImage(patient['photoUrl'])
                          : null,
                      child: patient['photoUrl'] == null || patient['photoUrl'].isEmpty
                          ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      )
                          : null,
                    ),
                    title: Text(
                      patient['name'] ?? 'Unknown Patient',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(patient['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View location button
                        IconButton(
                          icon: const Icon(
                            Icons.location_on,
                            color: Color(0xFF503663),
                          ),
                          onPressed: () => _viewPatientLocation(
                            patient['id'],
                            patient['name'] ?? 'Unknown Patient',
                          ),
                          tooltip: 'View Location',
                        ),
                        // Disconnect button
                        IconButton(
                          icon: const Icon(
                            Icons.link_off,
                            color: Colors.red,
                          ),
                          onPressed: () => _disconnectFromPatient(
                            patient['id'],
                            patient['name'] ?? 'Unknown Patient',
                          ),
                          tooltip: 'Disconnect',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Connect button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _connectToPatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF503663),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.person_add),
                    SizedBox(width: 8),
                    Text(
                      'CONNECT TO PATIENT',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _locationService.dispose();
    super.dispose();
  }
}

