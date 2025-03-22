import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Save patient data (works for both AssistMe and AssistLoved)
  Future<String> savePatientData({
    required String userId,
    required String formType, // 'self' or 'loved_one'
    required Map<String, dynamic> patientData
  }) async {
    try {
      print("Starting savePatientData for userId: $userId, formType: $formType");

      // Add timestamp
      patientData['created_at'] = FieldValue.serverTimestamp();
      patientData['updated_at'] = FieldValue.serverTimestamp();
      patientData['form_type'] = formType;

      print("Prepared data structure with timestamps and form type");

      // Save to Firestore
      print("Saving to Firestore: users/$userId/patients/");
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .add(patientData);

      print("Data saved successfully with document ID: ${docRef.id}");

      return docRef.id; // Return the document ID
    } catch (e) {
      print('Error saving patient data: $e');
      // Print stack trace for debugging
      print(StackTrace.current);
      rethrow;
    }
  }

  // Update patient data
  Future<void> updatePatientData({
    required String userId,
    required String patientId,
    required Map<String, dynamic> patientData
  }) async {
    try {
      print("Updating patient data for user: $userId, patient: $patientId");

      // Add timestamp
      patientData['updated_at'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .doc(patientId)
          .update(patientData);

      print("Patient data updated successfully");
    } catch (e) {
      print('Error updating patient data: $e');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Get all patients for a user
  Stream<QuerySnapshot> getPatientsStream(String userId) {
    print("Getting patients stream for user: $userId");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('patients')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // Get a specific patient
  Future<DocumentSnapshot> getPatient(String userId, String patientId) {
    print("Fetching patient document for user: $userId, patient: $patientId");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('patients')
        .doc(patientId)
        .get();
  }

  // Check if a user document exists
  Future<bool> userExists(String userId) async {
    try {
      print("Checking if user exists: $userId");
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
      bool exists = snapshot.exists;
      print("User exists: $exists");

      // If user doesn't exist, create an empty document
      if (!exists) {
        print("Creating new user document for: $userId");
        await _firestore.collection('users').doc(userId).set({
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      }

      return exists;
    } catch (e) {
      print("Error checking if user exists: $e");
      return false;
    }
  }

  // Delete a patient
  Future<void> deletePatient(String userId, String patientId) async {
    try {
      print("Deleting patient: $patientId for user: $userId");
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .doc(patientId)
          .delete();
      print("Patient deleted successfully");
    } catch (e) {
      print('Error deleting patient: $e');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Upload patient profile image
  Future<String> uploadPatientImage(String userId, String patientId, File imageFile) async {
    try {
      print("Uploading profile image for user: $userId, patient: $patientId");
      // Create a reference to the location you want to upload to in firebase
      Reference ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('patients')
          .child(patientId)
          .child('profile_image.jpg');

      // Upload the file
      UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait until the file is uploaded then fetch the download URL
      print("Waiting for upload to complete...");
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print("Image uploaded, download URL: $downloadUrl");

      // Update patient document with the image URL
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .doc(patientId)
          .update({
        'profile_image_url': downloadUrl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print("Patient record updated with new image URL");
      return downloadUrl;
    } catch (e) {
      print('Error uploading patient image: $e');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Save medication reminder
  Future<String> saveMedicationReminder({
    required String userId,
    required String patientId,
    required Map<String, dynamic> reminderData
  }) async {
    try {
      print("Saving medication reminder for user: $userId, patient: $patientId");
      // Add timestamps
      reminderData['created_at'] = FieldValue.serverTimestamp();
      reminderData['updated_at'] = FieldValue.serverTimestamp();

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .doc(patientId)
          .collection('medication_reminders')
          .add(reminderData);

      print("Medication reminder saved with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print('Error saving medication reminder: $e');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Get medication reminders for a patient
  Stream<QuerySnapshot> getMedicationRemindersStream(String userId, String patientId) {
    print("Getting medication reminders stream for user: $userId, patient: $patientId");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('patients')
        .doc(patientId)
        .collection('medication_reminders')
        .orderBy('time', descending: false)
        .snapshots();
  }

  // Save activity log
  Future<String> saveActivityLog({
    required String userId,
    required String patientId,
    required Map<String, dynamic> activityData
  }) async {
    try {
      print("Saving activity log for user: $userId, patient: $patientId");
      // Add timestamp
      activityData['timestamp'] = FieldValue.serverTimestamp();

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .doc(patientId)
          .collection('activity_logs')
          .add(activityData);

      print("Activity log saved with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print('Error saving activity log: $e');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Get activity logs for a patient
  Stream<QuerySnapshot> getActivityLogsStream(String userId, String patientId) {
    print("Getting activity logs stream for user: $userId, patient: $patientId");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('patients')
        .doc(patientId)
        .collection('activity_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Save caregiver notes
  Future<String> saveCaregiverNote({
    required String userId,
    required String patientId,
    required Map<String, dynamic> noteData
  }) async {
    try {
      print("Saving caregiver note for user: $userId, patient: $patientId");
      // Add timestamp
      noteData['created_at'] = FieldValue.serverTimestamp();
      noteData['updated_at'] = FieldValue.serverTimestamp();

      // Save to Firestore
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('patients')
          .doc(patientId)
          .collection('caregiver_notes')
          .add(noteData);

      print("Caregiver note saved with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print('Error saving caregiver note: $e');
      print(StackTrace.current);
      rethrow;
    }
  }

  // Add these methods to your DatabaseService class in database_service.dart

// Create a connection request
  Future<String> createConnectionRequest({
    required String caregiverId,
    required String patientEmail,
  }) async {
    try {
      print("Creating connection request from $caregiverId to $patientEmail");

      // First, find the user with the given email
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: patientEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('No user found with this email address');
      }

      String patientId = userQuery.docs.first.id;

      // Check if a connection already exists
      QuerySnapshot existingConnections = await _firestore
          .collection('connections')
          .where('caregiverId', isEqualTo: caregiverId)
          .where('patientId', isEqualTo: patientId)
          .get();

      if (existingConnections.docs.isNotEmpty) {
        // Get the existing connection status
        String status = existingConnections.docs.first['status'];
        if (status == 'pending') {
          throw Exception('A connection request is already pending with this user');
        } else if (status == 'accepted') {
          throw Exception('You are already connected with this user');
        } else if (status == 'rejected') {
          // If rejected, update the existing connection instead of creating a new one
          await _firestore
              .collection('connections')
              .doc(existingConnections.docs.first.id)
              .update({
            'status': 'pending',
            'requestedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return existingConnections.docs.first.id;
        }
      }

      // Create a new connection document
      DocumentReference docRef = await _firestore.collection('connections').add({
        'caregiverId': caregiverId,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print("Connection request created with ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print('Error creating connection request: $e');
      rethrow;
    }
  }

// Get all connections for a user (both as caregiver and patient)
  Stream<QuerySnapshot> getUserConnectionsStream(String userId) {
    print("Getting connections stream for user: $userId");
    return _firestore
        .collection('connections')
        .where(Filter.or(
        Filter('caregiverId', isEqualTo: userId),
        Filter('patientId', isEqualTo: userId)
    ))
        .snapshots();
  }

// Update connection status
  Future<void> updateConnectionStatus({
    required String connectionId,
    required String status,
  }) async {
    try {
      print("Updating connection $connectionId to status: $status");
      await _firestore
          .collection('connections')
          .doc(connectionId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Connection status updated successfully");
    } catch (e) {
      print('Error updating connection status: $e');
      rethrow;
    }
  }

// Update user location
  Future<void> updateUserLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      print("Updating location for user: $userId");

      // Update user document with location
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'lastLocation': GeoPoint(latitude, longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      // Also update all active connections where this user is the patient
      QuerySnapshot connections = await _firestore
          .collection('connections')
          .where('patientId', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();

      for (var doc in connections.docs) {
        await _firestore
            .collection('connections')
            .doc(doc.id)
            .update({
          'lastLocation': GeoPoint(latitude, longitude),
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
      }

      print("Location updated successfully");
    } catch (e) {
      print('Error updating user location: $e');
      // Don't rethrow as this might be a background operation
    }
  }

  // Get caregiver notes for a patient
  Stream<QuerySnapshot> getCaregiverNotesStream(String userId, String patientId) {
    print("Getting caregiver notes stream for user: $userId, patient: $patientId");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('patients')
        .doc(patientId)
        .collection('caregiver_notes')
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}