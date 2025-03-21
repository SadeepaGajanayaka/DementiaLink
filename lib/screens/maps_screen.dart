import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'map_style.dart';
import 'connect.dart';
import 'safe_zone.dart';
import 'permission.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> with WidgetsBindingObserver {
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

  // Services
  final LocationService _locationService = LocationService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final AuthService _authService = AuthService();
  final PermissionHandler _permissionHandler = PermissionHandler();

  // Connected patient info
  String? _connectedPatientId;
  String? _connectedPatientEmail;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _patientLocationAvailable = false;

  // Connected caregiver info (for patient view)
  String? _connectedCaregiverEmail;
  String? _connectedCaregiverId;

  // User role
  String? _userRole;

  // Markers
  final Map<MarkerId, Marker> _markers = {};
  BitmapDescriptor? _patientMarkerIcon;
  BitmapDescriptor? _caregiverMarkerIcon;
  StreamSubscription? _patientLocationSubscription;
  StreamSubscription? _connectionRequestSubscription;
  Timer? _locationRefreshTimer;
  int _locationRequestAttempts = 0;
  bool _showPatientOfflineStatus = false;
  bool _isLocationShared = false;

  @override
  void initState() {
    super.initState();
    print("MapsScreen initState called");
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadCustomMarkers();
    _fetchUserRole();

    // Add this to ensure connection status refreshes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConnectionStatus();
      _verifyAndDisplayConnection(); // Added explicit connection verification
    });
  }

  @override
  void dispose() {
    print("MapsScreen dispose called");
    _patientLocationSubscription?.cancel();
    _connectionRequestSubscription?.cancel();
    _locationRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App was resumed from background - refresh data
      print("App resumed - refreshing location data");
      _getCurrentLocation();
      if (_isConnected && _userRole == 'caregiver') {
        _getPatientLocationImmediately();
        _locationService.triggerUrgentLocationUpdate(_connectedPatientId!); // Enhanced: Use the new method
      }
      _debugMarkersStatus(); // Added for debugging markers
    }
  }

  // New method to verify and display connection status clearly
  void _verifyAndDisplayConnection() async {
    try {
      final connectionInfo = await _locationService.getConnectedPatient();
      print("Connection verify result: $connectionInfo");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(connectionInfo['connected']
                ? 'Connected to: ${_userRole == 'patient' ? connectionInfo['caregiverEmail'] : connectionInfo['patientEmail']}'
                : 'Not connected to anyone'),
            backgroundColor: connectionInfo['connected'] ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Connection verification error: $e");
    }
  }

  // New method to debug markers status
  void _debugMarkersStatus() {
    print("Current markers (${_markers.length}):");
    _markers.forEach((key, marker) {
      print("- ${key.value}: ${marker.position.latitude}, ${marker.position.longitude}");
    });

    if (_userRole == 'caregiver' && !_markers.containsKey(const MarkerId('patientLocation'))) {
      print("WARNING: Patient marker not found in the markers collection!");
    }
  }

  // Start listening for connection requests (for patients)
  void _startListeningForConnectionRequests() {
    // Only set up the listener if the user is a patient
    if (_userRole != 'patient') {
      print("User is not a patient, skipping connection request listener");
      return;
    }

    print("Starting to listen for connection requests");
    _connectionRequestSubscription = _permissionHandler
        .listenForConnectionRequests()
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        print("New connection request received: ${event.snapshot.key}");

        // Extract request data
        final requestData = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Add requestId to data if not present
        if (!requestData.containsKey('requestId')) {
          requestData['requestId'] = event.snapshot.key;
        }

        // Show permission dialog only if the request is pending
        if (requestData['status'] == 'pending') {
          // Show permission dialog on the main thread
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPermissionDialog(requestData);
          });
        }
      }
    }, onError: (error) {
      print("Error in connection request stream: $error");
    });
  }

  // Show permission dialog for connection request
  void _showPermissionDialog(Map<String, dynamic> requestData) {
    print("Showing permission dialog for request: ${requestData['requestId']}");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionDialog(
        requestData: requestData,
      ),
    ).then((accepted) {
      if (accepted == true) {
        // Request was accepted, update connection status
        _checkConnectionStatus();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sharing enabled'),
            backgroundColor: Colors.green,
          ),
        );

        // Start location sharing
        _locationService.startTracking();
        setState(() {
          _isLocationShared = true;
        });
      }
    });
  }

  // Check current connection status with improved error handling
  Future<void> _checkConnectionStatus() async {
    try {
      if (_authService.currentUser == null) {
        print("Cannot check connection: No authenticated user");
        return;
      }

      final connectionInfo = await _locationService.getConnectedPatient();
      print("Connection status check result: $connectionInfo");

      if (connectionInfo['connected']) {
        setState(() {
          _isConnected = true;

          if (_userRole == 'caregiver') {
            _connectedPatientId = connectionInfo['patientId'];
            _connectedPatientEmail = connectionInfo['patientEmail'];
            _startTrackingPatient();
          } else if (_userRole == 'patient') {
            _connectedCaregiverId = connectionInfo['caregiverId'];
            _connectedCaregiverEmail = connectionInfo['caregiverEmail'];
            _isLocationShared = true;
            _locationService.startTracking(); // Ensure location tracking is active
          }
        });
      } else {
        setState(() {
          _isConnected = false;
          _connectedPatientId = null;
          _connectedPatientEmail = null;
          _connectedCaregiverId = null;
          _connectedCaregiverEmail = null;
          _isLocationShared = false;
        });
      }
    } catch (e) {
      print("Error checking connection status: $e");
      // Added error handling with user feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error checking connection status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Fetch the user role and configure based on role
  Future<void> _fetchUserRole() async {
    try {
      final userId = _authService.currentUser?.uid;
      if (userId != null) {
        final userData = await _authService.getUserData(userId);

        if (mounted) {
          setState(() {
            _userRole = userData['role'] as String?;
          });
        }

        print("User role: $_userRole");

        // If user is a patient, start listening for connection requests
        if (_userRole == 'patient') {
          // Start listening for connection requests
          _startListeningForConnectionRequests();

          await _locationService.startTracking();
          print("Patient location tracking started automatically");

          // Check if connected to any caregiver
          final connectionInfo = await _locationService.getConnectedPatient();
          if (connectionInfo['connected']) {
            if (mounted) {
              setState(() {
                _connectedCaregiverId = connectionInfo['caregiverId'];
                _connectedCaregiverEmail = connectionInfo['caregiverEmail'];
                _isConnected = true;
                _isLocationShared = true;
              });

              print("Patient connected to caregiver: $_connectedCaregiverEmail");

              // Ensure the caregiver email isn't null for display
              if (_connectedCaregiverEmail == null) {
                // Fall back to using caregiverEmail directly from connection data
                _connectedCaregiverEmail = connectionInfo['caregiverEmail'] ?? 'Unknown Caregiver';
                print("Setting caregiver email from connection data: $_connectedCaregiverEmail");
              }
            }
          }
        } else if (_userRole == 'caregiver') {
          // Automatically check for existing connections for caregiver
          final connectionInfo = await _locationService.getConnectedPatient();
          if (connectionInfo['connected']) {
            if (mounted) {
              setState(() {
                _connectedPatientId = connectionInfo['patientId'];
                _connectedPatientEmail = connectionInfo['patientEmail'];
                _isConnected = true;
              });

              print("Caregiver connected to patient: $_connectedPatientEmail");

              // Start tracking the patient immediately
              _startTrackingPatient();
            }
          }
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading user data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Initialize the location service and check for existing connections
  Future<void> _initializeServices() async {
    try {
      print("Initializing location service...");
      await _locationService.initialize();

      // Get current location (don't move camera yet)
      await _getCurrentLocation();

      // Start tracking current user's location
      await _locationService.startTracking();
    } catch (e) {
      print("Error initializing services: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error initializing location services: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Load custom marker icons for patient and caregiver
  Future<void> _loadCustomMarkers() async {
    try {
      _patientMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'lib/assets/patient_marker.png',
      );

      _caregiverMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'lib/assets/caregiver_marker.png',
      );

      print("Custom markers loaded successfully");
    } catch (error) {
      print("Error loading custom markers: $error");
      _patientMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      _caregiverMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable to use the map.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // Check location permission
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Some features may not work.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    // Get current location without moving camera
    try {
      _currentLocation = await _location.getLocation();
      print("Current location obtained: ${_currentLocation?.latitude}, ${_currentLocation?.longitude}");

      // Add marker for current user
      _updateCurrentLocationMarker();

      // If this is the patient, update location in Firebase immediately
      if (_userRole == 'patient') {
        await _locationService.startTracking();
      }
    } catch (e) {
      print("Error getting current location: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing your location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update the current user's location marker
  void _updateCurrentLocationMarker() {
    if (_currentLocation == null || !mounted) return;

    final markerId = const MarkerId('currentLocation');
    final marker = Marker(
      markerId: markerId,
      position: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
      infoWindow: InfoWindow(
        title: _userRole == 'patient' ? 'My Location (Patient)' : 'My Location (Caregiver)',
      ),
      icon: _userRole == 'patient'
          ? (_patientMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet))
          : (_caregiverMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure)),
    );

    setState(() {
      _markers[markerId] = marker;
    });

    print("Current location marker updated: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}");
  }

  // Method to center on user's location when explicitly requested
  void _centerOnCurrentLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          16, // Zoom level
        ),
      );
      print("Centered map on current location");
    } else {
      _getCurrentLocation().then((_) {
        if (_currentLocation != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
              16, // Zoom level
            ),
          );
          print("Fetched location and centered map");
        }
      });
    }
  }

  // Center on patient's location
  void _centerOnPatientLocation() {
    if (_mapController != null && _markers.containsKey(const MarkerId('patientLocation'))) {
      final patientMarker = _markers[const MarkerId('patientLocation')]!;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          patientMarker.position,
          16, // Zoom level
        ),
      );
      print("Centered on existing patient marker");
    } else {
      if (_isConnected) {
        _getPatientLocationImmediately().then((_) {
          if (_markers.containsKey(const MarkerId('patientLocation')) && _mapController != null) {
            final patientMarker = _markers[const MarkerId('patientLocation')]!;
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                patientMarker.position,
                16, // Zoom level
              ),
            );
            print("Got patient location and centered map");
          } else {
            // Try one more time with the urgent trigger method
            _locationService.triggerUrgentLocationUpdate(_connectedPatientId!);
            Future.delayed(const Duration(seconds: 2), () {
              if (_markers.containsKey(const MarkerId('patientLocation')) && _mapController != null) {
                final patientMarker = _markers[const MarkerId('patientLocation')]!;
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    patientMarker.position,
                    16, // Zoom level
                  ),
                );
                print("Used urgent method and centered map");
              } else {
                print("Still cannot find patient marker after urgent request");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Patient location is not available yet. They may need to open the app.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            });
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No patient connected. Please connect with a patient first.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Toggle live location tracking
  void _toggleLiveLocation(bool value) {
    setState(() {
      _liveLocationEnabled = value;
    });

    if (_liveLocationEnabled) {
      _location.onLocationChanged.listen((LocationData currentLocation) {
        if (!mounted) return;

        setState(() {
          _currentLocation = currentLocation;
        });

        // Update current location marker
        _updateCurrentLocationMarker();

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            ),
          );
        }
      });
      print("Live location tracking enabled");
    } else {
      print("Live location tracking disabled");
    }
  }

  // IMPROVED: Start tracking the connected patient's location with better reliability
  void _startTrackingPatient() {
    if (_connectedPatientId == null) {
      print("Cannot start tracking: No connected patient ID");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patient connected. Please connect with a patient first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print("Starting to track patient: $_connectedPatientId");

    // Cancel existing subscription if any
    _patientLocationSubscription?.cancel();
    _locationRefreshTimer?.cancel();

    // Reset patient location status
    setState(() {
      _patientLocationAvailable = false;
      _showPatientOfflineStatus = false;
      _locationRequestAttempts = 0;
      _isConnecting = true; // Show loading state
    });

    // CRITICAL FIX: Immediately request latest location with the improved method
    _locationService.triggerUrgentLocationUpdate(_connectedPatientId!);

    // Create a timer to periodically check for patient location if not available
    _locationRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_patientLocationAvailable && _isConnected && mounted) {
        print("Periodic location check - attempt: ${_locationRequestAttempts + 1}");
        _locationRequestAttempts++;
        _getPatientLocationImmediately();

        // Every second attempt, also try the urgent trigger method
        if (_locationRequestAttempts % 2 == 0) {
          _locationService.triggerUrgentLocationUpdate(_connectedPatientId!);
        }

        // Show offline message after 3 failed attempts
        if (_locationRequestAttempts > 3 && !_showPatientOfflineStatus) {
          setState(() {
            _showPatientOfflineStatus = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Patient may be offline. Location updates will appear when they open the app.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Stop checking after 10 attempts (50 seconds)
        if (_locationRequestAttempts > 10) {
          print("Stopping periodic location check after 10 attempts");
          timer.cancel();
          setState(() {
            _isConnecting = false;
          });
        }
      } else if (_patientLocationAvailable) {
        // Once we have the location, we can stop the timer
        print("Patient location available, stopping periodic checks");
        timer.cancel();
        setState(() {
          _isConnecting = false;
        });
      }
    });

    // FIXED: Improved error handling in location stream subscription
    _patientLocationSubscription = _locationService
        .getPatientLocationStream(_connectedPatientId!)
        .listen((DatabaseEvent event) {
      if (!mounted) return;

      print("Received patient location update event");
      _processPatientLocationUpdate(event);
    }, onError: (error) {
      print("Error in patient location stream: $error");
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    });

    print("Patient location subscription set up");

    // Make an immediate request for the patient's location
    _getPatientLocationImmediately();
  }

  // IMPROVED: Process patient location updates from Firebase
  void _processPatientLocationUpdate(DatabaseEvent event) {
    if (!mounted) return;

    if (event.snapshot.value != null) {
      try {
        print("Processing location update from stream");
        // Extract location data
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Debug the entire data received
        print("Received data: ${data.keys.join(', ')}");

        // Check if the location data contains valid coordinates
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          double? latitude = data['latitude'];
          double? longitude = data['longitude'];

          if (latitude != null && longitude != null) {
            print("Valid location data received: $latitude, $longitude");

            // Create patient marker
            final markerId = const MarkerId('patientLocation');
            final marker = Marker(
              markerId: markerId,
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: 'Patient',
                snippet: _connectedPatientEmail ?? 'Connected Patient',
              ),
              icon: _patientMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            );

            setState(() {
              _markers[markerId] = marker;
              _isConnecting = false;
              _patientLocationAvailable = true;
              _showPatientOfflineStatus = false;
            });

            print("Patient marker updated on map");
            _debugMarkersStatus();

            // Only center on patient location if it's the first time we're getting it
            if (!_patientLocationAvailable && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(latitude, longitude),
                  16, // Zoom level
                ),
              );
            }
          } else {
            print("Received null coordinates in patient location data");
          }
        } else {
          print("Incomplete location data received: $data");
        }
      } catch (e) {
        print("Error processing patient location update: $e");
      }
    } else {
      print("Received null value for patient location");
    }
  }

  // IMPROVED: Method to get patient location immediately with better error handling
  Future<void> _getPatientLocationImmediately() async {
    if (_connectedPatientId == null || !mounted) return;

    try {
      print("Requesting immediate patient location update");

      // Request an update for tracking
      DatabaseReference patientLocationRef = _database
          .ref()
          .child('locations')
          .child(_connectedPatientId!);

      // Ask for an update by setting a timestamp and more explicit flags
      await patientLocationRef.update({
        'trackedAt': ServerValue.timestamp,
        'trackRequest': true,
        'requester': {
          'id': _authService.currentUser?.uid,
          'email': _authService.currentUser?.email,
          'requestTime': DateTime.now().toIso8601String(),
        },
        'track_request_count': ServerValue.increment(1)
      });

      // Get the current data directly
      DataSnapshot snapshot = await patientLocationRef.get();

      if (snapshot.exists) {
        print("Patient location data exists in database");
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print("Patient location data keys: ${data.keys.join(', ')}");

        // Check if we have actual location data
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          double? latitude = data['latitude'];
          double? longitude = data['longitude'];

          if (latitude != null && longitude != null) {
            print("Got valid location coordinates: $latitude, $longitude");

            // Create patient marker
            final markerId = const MarkerId('patientLocation');
            final marker = Marker(
              markerId: markerId,
              position: LatLng(latitude, longitude),
              infoWindow: InfoWindow(
                title: 'Patient',
                snippet: _connectedPatientEmail ?? 'Connected Patient',
              ),
              icon: _patientMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            );

            if (mounted) {
              setState(() {
                _markers[markerId] = marker;
                _isConnecting = false;
                _patientLocationAvailable = true;
                _showPatientOfflineStatus = false;
              });
            }

            // Center on patient location
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(latitude, longitude),
                  16, // Zoom level
                ),
              );
            }

            // Debug markers
            _debugMarkersStatus();

            // Location found successfully
            return;
          }
        }

        // If we reach here, we have a record but no valid location
        print("Patient record exists but no valid location data");
      } else {
        print("No patient location record exists yet");
      }

      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    } catch (e) {
      print("Error getting immediate patient location: $e");
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  // Method to terminate loading state after a delay
  void _startLoadingTimeout() {
    // Automatically end loading state after 15 seconds if not already ended
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isConnecting) {
        setState(() {
          _isConnecting = false;
        });

        // Show a timeout message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient location request timed out. They may need to share their location.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  // Position the map based on available data
  void _positionMapInitially() {
    if (_mapController == null) return;

    // First priority: Center on patient if caregiver and location is available
    if (_userRole == 'caregiver' && _isConnected && _markers.containsKey(const MarkerId('patientLocation'))) {
      final patientMarker = _markers[const MarkerId('patientLocation')]!;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          patientMarker.position,
          16, // Zoom level
        ),
      );
      print("Positioned map initially on patient location");
    }
    // Second priority: Center on user's location if available
    else if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          16, // Zoom level
        ),
      );
      print("Positioned map initially on user's current location");
    }
    // Fall back to initial position
    else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
      print("Positioned map at default location (Sri Lanka)");
    }
  }

  // Improved connect dialog method with better input validation and error handling
  Future<void> _showConnectDialog() async {
    if (_userRole == null) {
      // First fetch user role if not already done
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to use location tracking'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final userData = await _authService.getUserData(userId);
        setState(() {
          _userRole = userData['role'] as String?;
        });
      } catch (e) {
        print("Error fetching user role: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading user data: $e"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_userRole == 'caregiver') {
      // CAREGIVER FLOW: Show connect dialog to enter patient email or ID
      setState(() {
        _isConnecting = true;
      });

      // Display connection dialog
      final patientIdentifier = await Navigator.of(context).push<String>(
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

      // If no identifier was returned (user canceled), stop here
      if (patientIdentifier == null || patientIdentifier.isEmpty) {
        setState(() {
          _isConnecting = false;
        });
        return;
      }

      // Show searching message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Searching for patient...'),
          duration: Duration(seconds: 2),
        ),
      );

      try {
        // Directly use the improved connectWithPatient method that handles both email and UIDs
        final result = await _locationService.connectWithPatient(patientIdentifier);

        if (result['success']) {
          if (mounted) {
            // Connection successful
            setState(() {
              _connectedPatientId = result['patientId'];
              _connectedPatientEmail = result['patientEmail'];
              _isConnected = true;
              _isConnecting = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully connected with ${result['patientEmail']}'),
                backgroundColor: Colors.green,
              ),
            );

            // IMPROVED: Start tracking the patient immediately with trigger for urgent update
            _startTrackingPatient();
            // Make a second request after a slight delay for reliability
            Future.delayed(Duration(seconds: 1), () {
              if (_connectedPatientId != null) {
                _locationService.triggerUrgentLocationUpdate(_connectedPatientId!);
              }
            });
          }
        } else {
          // Connection failed
          if (mounted) {
            setState(() {
              _isConnecting = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${result['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        print("Error connecting with patient: $e");
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (_userRole == 'patient') {
      // PATIENT FLOW: Show current connection status
      setState(() {
        _isConnecting = true;
      });

      try {
        // Get current connection info
        final connectionInfo = await _locationService.getConnectedPatient();

        if (connectionInfo['connected']) {
          // Patient is connected to a caregiver
          setState(() {
            _connectedCaregiverId = connectionInfo['caregiverId'];
            _connectedCaregiverEmail = connectionInfo['caregiverEmail'];
            _isConnected = true;
            _isConnecting = false;
            _isLocationShared = true;
          });

          // Show connected status
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are sharing location with: $_connectedCaregiverEmail'),
              backgroundColor: Colors.green,
            ),
          );

          // Ensure location sharing is active
          await _locationService.startTracking();
          await _locationService.ensurePatientLocationIsTracked();
        } else {
          // Patient is not connected to anyone
          setState(() {
            _isConnecting = false;
            _isLocationShared = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not connected with any caregiver. Caregivers can request to track your location.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        print("Error checking patient connection: $e");
        setState(() {
          _isConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking connection status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Role not properly set
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete your profile setup first by selecting a role (patient or caregiver).'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isConnecting = false;
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
                      const SizedBox(width: 8), // Added spacing
                      const Expanded(
                        child: Text(
                          'Location Tracking',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24, // Reduced font size to prevent overflow
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center, // Ensure text is centered
                        ),
                      ),
                      const SizedBox(width: 8), // Added spacing
                      // Brain icon - using the specified asset with adjusted size
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Image.asset(
                          'lib/assets/images/brain_icon.png',
                          width: 40, // Reduced size to prevent overflow
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.psychology,
                            color: Colors.white,
                            size: 35,
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
                              color: Colors.black,
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
              child: GoogleMap(
                // Improve responsiveness with these settings
                compassEnabled: true,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
                initialCameraPosition: _initialCameraPosition,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                padding: const EdgeInsets.only(top: 10),
                markers: Set<Marker>.of(_markers.values),
                onMapCreated: (controller) {
                  setState(() {
                    _mapController = controller;
                  });

                  // Apply the custom map style with improved error handling
                  try {
                    print("Attempting to apply custom map style...");
                    controller.setMapStyle(MapStyle.mapStyle);
                    print("Map style applied successfully");
                  } catch (e) {
                    print("Error applying map style: $e");
                  }

                  // FIXED: After map is created, check if we need to show patient location
                  if (_userRole == 'caregiver' && _isConnected && _connectedPatientId != null) {
                    print("Map created and caregiver connected to patient - starting tracking");
                    // Slight delay to ensure map is fully ready
                    Future.delayed(Duration(milliseconds: 500), () {
                      _startTrackingPatient();
                    });
                  } else if (_userRole == 'patient') {
                    print("Map created for patient - ensuring location sharing is active");
                    _locationService.ensurePatientLocationIsTracked();
                  }

                  // Position the map appropriately based on available data
                  _positionMapInitially();
                },
              ),
            ),
          ),

          // UI elements on top of map
          Positioned(
            top: 30, // Moved a tiny bit lower
            left: 0,
            right: 0,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.85, // Use 85% of screen width
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

                                  // Navigate to SafeZoneScreen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SafeZoneScreen(),
                                    ),
                                  );
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
                                  child: const Center(
                                    child: Text(
                                      'Safe Zone Alert',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 15, // Reduced font size to avoid overflow
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
                                  child: const Center(
                                    child: Text(
                                      'Red Alert',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        fontSize: 15, // Reduced font size to avoid overflow
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Connected user info box - shows either patient or caregiver info based on role
                      if (_isConnected)
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFECE5F1),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person_pin_circle,
                                color: Color(0xFF503663),
                                size: 18, // Reduced size
                              ),
                              const SizedBox(width: 4), // Reduced spacing
                              Expanded(
                                child: _userRole == 'patient'
                                    ? Text(
                                  'Sharing with: ${_connectedCaregiverEmail ?? 'Caregiver'}',
                                  style: const TextStyle(
                                    color: Color(0xFF503663),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13, // Reduced font size
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                                    : Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Tracking: ${_connectedPatientEmail ?? 'Patient'}',
                                        style: const TextStyle(
                                          color: Color(0xFF503663),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13, // Reduced font size
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_patientLocationAvailable)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 14, // Reduced size
                                        ),
                                      )
                                    else if (_showPatientOfflineStatus)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4.0),
                                        child: Icon(
                                          Icons.offline_bolt,
                                          color: Colors.orange,
                                          size: 14, // Reduced size
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_userRole == 'caregiver' && _patientLocationAvailable)
                                IconButton(
                                  icon: const Icon(
                                    Icons.center_focus_strong,
                                    color: Color(0xFF503663),
                                    size: 18, // Reduced size
                                  ),
                                  onPressed: _centerOnPatientLocation,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6), // Reduced padding
                                  visualDensity: VisualDensity.compact, // Make button more compact
                                  tooltip: 'Focus on patient',
                                ),
                            ],
                          ),
                        ),

                      // Location sharing status for patients
                      if (_userRole == 'patient')
                        Container(
                          decoration: BoxDecoration(
                            color: _isLocationShared ? const Color(0xFFE5F1E9) : const Color(0xFFF1E5E5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                _isLocationShared ? Icons.location_on : Icons.location_off,
                                color: _isLocationShared ? Colors.green : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isLocationShared
                                      ? 'Location sharing is active'
                                      : 'Location sharing is inactive',
                                  style: TextStyle(
                                    color: _isLocationShared ? Colors.green.shade800 : Colors.red.shade800,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Live location toggle
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF503663),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                // Location pin icon next to "Live Location" text
                                Image.asset(
                                  'lib/assets/location_pin.png',
                                  width: 20, // Reduced size
                                  height: 20, // Reduced size
                                  color: Colors.white,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: 20, // Reduced size
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Live Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16, // Reduced font size
                                  ),
                                ),
                              ],
                            ),
                            Transform.scale(
                              scale: 0.8, // Scale down the switch
                              child: Switch(
                                value: _liveLocationEnabled,
                                onChanged: _toggleLiveLocation,
                                activeColor: Colors.white,
                                activeTrackColor: const Color(0xFF6246A3),
                                inactiveTrackColor: Colors.grey[700],
                                inactiveThumbColor: Colors.white,
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
          ),

          // Position buttons at right side
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
                  size: 28, // Reduced size
                ),
                iconSize: 46, // Reduced size
                onPressed: _centerOnCurrentLocation,
              ),
            ),
          ),

          // Second circle (Target location button) - moved closer to the first one
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.47, // Adjusted position
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
                  size: 28, // Reduced size
                ),
                iconSize: 46, // Reduced size
                onPressed: _getCurrentLocation,
              ),
            ),
          ),

          // Connect button (bottom right corner)
          // Only show for caregivers (patients can't initiate connections)
          if (_userRole == 'caregiver')
      Positioned(
      bottom: 20,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: _isConnected ? Colors.green : const Color(0xFF77588D),
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
            onTap: _isConnecting ? null : () {
              _showConnectDialog();
              _startLoadingTimeout(); // Start the timeout timer
            },
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24, // Reduced horizontal padding
                vertical: 10, // Reduced vertical padding
              ),
              child: _isConnecting
                  ? const SizedBox(
                height: 22, // Reduced size
                width: 22, // Reduced size
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isConnected ? Icons.link : Icons.link_off,
                    color: Colors.white,
                    size: 18, // Reduced size
                  ),
                  const SizedBox(width: 6), // Reduced spacing
                  Text(
                    _isConnected ? 'Connected' : 'Connect',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16, // Reduced font size
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

    // Connection status button for patients (shows current sharing status)
    if (_userRole == 'patient')
    Positioned(
    bottom: 20,
    right: 16,
    child: Container(
    decoration: BoxDecoration(
    color: _isConnected ? Colors.green : const Color(0xFF77588D),
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
    onTap: _isConnecting ? null : () {
    // For patients, this will just show the current connection status
    _checkConnectionStatus();
    _verifyAndDisplayConnection();

    // IMPROVED: Ensure location tracking is active
    if (_isConnected) {
    _locationService.ensurePatientLocationIsTracked();
    }

    // Show appropriate message
    if (_isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
    content: Text('You are sharing your location with: $_connectedCaregiverEmail'),
    backgroundColor: Colors.green,
    ),
    );
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
    content: Text('No caregiver is currently tracking your location.'),
    backgroundColor: Colors.blue,
    ),
    );
    }
    },
    borderRadius: BorderRadius.circular(30),
    child: Padding(
    padding: const EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 10,
    ),
    child: _isConnecting
    ? const SizedBox(
    height: 22,
    width: 22,
    child: CircularProgressIndicator(
    color: Colors.white,
    strokeWidth: 2,
    ),
    )
        : Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    Icon(
    _isConnected ? Icons.visibility : Icons.visibility_off,
    color: Colors.white,
    size: 18,
    ),
    const SizedBox(width: 6),
    Text(
    _isConnected ? 'Sharing Location' : 'Not Being Tracked',
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

    // Offline message if patient is not sharing location
    if (_isConnected && _userRole == 'caregiver' && _showPatientOfflineStatus)
    Positioned(
    top: MediaQuery.of(context).size.height * 0.2,
    left: 16,
    right: 16,
    child: Center(
    child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reduced padding
    decoration: BoxDecoration(
    color: Colors.orange.shade100,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
    BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 4,
    offset: const Offset(0, 2),
    ),
    ],
    border: Border.all(color: Colors.orange, width: 1),
    ),
    child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    const Icon(
    Icons.info_outline,
    color: Colors.orange,
    size: 16, // Reduced size
    ),
    const SizedBox(width: 6), // Reduced spacing
    Flexible(
      child: Text(
        'Patient may be offline. Updates will appear when they come online.',
        style: TextStyle(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 12, // Reduced font size
        ),
        textAlign: TextAlign.center,
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
            ],
          ),
      ),
    );
  }
}
