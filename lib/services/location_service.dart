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

      // Create the locations node if it doesn't exist
      // Include more user details for easier identification
      await userLocationRef.set({
        'initialized': true,
        'timestamp': ServerValue.timestamp,
        'userEmail': _auth.currentUser!.email,
        'userName': _auth.currentUser!.displayName ?? 'User',
        'userUid': _auth.currentUser!.uid,
        'deviceInfo': {
          'online': true,
          'lastActive': ServerValue.timestamp,
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

  // Update location in Firebase Realtime Database
  Future<void> _updateLocationInFirebase(LocationData locationData) async {
    if (_auth.currentUser == null) return;

    try {
      if (locationData.latitude == null || locationData.longitude == null) {
        print("Invalid location data, can't update");
        return;
      }

      print("Updating location: ${locationData.latitude}, ${locationData.longitude}");

      // Reference to user location in Firebase
      DatabaseReference userLocationRef = _database.ref().child('locations').child(_auth.currentUser!.uid);

      // Update the location with timestamp and additional metadata
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

      print("Location updated successfully in Firebase");
    } catch (e) {
      print("Error updating location in Firebase: $e");
    }
  }

// Connect with a patient by email or UID
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
      });

      print("Created patient connection record");

      // Initialize location node if it doesn't exist
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);

      // Try to ping patient location to confirm access
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
        print("Successfully updated patient location node");
      } catch (e) {
        print("Warning: Could not update patient location node: $e");
        // We'll continue anyway as the patient may update their location later
      }

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

    // Attempt to update tracking status to improve responsiveness
    patientLocationRef.update({
      'trackedAt': ServerValue.timestamp,
      'trackRequest': true,
    }).catchError((e) {
      // Ignore errors here, this is just to improve responsiveness
      print("Non-critical error updating track request: $e");
    });

    return patientLocationRef.onValue;
  }

  // One-time get of patient's current location
  Future<Map<String, dynamic>?> getPatientCurrentLocation(String patientId) async {
    try {
      print("Getting current location for patient: $patientId");
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId);

      // Update tracking status to request a fresh location
      await patientLocationRef.update({
        'trackedAt': ServerValue.timestamp,
        'trackRequest': true,
        'requestedBy': {
          'caregiverId': _auth.currentUser?.uid,
          'caregiverEmail': _auth.currentUser?.email,
          'timestamp': ServerValue.timestamp,
        }
      });

      // Wait a moment for patient to respond with location
      await Future.delayed(Duration(seconds: 1));

      DataSnapshot snapshot = await patientLocationRef.get();

      if (snapshot.exists) {
        print("Patient location data found");
        return Map<String, dynamic>.from(snapshot.value as Map);
      } else {
        print("No location data found for patient");
        return null;
      }
    } catch (e) {
      print("Error getting patient location: $e");
      return null;
    }
  }

  // Check if patient is online based on last active time
  Future<bool> isPatientOnline(String patientId) async {
    try {
      DatabaseReference patientLocationRef = _database.ref().child('locations').child(patientId).child('deviceInfo');
      DataSnapshot snapshot = await patientLocationRef.get();

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