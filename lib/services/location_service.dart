import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isTracking = false;
  bool _isInitialized = false;
  StreamSubscription<LocationData>? _locationSubscription;
  Timer? _heartbeatTimer;

  // Cache the last known location
  LocationData? _lastKnownLocation;

  // Initialize the location service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    print("Initializing location service...");
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    try {
      // Check if location service is enabled
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          print("Location service not enabled");
          return false;
        }
      }

      // Check location permission
      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          print("Location permission not granted");
          return false;
        }
      }

      // Configure location settings - higher accuracy and faster updates
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 3000, // Update every 3 seconds
        distanceFilter: 3, // Minimum distance (meters) to trigger updates
      );

      // Enable background mode if available
      try {
        await _location.enableBackgroundMode(enable: true);
        print("Background mode enabled for location tracking");
      } catch (e) {
        print("Could not enable background mode: $e");
        // Continue anyway, as this is not critical
      }

      _isInitialized = true;
      print("Location service initialized successfully");
      return true;
    } catch (e) {
      print("Error initializing location service: $e");
      return false;
    }
  }

  // Start tracking and broadcasting location
  Future<bool> startTracking() async {
    if (_isTracking) return true;
    print("Starting location tracking...");

    try {
      if (_auth.currentUser == null) {
        print("Cannot start tracking: No authenticated user");
        return false;
      }

      bool initialized = await initialize();
      if (!initialized) {
        print("Failed to initialize location service");
        return false;
      }

      // Set up the database reference
      DatabaseReference userLocationRef = _database.ref().child('locations').child(_auth.currentUser!.uid);

      // Create the locations node with comprehensive data
      await userLocationRef.set({
        'initialized': true,
        'timestamp': ServerValue.timestamp,
        'userEmail': _auth.currentUser!.email,
        'userName': _auth.currentUser!.displayName ?? 'User',
        'userUid': _auth.currentUser!.uid,
        'deviceInfo': {
          'online': true,
          'lastActive': ServerValue.timestamp,
          'appVersion': '1.0.0',
        }
      });

      print("Created initial location entry in Firebase");

      // Get initial location and update immediately
      try {
        LocationData initialLocation = await _location.getLocation();
        _lastKnownLocation = initialLocation;
        await _updateLocationInFirebase(initialLocation);
      } catch (e) {
        print("Error getting initial location: $e");
        // Continue anyway, we'll get updates later
      }

      _isTracking = true;

      // Cancel any existing subscription
      await _locationSubscription?.cancel();
      _heartbeatTimer?.cancel();

      // Create new location subscription
      _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
        if (!_isTracking) return;
        _lastKnownLocation = currentLocation;
        _updateLocationInFirebase(currentLocation);
      }, onError: (e) {
        print("Error in location stream: $e");
        // Try to recover by restarting tracking after a delay
        Future.delayed(Duration(seconds: 5), () {
          if (_isTracking) {
            print("Attempting to restart location tracking after error");
            stopTracking().then((_) => startTracking());
          }
        });
      });

      // Setup a heartbeat timer to keep the location node alive
      // and indicate that device is online
      _heartbeatTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
        if (!_isTracking) {
          timer.cancel();
          return;
        }

        try {
          await userLocationRef.update({
            'deviceInfo': {
              'online': true,
              'lastActive': ServerValue.timestamp,
            }
          });

          // If we haven't received location updates recently, try to get a new one
          if (_lastKnownLocation != null) {
            LocationData currentLocation = await _location.getLocation();
            _lastKnownLocation = currentLocation;
            await _updateLocationInFirebase(currentLocation);
          }
        } catch (e) {
          print("Error updating heartbeat: $e");
        }
      });

      print("Location tracking started for user: ${_auth.currentUser!.uid}");
      return true;
    } catch (e) {
      print("Error starting location tracking: $e");
      _isTracking = false;
      return false;
    }
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    print("Stopping location tracking");
    _isTracking = false;
    await _locationSubscription?.cancel();
    _heartbeatTimer?.cancel();
    _locationSubscription = null;
    _heartbeatTimer = null;

    // Update status to offline
    try {
      if (_auth.currentUser != null) {
        DatabaseReference userLocationRef = _database.ref().child('locations').child(_auth.currentUser!.uid);
        await userLocationRef.update({
          'deviceInfo': {
            'online': false,
            'lastActive': ServerValue.timestamp,
          }
        });
      }
    } catch (e) {
      print("Error updating offline status: $e");
    }
  }

  // Update location in Firebase Realtime Database with improved reliability
  Future<void> _updateLocationInFirebase(LocationData locationData) async {
    if (_auth.currentUser == null) return;

    try {
      if (locationData.latitude == null || locationData.longitude == null) {
        print("Invalid location data, can't update");
        return;
      }

      print("Updating location: ${locationData.latitude}, ${locationData.longitude}");

      // Reference to user location in Firebase
      String userUid = _auth.currentUser!.uid;
      DatabaseReference userLocationRef = _database.ref().child('locations').child(userUid);

      // IMPROVED: First check if the node exists
      DataSnapshot snapshot = await userLocationRef.get();
      if (!snapshot.exists) {
        // If node doesn't exist, create it first with full data
        await userLocationRef.set({
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'heading': locationData.heading,
          'speed': locationData.speed,
          'accuracy': locationData.accuracy,
          'altitude': locationData.altitude,
          'timestamp': ServerValue.timestamp,
          'userEmail': _auth.currentUser!.email,
          'userName': _auth.currentUser!.displayName ?? 'User',
          'deviceInfo': {
            'online': true,
            'lastActive': ServerValue.timestamp,
          }
        });
        print("Created new location node with complete data");
      } else {
        // Update the existing location with timestamp and additional metadata
        await userLocationRef.update({
          'latitude': locationData.latitude,
          'longitude': locationData.longitude,
          'heading': locationData.heading,
          'speed': locationData.speed,
          'accuracy': locationData.accuracy,
          'altitude': locationData.altitude,
          'timestamp': ServerValue.timestamp,
          'userEmail': _auth.currentUser!.email,
          'userName': _auth.currentUser!.displayName ?? 'User',
          'deviceInfo': {
            'online': true,
            'lastActive': ServerValue.timestamp,
          }
        });
      }

      // Also check if there are any urgent tracking requests to clear
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map;
        if (data.containsKey('urgent_location_request') ||
            data.containsKey('trackRequest')) {
          // Clear these flags to indicate we've responded
          await userLocationRef.update({
            'urgent_location_request': false,
            'trackRequest': false,
            'lastLocationUpdateAt': ServerValue.timestamp,
            'respondedToRequest': true
          });
          print("Cleared urgent request flags after location update");
        }
      }

      print("Location updated successfully in Firebase");
    } catch (e) {
      print("Error updating location in Firebase: $e");
    }
  }

  // Enhanced method to ensure patient location is properly tracked
  Future<void> ensurePatientLocationIsTracked() async {
    if (_auth.currentUser == null) return;
    String userId = _auth.currentUser!.uid;

    try {
      // Check if this user is a patient with connected caregiver
      DocumentSnapshot connectionDoc = await _firestore
          .collection('connections')
          .doc(userId)
          .get();

      if (!connectionDoc.exists) {
        print("No connection found for user $userId - not sending location updates");
        return;
      }

      Map<String, dynamic> connectionData = connectionDoc.data() as Map<String, dynamic>;

      // Check if this is a patient (connected to a caregiver)
      if (!connectionData.containsKey('caregiverId')) {
        print("User is not a patient - not sending location updates");
        return;
      }

      print("User is a patient connected to caregiver ${connectionData['caregiverId']} - ensuring location tracking");

      // Start or restart location tracking to ensure it's active
      bool trackingStarted = await startTracking();
      if (!trackingStarted) {
        print("Warning: Could not start location tracking");
      }

      // Verify location node exists with proper data
      DatabaseReference locationRef = _database.ref().child('locations').child(userId);
      DataSnapshot locationSnapshot = await locationRef.get();

      if (!locationSnapshot.exists) {
        print("Location node missing - creating it");
        await locationRef.set({
          'initialized': true,
          'timestamp': ServerValue.timestamp,
          'userEmail': _auth.currentUser!.email,
          'userName': _auth.currentUser!.displayName ?? 'Patient',
          'userUid': userId,
          'deviceInfo': {
            'online': true,
            'lastActive': ServerValue.timestamp,
          }
        });
      }

      // Check if there are any urgent requests pending
      if (locationSnapshot.exists) {
        Map<dynamic, dynamic> data = locationSnapshot.value as Map;
        if (data.containsKey('urgent_location_request') ||
            data.containsKey('trackRequest')) {
          print("Urgent location request found - sending immediate update");

          // Get current location and update immediately
          LocationData currentLocation = await _location.getLocation();
          await _updateLocationInFirebase(currentLocation);
        }
      }
    } catch (e) {
      print("Error in ensurePatientLocationIsTracked: $e");
    }
  }

  // Trigger an urgent location update from a patient
  Future<void> triggerUrgentLocationUpdate(String patientId) async {
    if (patientId.isEmpty) {
      print("Cannot trigger update: Empty patient ID");
      return;
    }

    try {
      print("URGENT: Triggering immediate location update for patient: $patientId");

      // Create the reference path
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);

      // First verify if the node exists
      DataSnapshot snapshot = await patientLocationRef.get();
      if (!snapshot.exists) {
        print("Creating initial location node for patient");
        // Create initial node with request flags
        await patientLocationRef.set({
          'initialized': true,
          'urgent_location_request': true,
          'requested_at': ServerValue.timestamp,
          'requester': {
            'id': _auth.currentUser?.uid,
            'email': _auth.currentUser?.email,
            'timestamp': ServerValue.timestamp
          },
          'priority': 'critical',
          'track_request_count': 1
        });
      } else {
        // Update existing node with multiple flags to ensure delivery
        await patientLocationRef.update({
          'urgent_location_request': true,
          'requested_at': ServerValue.timestamp,
          'requester': {
            'id': _auth.currentUser?.uid,
            'email': _auth.currentUser?.email,
            'timestamp': ServerValue.timestamp
          },
          'priority': 'critical',
          'trackRequest': true,
          'trackedAt': ServerValue.timestamp,
          // Increment request counter to make sure we're changing a value
          'track_request_count': ServerValue.increment(1)
        });
      }

      print("Urgent location request sent for patient");

      // Try a secondary approach - update a different path to trigger change listeners
      try {
        await _database.ref().child('urgent_requests').child(patientId).set({
          'timestamp': ServerValue.timestamp,
          'requesterId': _auth.currentUser?.uid,
          'requesterEmail': _auth.currentUser?.email
        });
        print("Secondary urgent request path updated");
      } catch (e) {
        print("Error updating secondary path: $e");
        // Continue anyway since this is just a backup
      }
    } catch (e) {
      print("Error requesting urgent location update: $e");
      // Retry once with a simplified approach
      try {
        await _database.ref().child('locations').child(patientId).update({
          'trackRequest': true,
          'timestamp': ServerValue.timestamp
        });
        print("Simplified fallback request sent");
      } catch (secondError) {
        print("Even fallback request failed: $secondError");
      }
    }
  }

  // Connect with a patient by email or UID with improved notifications
  Future<Map<String, dynamic>> connectWithPatient(String patientIdentifier) async {
    print("Attempting to connect with patient: $patientIdentifier");

    try {
      if (_auth.currentUser == null) {
        return {
          'success': false,
          'message': 'You must be logged in to connect with a patient',
        };
      }

      // Validate that the identifier isn't the caregiver's own email or UID
      if (_auth.currentUser!.email?.toLowerCase() == patientIdentifier.toLowerCase() ||
          _auth.currentUser!.uid == patientIdentifier) {
        return {
          'success': false,
          'message': 'You cannot connect with yourself. Please enter a different email or ID.',
        };
      }

      // Initialize patientId and patientEmail as nullable variables
      String? patientId;
      String? patientEmail;
      bool isDirectUidLookup = false;

      // Check if the input is an email or possibly a UID
      bool isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(patientIdentifier);

      // If it's not an email format, first try to find user directly by ID
      if (!isEmail) {
        try {
          // Try direct document lookup by ID
          DocumentSnapshot directUserCheck = await _firestore
              .collection('users')
              .doc(patientIdentifier)
              .get();

          if (directUserCheck.exists) {
            patientId = patientIdentifier;
            final userData = directUserCheck.data() as Map<String, dynamic>?;
            patientEmail = userData?['email'] as String?;
            isDirectUidLookup = true;

            print("Found patient directly by ID: $patientId with email: $patientEmail");

            // Check if user is actually a patient
            final patientRole = userData?['role'] as String?;
            if (patientRole != null && patientRole != 'patient') {
              return {
                'success': false,
                'message': 'The specified ID belongs to a caregiver, not a patient.',
              };
            }
          } else {
            print("No user found with direct ID lookup: $patientIdentifier");
          }
        } catch (e) {
          print("Error in direct UID lookup: $e");
          // Continue to alternative lookup methods
        }
      }

      // If not found by direct UID or is email format, try email lookup
      if (!isDirectUidLookup) {
        QuerySnapshot userSnapshot;

        if (isEmail) {
          // Find by email
          userSnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: patientIdentifier)
              .limit(1)
              .get();
        } else {
          // Try to find by UID stored in a field
          userSnapshot = await _firestore
              .collection('users')
              .where('uid', isEqualTo: patientIdentifier)
              .limit(1)
              .get();

          // If not found, try one more lookup method that might help
          if (userSnapshot.docs.isEmpty) {
            // This can catch some edge cases
            userSnapshot = await _firestore
                .collection('users')
                .where('userUid', isEqualTo: patientIdentifier)
                .limit(1)
                .get();
          }
        }

        if (userSnapshot.docs.isEmpty) {
          print("No user found with identifier: $patientIdentifier");
          return {
            'success': false,
            'message': 'No user found with this email address or ID',
          };
        }

        patientId = userSnapshot.docs.first.id;
        final patientData = userSnapshot.docs.first.data() as Map<String, dynamic>;
        patientEmail = patientData['email'] as String?;

        print("Found patient via query with ID: $patientId");

        // Get patient's role to verify they are actually a patient
        final patientRole = patientData['role'] as String?;
        if (patientRole != null && patientRole != 'patient') {
          return {
            'success': false,
            'message': 'The specified email belongs to a caregiver, not a patient.',
          };
        }
      }

      // Make sure patientId is assigned at this point
      if (patientId == null) {
        return {
          'success': false,
          'message': 'Could not determine patient ID from the provided information.',
        };
      }

      // If patientEmail is still null, set a default for display purposes
      patientEmail ??= 'Unknown Email';

      // Check if caregiver is already connected to someone
      DocumentSnapshot existingCaregiverConn = await _firestore.collection('connections').doc(_auth.currentUser!.uid).get();
      if (existingCaregiverConn.exists) {
        // Get existing patient data
        Map<String, dynamic> connData = existingCaregiverConn.data() as Map<String, dynamic>;
        String connPatientId = connData['patientId'] ?? '';

        // If already connected to this patient, just return success
        if (connPatientId == patientId) {
          return {
            'success': true,
            'message': 'Already connected with this patient',
            'patientId': patientId,
            'patientEmail': patientEmail,
          };
        }

        // If connected to a different patient, disconnect first
        await disconnectFromPatient();
      }

      // Check if patient is already connected to a different caregiver
      DocumentSnapshot existingPatientConn = await _firestore.collection('connections').doc(patientId).get();
      if (existingPatientConn.exists) {
        Map<String, dynamic> connData = existingPatientConn.data() as Map<String, dynamic>;
        String connCaregiverEmail = connData['caregiverEmail'] ?? '';

        // Allow overriding existing connection
        await disconnectPatient(patientId);
        print("Disconnected patient from previous caregiver: $connCaregiverEmail");
      }

      // Get caregiver data for better identification
      String caregiverName = _auth.currentUser!.displayName ?? 'Caregiver';
      String caregiverEmail = _auth.currentUser!.email ?? '';

      // Create a connection record for the caregiver
      await _firestore.collection('connections').doc(_auth.currentUser!.uid).set({
        'connectedTo': patientId,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'caregiverId': _auth.currentUser!.uid,
        'caregiverEmail': caregiverEmail,
        'caregiverName': caregiverName,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'connectionActive': true,
      });

      print("Created caregiver connection record");

      // Also create a reverse connection for the patient
      await _firestore.collection('connections').doc(patientId).set({
        'connectedTo': _auth.currentUser!.uid,
        'caregiverId': _auth.currentUser!.uid,
        'caregiverEmail': caregiverEmail,
        'caregiverName': caregiverName,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'connectionActive': true,
      });

      print("Created patient connection record");

      // IMPROVED: Send explicit notification to patient about the new connection
      await _database
          .ref()
          .child('notifications')
          .child(patientId)
          .push()
          .set({
        'type': 'connection_established',
        'caregiverId': _auth.currentUser!.uid,
        'caregiverEmail': caregiverEmail,
        'caregiverName': caregiverName,
        'timestamp': ServerValue.timestamp,
        'message': 'You are now connected with caregiver: $caregiverEmail',
        'priority': 'high'
      });

      print("Sent connection notification to patient");

      // Initialize location node if it doesn't exist
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);

      // Try to ping patient location to confirm access with multiple retries
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          await patientLocationRef.update({
            'trackedAt': ServerValue.timestamp,
            'trackRequest': true,
            'requestedBy': {
              'caregiverId': _auth.currentUser!.uid,
              'caregiverEmail': caregiverEmail,
              'timestamp': ServerValue.timestamp,
            }
          });
          print("Successfully updated patient location node on attempt ${attempt + 1}");
          break;
        } catch (e) {
          print("Warning: Could not update patient location node on attempt ${attempt + 1}: $e");
          if (attempt < 2) await Future.delayed(Duration(seconds: 1)); // Brief delay before retry
        }
      }

      // ENHANCED: Also send an urgent location request to the patient
      await triggerUrgentLocationUpdate(patientId);

      return {
        'success': true,
        'message': 'Successfully connected with patient',
        'patientId': patientId,
        'patientEmail': patientEmail,
      };
    } catch (e) {
      print("Error connecting with patient: $e");
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Get the connected patient's location stream
  Stream<DatabaseEvent> getPatientLocationStream(String patientId) {
    print("Getting location stream for patient: $patientId");
    DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);

    // IMPROVED: Make multiple attempts to update tracking status
    for (int i = 0; i < 3; i++) {
      patientLocationRef.update({
        'trackedAt': ServerValue.timestamp,
        'trackRequest': true,
        'priority': 'high',
        'requestTime': DateTime.now().toIso8601String(), // Adding timestamps helps debug
      }).then((_) {
        print("Track request sent successfully on attempt ${i+1}");
      }).catchError((e) {
        print("Error updating track request on attempt ${i+1}: $e");
      });

      // Small delay between attempts
      if (i < 2) Future.delayed(Duration(milliseconds: 500));
    }

    return patientLocationRef.onValue;
  }

  // One-time get of patient's current location with improved reliability
  Future<Map<String, dynamic>?> getPatientCurrentLocation(String patientId) async {
    try {
      print("Getting current location for patient: $patientId");
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);

      // IMPROVED: First check if the node exists
      DataSnapshot checkSnapshot = await patientLocationRef.get();
      if (!checkSnapshot.exists) {
        print("Patient location node doesn't exist yet, creating it");
        await patientLocationRef.set({
          'initialized': true,
          'trackedAt': ServerValue.timestamp,
          'trackRequest': true,
          'requestedBy': {
            'caregiverId': _auth.currentUser?.uid,
            'caregiverEmail': _auth.currentUser?.email,
            'timestamp': ServerValue.timestamp,
          }
        });
      } else {
        // Update tracking status to request a fresh location
        await patientLocationRef.update({
          'trackedAt': ServerValue.timestamp,
          'trackRequest': true,
          'urgent': true, // Added priority flag
          'requestedBy': {
            'caregiverId': _auth.currentUser?.uid,
            'caregiverEmail': _auth.currentUser?.email,
            'timestamp': ServerValue.timestamp,
          }
        });
      }

      // Send an urgent location update request
      await triggerUrgentLocationUpdate(patientId);

      // Wait a moment for patient to respond with location
      await Future.delayed(Duration(seconds: 2)); // IMPROVED: longer wait

      // Try multiple times
      for (int attempt = 0; attempt < 3; attempt++) {
        DataSnapshot snapshot = await patientLocationRef.get();

        if (snapshot.exists) {
          Map<dynamic, dynamic>? data = snapshot.value as Map?;
          if (data != null &&
              data.containsKey('latitude') &&
              data.containsKey('longitude')) {
            print("Patient location data found with coordinates");
            return Map<String, dynamic>.from(data);
          } else {
            print("Patient location data found but missing coordinates, attempt ${attempt + 1}");
            if (attempt < 2) await Future.delayed(Duration(seconds: 1));
          }
        } else {
          print("No location data found for patient, attempt ${attempt + 1}");
          if (attempt < 2) await Future.delayed(Duration(seconds: 1));
        }
      }

      return null;
    } catch (e) {
      print("Error getting patient location: $e");
      return null;
    }
  }

  // Check if patient is online based on last active time
  Future<bool> isPatientOnline(String patientId) async {
    try {
      // First check the whole location node
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);
      DataSnapshot fullSnapshot = await patientLocationRef.get();

      if (!fullSnapshot.exists) {
        print("Patient location node doesn't exist at all");
        return false;
      }

      // Then check the device info specifically
      DatabaseReference deviceInfoRef = _database.ref().child('locations').child(patientId).child('deviceInfo');
      DataSnapshot snapshot = await deviceInfoRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> deviceInfo = snapshot.value as Map<dynamic, dynamic>;
        bool isOnline = deviceInfo['online'] ?? false;

        // If marked as online, check last active timestamp (consider offline if > 5 minutes)
        if (isOnline && deviceInfo.containsKey('lastActive')) {
          int lastActive = deviceInfo['lastActive'];
          int now = DateTime.now().millisecondsSinceEpoch;
          int diff = now - lastActive;

          // If more than 5 minutes since last update, consider offline
          if (diff > 5 * 60 * 1000) {
            return false;
          }

          return true;
        }

        return isOnline;
      }

      return false;
    } catch (e) {
      print("Error checking if patient is online: $e");
      return false;
    }
  }

  // Get current connected patient
  Future<Map<String, dynamic>> getConnectedPatient() async {
    if (_auth.currentUser == null) {
      return {'connected': false};
    }

    try {
      DocumentSnapshot connectionDoc = await _firestore
          .collection('connections')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!connectionDoc.exists) {
        return {'connected': false};
      }

      Map<String, dynamic> connectionData = connectionDoc.data() as Map<String, dynamic>;
      String connectedToId = connectionData['connectedTo'];

      // Check if we're the caregiver or the patient
      bool isCaregiver = connectionData.containsKey('patientId');

      if (isCaregiver) {
        print("Found connection to patient: ${connectionData['patientId']}");

        // Check if patient is online
        bool isOnline = await isPatientOnline(connectionData['patientId']);

        return {
          'connected': true,
          'patientId': connectionData['patientId'],
          'patientEmail': connectionData['patientEmail'],
          'isPatientOnline': isOnline,
          'timestamp': connectionData['timestamp'],
        };
      } else {
        print("Found connection to caregiver: ${connectionData['caregiverId']}");

        return {
          'connected': true,
          'caregiverId': connectionData['caregiverId'],
          'caregiverEmail': connectionData['caregiverEmail'],
          'caregiverName': connectionData['caregiverName'],
          'timestamp': connectionData['timestamp'],
        };
      }
    } catch (e) {
      print("Error getting connected patient: $e");
      return {'connected': false, 'error': e.toString()};
    }
  }

// Disconnect from patient (for caregiver)
  Future<bool> disconnectFromPatient() async {
    if (_auth.currentUser == null) return false;

    try {
      DocumentSnapshot connectionDoc = await _firestore
          .collection('connections')
          .doc(_auth.currentUser!.uid)
          .get();

      if (!connectionDoc.exists) return true; // Already disconnected

      Map<String, dynamic> connectionData = connectionDoc.data() as Map<String, dynamic>;
      String patientId = connectionData['connectedTo'];

      // Delete both connection records
      await _firestore.collection('connections').doc(_auth.currentUser!.uid).delete();
      await _firestore.collection('connections').doc(patientId).delete();

      print("Disconnected from patient: $patientId");

      // IMPROVED: Send notification to patient about disconnection
      await _database
          .ref()
          .child('notifications')
          .child(patientId)
          .push()
          .set({
        'type': 'connection_terminated',
        'caregiverEmail': _auth.currentUser!.email,
        'timestamp': ServerValue.timestamp,
        'message': 'Your location sharing with ${_auth.currentUser!.email} has been stopped',
      });

      return true;
    } catch (e) {
      print("Error disconnecting from patient: $e");
      return false;
    }
  }

  // Disconnect patient (for system use)
  Future<bool> disconnectPatient(String patientId) async {
    try {
      // Get the connection record for the patient
      DocumentSnapshot connectionDoc = await _firestore
          .collection('connections')
          .doc(patientId)
          .get();

      if (!connectionDoc.exists) return true; // Already disconnected

      // Get the caregiver ID
      Map<String, dynamic> connectionData = connectionDoc.data() as Map<String, dynamic>;
      String caregiverId = connectionData['connectedTo'];

      // Delete both connection records
      await _firestore.collection('connections').doc(patientId).delete();
      await _firestore.collection('connections').doc(caregiverId).delete();

      print("Disconnected patient $patientId from caregiver $caregiverId");

      return true;
    } catch (e) {
      print("Error disconnecting patient: $e");
      return false;
    }
  }

  // Debug method to check connection status and location data
  Future<Map<String, dynamic>> debugLocationSystem(String? targetUserId) async {
    Map<String, dynamic> results = {};

    try {
      final userId = _auth.currentUser?.uid;
      results['currentUserId'] = userId;

      if (userId == null) {
        results['error'] = 'No authenticated user';
        return results;
      }

      // Get user's current connection status
      final connectionData = await getConnectedPatient();
      results['connectionData'] = connectionData;

      // Check own location node
      final ownLocationRef = _database.ref().child('locations').child(userId);
      final ownSnapshot = await ownLocationRef.get();
      results['ownLocationExists'] = ownSnapshot.exists;

      if (ownSnapshot.exists) {
        results['ownLocationData'] = ownSnapshot.value;
      }

      // Check target user's location if specified
      if (targetUserId != null) {
        final targetLocationRef = _database.ref().child('locations').child(targetUserId);
        final targetSnapshot = await targetLocationRef.get();
        results['targetLocationExists'] = targetSnapshot.exists;

        if (targetSnapshot.exists) {
          results['targetLocationData'] = targetSnapshot.value;
        }
      }

      return results;
    } catch (e) {
      results['error'] = e.toString();
      return results;
    }
  }

  // Send message to connected user
  Future<bool> sendLocationMessage({
    required String recipientId,
    required String message,
    LatLng? location,
  }) async {
    if (_auth.currentUser == null) return false;

    try {
      // Create message data
      Map<String, dynamic> messageData = {
        'senderId': _auth.currentUser!.uid,
        'senderEmail': _auth.currentUser!.email,
        'senderName': _auth.currentUser!.displayName ?? 'User',
        'recipientId': recipientId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      };

      // Add location if provided
      if (location != null) {
        messageData['location'] = {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }

      // Save to Firestore
      await _firestore
          .collection('location_messages')
          .add(messageData);

      // Also send as a notification via Realtime Database for immediate delivery
      await _database
          .ref()
          .child('notifications')
          .child(recipientId)
          .push()
          .set({
        'message': message,
        'sender': _auth.currentUser!.email,
        'timestamp': ServerValue.timestamp,
        'type': 'location_message',
      });

      return true;
    } catch (e) {
      print("Error sending location message: $e");
      return false;
    }
  }

  // Get messages from the other connected user
  Stream<QuerySnapshot> getLocationMessages() {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('location_messages')
        .where('recipientId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark message as read
  Future<void> markMessageRead(String messageId) async {
    await _firestore
        .collection('location_messages')
        .doc(messageId)
        .update({'read': true});
  }
}