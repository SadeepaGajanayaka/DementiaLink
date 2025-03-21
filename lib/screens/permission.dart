import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Permission Handler for location tracking requests
class PermissionHandler {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen for incoming connection requests
  Stream<DatabaseEvent> listenForConnectionRequests() {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }

    final requestsRef = _database.ref()
        .child('permission_requests')
        .child(_auth.currentUser!.uid);

    print("Setting up listener for permission requests at: ${requestsRef.path}");

    return requestsRef.onChildAdded;
  }

  // Send a connection request to a patient
  Future<bool> sendConnectionRequest({
    required String patientId,
    required String patientEmail,
    required String caregiverName,
    required String caregiverEmail,
  }) async {
    try {
      if (_auth.currentUser == null) {
        print("Cannot send request: No authenticated user");
        return false;
      }

      final caregiverId = _auth.currentUser!.uid;
      print("Sending connection request from $caregiverId to patient $patientId");

      // Create a unique request ID
      final requestRef = _database.ref()
          .child('permission_requests')
          .child(patientId)
          .push();

      // Request data
      final requestData = {
        'caregiverId': caregiverId,
        'caregiverName': caregiverName,
        'caregiverEmail': caregiverEmail,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'timestamp': ServerValue.timestamp,
        'status': 'pending',
        'requestId': requestRef.key,
      };

      // Save request
      await requestRef.set(requestData);

      // Also add a notification for immediate display
      await _database
          .ref()
          .child('notifications')
          .child(patientId)
          .push()
          .set({
        'type': 'permission_request',
        'caregiverName': caregiverName,
        'caregiverEmail': caregiverEmail,
        'timestamp': ServerValue.timestamp,
        'message': 'Location access request from $caregiverName',
      });

      print("Connection request sent successfully with ID: ${requestRef.key}");
      return true;
    } catch (e) {
      print("Error sending connection request: $e");
      return false;
    }
  }

  // Respond to a permission request
  Future<bool> respondToRequest(String requestId, bool accept) async {
    try {
      if (_auth.currentUser == null) {
        print("Cannot respond to request: No authenticated user");
        return false;
      }

      final patientId = _auth.currentUser!.uid;
      print("Responding to request $requestId with accept=$accept");

      // Update request status
      await _database
          .ref()
          .child('permission_requests')
          .child(patientId)
          .child(requestId)
          .update({
        'status': accept ? 'accepted' : 'rejected',
        'respondedAt': ServerValue.timestamp,
      });

      // If accepted, establish the connection
      if (accept) {
        // Get request data
        final snapshot = await _database
            .ref()
            .child('permission_requests')
            .child(patientId)
            .child(requestId)
            .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          // Create connection record for patient
          await _firestore.collection('connections').doc(patientId).set({
            'connectedTo': data['caregiverId'],
            'caregiverId': data['caregiverId'],
            'caregiverEmail': data['caregiverEmail'],
            'caregiverName': data['caregiverName'],
            'patientId': patientId,
            'patientEmail': data['patientEmail'],
            'timestamp': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Create connection record for caregiver
          await _firestore.collection('connections').doc(data['caregiverId']).set({
            'connectedTo': patientId,
            'patientId': patientId,
            'patientEmail': data['patientEmail'],
            'caregiverId': data['caregiverId'],
            'caregiverEmail': data['caregiverEmail'],
            'caregiverName': data['caregiverName'],
            'timestamp': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Notify caregiver that request was accepted
          await _database
              .ref()
              .child('notifications')
              .child(data['caregiverId'])
              .push()
              .set({
            'type': 'permission_accepted',
            'patientEmail': data['patientEmail'],
            'timestamp': ServerValue.timestamp,
            'message': 'Your location access request has been accepted',
          });

          print("Connection established successfully");
        } else {
          print("Request data not found");
          return false;
        }
      } else {
        // Get caregiver ID from request
        final snapshot = await _database
            .ref()
            .child('permission_requests')
            .child(patientId)
            .child(requestId)
            .get();

        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          // Notify caregiver that request was rejected
          await _database
              .ref()
              .child('notifications')
              .child(data['caregiverId'])
              .push()
              .set({
            'type': 'permission_rejected',
            'patientEmail': data['patientEmail'],
            'timestamp': ServerValue.timestamp,
            'message': 'Your location access request has been rejected',
          });
        }

        print("Rejection notification sent");
      }

      return true;
    } catch (e) {
      print("Error responding to request: $e");
      return false;
    }
  }

  // Check if there are any pending requests
  Future<bool> hasPendingRequests() async {
    try {
      if (_auth.currentUser == null) return false;

      final patientId = _auth.currentUser!.uid;
      final requestsRef = _database.ref()
          .child('permission_requests')
          .child(patientId);

      // Query for pending requests
      final snapshot = await requestsRef
          .orderByChild('status')
          .equalTo('pending')
          .get();

      return snapshot.exists;
    } catch (e) {
      print("Error checking pending requests: $e");
      return false;
    }
  }

  // Get all pending requests
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      if (_auth.currentUser == null) return [];

      final patientId = _auth.currentUser!.uid;
      final requestsRef = _database.ref()
          .child('permission_requests')
          .child(patientId);

      // Query for pending requests
      final snapshot = await requestsRef
          .orderByChild('status')
          .equalTo('pending')
          .get();

      if (!snapshot.exists) return [];

      final pendingRequests = <Map<String, dynamic>>[];
      final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

      data.forEach((key, value) {
        final request = Map<String, dynamic>.from(value as Map);
        request['requestId'] = key; // Ensure the key is included
        pendingRequests.add(request);
      });

      return pendingRequests;
    } catch (e) {
      print("Error getting pending requests: $e");
      return [];
    }
  }

  // Delete a request
  Future<bool> deleteRequest(String requestId) async {
    try {
      if (_auth.currentUser == null) return false;

      final userId = _auth.currentUser!.uid;
      await _database
          .ref()
          .child('permission_requests')
          .child(userId)
          .child(requestId)
          .remove();

      return true;
    } catch (e) {
      print("Error deleting request: $e");
      return false;
    }
  }
}

// Permission Dialog shown to patients
class PermissionDialog extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const PermissionDialog({
    Key? key,
    required this.requestData,
  }) : super(key: key);

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> {
  final PermissionHandler _permissionHandler = PermissionHandler();
  bool _isLoading = false;

  void _respondToRequest(bool accept) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final requestId = widget.requestData['requestId'];
      print("Responding to request $requestId with: $accept");

      final success = await _permissionHandler.respondToRequest(requestId, accept);

      if (mounted) {
        if (success) {
          // Close dialog and return result
          Navigator.of(context).pop(accept);
        } else {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process response'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error in permission dialog: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data from request
    final caregiverName = widget.requestData['caregiverName'] ?? 'Caregiver';
    final caregiverEmail = widget.requestData['caregiverEmail'] ?? 'Unknown Email';

    return AlertDialog(
      title: const Text('Location Tracking Request',
        style: TextStyle(color: Color(0xFF503663)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$caregiverName would like to track your location.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text('Email: $caregiverEmail'),
          const SizedBox(height: 16),
          const Text(
            'If you accept, this person will be able to see your location in real-time.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => _respondToRequest(false),
          child: const Text(
            'Deny',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () => _respondToRequest(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF77588D),
          ),
          child: _isLoading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Text(
            'Allow',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}