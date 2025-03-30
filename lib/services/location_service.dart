import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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