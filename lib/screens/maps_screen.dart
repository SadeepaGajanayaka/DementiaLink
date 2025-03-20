import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'map_style.dart';
import 'connect.dart';
import 'safe_zone.dart';
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

  // Connected patient info
  String? _connectedPatientId;
  String? _connectedPatientEmail;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _patientLocationAvailable = false;

  // Connected caregiver info (for patient view)
  String? _connectedCaregiverEmail;

  // User role
  String? _userRole;

  // Markers
  final Map<MarkerId, Marker> _markers = {};
  BitmapDescriptor? _patientMarkerIcon;
  BitmapDescriptor? _caregiverMarkerIcon;
  StreamSubscription? _patientLocationSubscription;
  Timer? _locationRefreshTimer;
  int _locationRequestAttempts = 0;
  bool _showPatientOfflineStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadCustomMarkers();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _patientLocationSubscription?.cancel();
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

        // If user is a patient, automatically start sharing location
        if (_userRole == 'patient') {
          await _locationService.startTracking();
          print("Patient location tracking started automatically");

          // Check if connected to any caregiver
          final connectionInfo = await _locationService.getConnectedPatient();
          if (connectionInfo['connected']) {
            if (mounted) {
              setState(() {
                _connectedPatientId = connectionInfo['patientId']; // This will be caregiver's ID for patient
                _connectedCaregiverEmail = connectionInfo['caregiverEmail'];
                _isConnected = true;
              });

              print("Patient connected to caregiver: $_connectedCaregiverEmail");
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
      print("Error fetching user role: $e");
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
    } else {
      _getCurrentLocation().then((_) {
        if (_currentLocation != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
              16, // Zoom level
            ),
          );
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
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Patient location is not available yet. They may need to open the app.'),
                backgroundColor: Colors.orange,
              ),
            );
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
    }
  }

  // Start tracking the connected patient's location
  void _startTrackingPatient() {
    if (_connectedPatientId == null) {
      print("Cannot start tracking: No connected patient ID");
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
    });

    // Create a timer to periodically check for patient location if not available
    _locationRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_patientLocationAvailable && _isConnected && mounted) {
        print("Periodic location check - attempt: ${_locationRequestAttempts + 1}");
        _locationRequestAttempts++;
        _getPatientLocationImmediately();

        // Show offline message after 3 failed attempts (30 seconds)
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

        // Stop checking after 12 attempts (2 minutes)
        if (_locationRequestAttempts > 12) {
          print("Stopping periodic location check after 12 attempts");
          timer.cancel();
        }
      } else if (_patientLocationAvailable) {
        // Once we have the location, we can stop the timer
        print("Patient location available, stopping periodic checks");
        timer.cancel();
      }
    });

    // Listen to patient location updates
    _patientLocationSubscription = _locationService
        .getPatientLocationStream(_connectedPatientId!)
        .listen((DatabaseEvent event) {
      if (!mounted) return;

      print("Received patient location update event");

      if (event.snapshot.value != null) {
        try {
          // Extract location data
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

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
          } else if (data.containsKey('trackRequest') || data.containsKey('trackedAt')) {
            // This is just a tracking request, not actual location data
            print("Received tracking request or timestamp update, not location data");
          } else {
            print("Incomplete location data received: $data");
          }
        } catch (e) {
          print("Error processing patient location update: $e");
        }
      } else {
        print("Received null value for patient location");
      }
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

  // New method to get patient location immediately with improved error handling
  Future<void> _getPatientLocationImmediately() async {
    if (_connectedPatientId == null || !mounted) return;

    try {
      print("Requesting immediate patient location update");

      // Request an update for tracking
      DatabaseReference patientLocationRef = _database
          .ref()
          .child('locations')
          .child(_connectedPatientId!);

      // Ask for an update by setting a timestamp
      await patientLocationRef.update({
        'trackedAt': ServerValue.timestamp,
        'trackRequest': true
      });

      // Get the current data directly
      DataSnapshot snapshot = await patientLocationRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

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

            // Location found successfully
            return;
          }
        }

        // If we reach here, we have a record but no valid location
        print("Patient record exists but no valid location data");
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
        }
      } else {
        print("No patient location record exists yet");
        if (mounted) {
          setState(() {
            _isConnecting = false;
          });
        }
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

  // Improved connect dialog method with better feedback
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
      // CAREGIVER FLOW: Show connect dialog to enter patient email
      setState(() {
        _isConnecting = true;
      });

      // Display connection dialog
      final patientId = await Navigator.of(context).push<String>(
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

      // Handle connection result
      if (patientId != null) {
        // Connection was successful
        setState(() {
          _connectedPatientId = patientId;
          _isConnected = true;
        });

        // Get patient email for display
        final connectionInfo = await _locationService.getConnectedPatient();
        if (connectionInfo['connected']) {
          setState(() {
            _connectedPatientEmail = connectionInfo['patientEmail'];
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected with patient: $_connectedPatientEmail'),
            backgroundColor: Colors.green,
          ),
        );

        // Start tracking patient location immediately
        _startTrackingPatient();

        // Show searching message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Searching for patient\'s location...'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // User canceled the connection dialog
        setState(() {
          _isConnecting = false;
        });
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
            _connectedPatientId = connectionInfo['patientId']; // This will be caregiver's ID
            _connectedCaregiverEmail = connectionInfo['caregiverEmail'];
            _isConnected = true;
            _isConnecting = false;
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
        } else {
          // Patient is not connected to anyone
          setState(() {
            _isConnecting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are not connected with any caregiver. Ask them to connect with your email.'),
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

  // Add a method to terminate loading state after a delay
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
                        initialCameraPosition: _initialCameraPosition,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        padding: const EdgeInsets.only(top: 10),
                        markers: Set<Marker>.of(_markers.values),
                        onMapCreated: (controller) {
                          setState(() {
                            _mapController = controller;
                          });

                          // Apply the custom map style
                          _mapController!.setMapStyle(MapStyle.mapStyle);

                          // Position the map appropriately based on available data
                          _positionMapInitially();
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
                                          child: const Center(
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

                              // Connected patient/caregiver info box - enhanced with role-based display
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
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _userRole == 'patient'
                                            ? Text(
                                          'Sharing with: $_connectedCaregiverEmail',
                                          style: const TextStyle(
                                            color: Color(0xFF503663),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                            : Row(
                                          children: [
                                            Text(
                                              'Tracking: $_connectedPatientEmail',
                                              style: const TextStyle(
                                                color: Color(0xFF503663),
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (_patientLocationAvailable)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 16,
                                              )
                                            else if (_showPatientOfflineStatus)
                                              const Icon(
                                                Icons.offline_bolt,
                                                color: Colors.orange,
                                                size: 16,
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_userRole == 'caregiver')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.center_focus_strong,
                                            color: Color(0xFF503663),
                                            size: 20,
                                          ),
                                          onPressed: _centerOnPatientLocation,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                          tooltip: 'Focus on patient',
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
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Location pin icon next to "Live Location" text
                                        Image.asset(
                                          'lib/assets/location_pin.png',
                                          width: 24,
                                          height: 24,
                                          color: Colors.white,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.location_on,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Live Location',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 18, // Increased font size
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

                  // Connect button (bottom right corner)
                  // Only show for caregivers or patients who aren't connected yet
                  if (_userRole != 'patient' || !_isConnected)
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
                                horizontal: 32,
                                vertical: 12,
                              ),
                              child: _isConnecting
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
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
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _userRole == 'patient'
                                        ? 'Check Connection'
                                        : (_isConnected ? 'Connected' : 'Connect'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18, // Increased font size
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
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Patient may be offline. Updates will appear when they come online.',
                                style: TextStyle(
                                  color: Colors.orange,
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
            ),
          ],
        ),
      ),
    );
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
    }
    // Second priority: Center on user's location if available
    else if (_currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          16, // Zoom level
        ),
      );
    }
    // Fall back to initial position
    else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_initialCameraPosition),
      );
    }
  }
}