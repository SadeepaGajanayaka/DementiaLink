import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:location/location.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Custom logging service to replace print statements
class LogService {
  static void log(String message, {LogLevel level = LogLevel.info}) {
    // In a production app, replace this with a more robust logging mechanism
    // For example, integrate with Firebase Crashlytics or a logging service
    switch (level) {
      case LogLevel.error:
        print('ERROR: $message');
        break;
      case LogLevel.warning:
        print('WARNING: $message');
        break;
      case LogLevel.info:
        print('INFO: $message');
        break;
    }
  }
}

enum LogLevel { error, warning, info }

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Location service
  final Location _location = Location();
  // Firebase references
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Subscription for location updates
  StreamSubscription<LocationData>? _locationSubscription;
  // Track whether service is running
  bool _isRunning = false;

  // Controller for broadcasting connection status changes
  final _connectionStatusController = StreamController<Map<String, dynamic>>.broadcast();
  // Stream to listen to connection changes
  Stream<Map<String, dynamic>> get connectionStatusStream => _connectionStatusController.stream;

  // Initialize the location service
  Future<bool> initialize() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location service is enabled
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          LogService.log('Location service not enabled', level: LogLevel.warning);
          return false;
        }
      }

      // Check if permission is granted
      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          LogService.log('Location permission denied', level: LogLevel.warning);
          return false;
        }
      }

      // Configure location settings
      await _location.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000, // Update every 10 seconds
        distanceFilter: 5, // Update if moved at least 5 meters
      );

      return true;
    } catch (e) {
      LogService.log('Location initialization error: $e', level: LogLevel.error);
      return false;
    }
  }

  // Start sharing location
  Future<bool> startSharingLocation() async {
    if (_isRunning) return true;

    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      _locationSubscription = _location.onLocationChanged.listen((LocationData currentLocation) {
        // Update location in Firebase
        _database.ref().child('locations/${user.uid}').update({
          'latitude': currentLocation.latitude,
          'longitude': currentLocation.longitude,
          'accuracy': currentLocation.accuracy,
          'heading': currentLocation.heading,
          'speed': currentLocation.speed,
          'timestamp': ServerValue.timestamp,
        });
      });

      _isRunning = true;
      LogService.log('Location sharing started', level: LogLevel.info);
      return true;
    } catch (e) {
      LogService.log('Error starting location sharing: $e', level: LogLevel.error);
      return false;
    }
  }

  // Stop sharing location
  Future<void> stopSharingLocation() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _isRunning = false;

    final user = _auth.currentUser;
    if (user != null) {
      // Update status in Firebase
      await _database.ref().child('locations/${user.uid}').update({
        'active': false,
        'last_updated': ServerValue.timestamp,
      });
    }
    LogService.log('Location sharing stopped', level: LogLevel.info);
  }

  // Get location data for a specific user
  Stream<Map<String, dynamic>> getUserLocationStream(String userId) {
    return _database.ref().child('locations/$userId').onValue.map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(data);
    });
  }

  // Check if caregiver is authorized to track patient
  Future<bool> isAuthorizedToTrack(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Check if the current user is authorized to track the patient
      final doc = await _firestore
          .collection('users')
          .doc(patientId)
          .collection('authorized_caregivers')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      LogService.log('Error checking tracking authorization: $e', level: LogLevel.error);
      return false;
    }
  }

  // Get user ID from email
  Future<String?> getUserIdFromEmail(String email) async {
    try {
      // Query Firestore for user with this email
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      LogService.log('Error getting user ID from email: $e', level: LogLevel.error);
      return null;
    }
  }

  // Request connection with patient
  Future<bool> requestConnection(String patientEmail) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Get patient ID from email
      final patientId = await getUserIdFromEmail(patientEmail);
      if (patientId == null) {
        LogService.log('User not found with this email', level: LogLevel.warning);
        return false;
      }

      // Check if already connected
      final isAlreadyConnected = await isAuthorizedToTrack(patientId);
      if (isAlreadyConnected) {
        // Notify listeners of existing connection
        _connectionStatusController.add({
          'patientId': patientId,
          'patientEmail': patientEmail,
          'status': 'connected',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return true;
      }

      // Create a connection request
      await _firestore
          .collection('users')
          .doc(patientId)
          .collection('connection_requests')
          .doc(user.uid)
          .set({
        'caregiverId': user.uid,
        'caregiverEmail': user.email,
        'caregiverName': user.displayName,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Also add to caregiver's outgoing requests
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('outgoing_requests')
          .doc(patientId)
          .set({
        'patientId': patientId,
        'patientEmail': patientEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // Set up listener for this connection request
      _listenToConnectionRequest(user.uid, patientId);

      return true;
    } catch (e) {
      LogService.log('Error requesting connection: $e', level: LogLevel.error);
      return false;
    }
  }

  // Listen for changes in connection request status
  void _listenToConnectionRequest(String caregiverId, String patientId) {
    _firestore
        .collection('users')
        .doc(caregiverId)
        .collection('outgoing_requests')
        .doc(patientId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        _connectionStatusController.add({
          'patientId': patientId,
          'status': data['status'],
          'patientEmail': data['patientEmail'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  // Accept a connection request (for patient side)
  Future<bool> acceptConnectionRequest(String caregiverId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Get caregiver details from request
      final requestDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('connection_requests')
          .doc(caregiverId)
          .get();

      if (!requestDoc.exists) {
        LogService.log('Connection request not found', level: LogLevel.warning);
        return false;
      }

      final requestData = requestDoc.data() as Map<String, dynamic>;

      // Add caregiver to authorized list
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authorized_caregivers')
          .doc(caregiverId)
          .set({
        'caregiverId': caregiverId,
        'caregiverEmail': requestData['caregiverEmail'],
        'caregiverName': requestData['caregiverName'],
        'authorizedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Add patient to caregiver's tracked patients
      await _firestore
          .collection('users')
          .doc(caregiverId)
          .collection('tracked_patients')
          .doc(user.uid)
          .set({
        'patientId': user.uid,
        'patientEmail': user.email,
        'patientName': user.displayName,
        'connectedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Update request status
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('connection_requests')
          .doc(caregiverId)
          .update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Update caregiver's outgoing request
      await _firestore
          .collection('users')
          .doc(caregiverId)
          .collection('outgoing_requests')
          .doc(user.uid)
          .update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      LogService.log('Error accepting connection request: $e', level: LogLevel.error);
      return false;
    }
  }

  // Reject a connection request (for patient side)
  Future<bool> rejectConnectionRequest(String caregiverId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Update request status
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('connection_requests')
          .doc(caregiverId)
          .update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Update caregiver's outgoing request
      await _firestore
          .collection('users')
          .doc(caregiverId)
          .collection('outgoing_requests')
          .doc(user.uid)
          .update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      LogService.log('Error rejecting connection request: $e', level: LogLevel.error);
      return false;
    }
  }

  // Get pending connection requests (for patient side)
  Stream<QuerySnapshot> getPendingConnectionRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty(); // Return an empty stream if no user
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('connection_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get list of connected caregivers (for patient side)
  Stream<QuerySnapshot> getConnectedCaregivers() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty(); // Return an empty stream if no user
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('authorized_caregivers')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Get list of connected patients (for caregiver side)
  Stream<QuerySnapshot> getConnectedPatients() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty(); // Return an empty stream if no user
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tracked_patients')
        .where('status', isEqualTo: 'active')
        .snapshots();
  }

  // Disconnect from patient (caregiver side)
  Future<bool> disconnectFromPatient(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Remove from tracked patients
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracked_patients')
          .doc(patientId)
          .update({
        'status': 'inactive',
        'disconnectedAt': FieldValue.serverTimestamp(),
      });

      // Remove caregiver authorization
      await _firestore
          .collection('users')
          .doc(patientId)
          .collection('authorized_caregivers')
          .doc(user.uid)
          .update({
        'status': 'inactive',
        'revokedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      LogService.log('Error disconnecting from patient: $e', level: LogLevel.error);
      return false;
    }
  }

  // Revoke caregiver access (patient side)
  Future<bool> revokeCaregiverAccess(String caregiverId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Remove caregiver authorization
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('authorized_caregivers')
          .doc(caregiverId)
          .update({
        'status': 'inactive',
        'revokedAt': FieldValue.serverTimestamp(),
      });

      // Update tracked patient status in caregiver's list
      await _firestore
          .collection('users')
          .doc(caregiverId)
          .collection('tracked_patients')
          .doc(user.uid)
          .update({
        'status': 'inactive',
        'disconnectedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      LogService.log('Error revoking caregiver access: $e', level: LogLevel.error);
      return false;
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _locationSubscription?.cancel();
    _connectionStatusController.close();
  }
}