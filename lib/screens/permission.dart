import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PermissionHandler {
  static final PermissionHandler _instance = PermissionHandler._internal();
  factory PermissionHandler() => _instance;
  PermissionHandler._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen for connection requests with improved error handling
  Stream<DatabaseEvent> listenForConnectionRequests() {
    if (_auth.currentUser == null) {
      print("Cannot listen for connection requests: No authenticated user");
      return const Stream.empty();
    }

    print("Setting up connection request listener for user: ${_auth.currentUser!.uid}");

    // Create reference to the patient's connection requests node
    DatabaseReference requestsRef = _database
        .ref()
        .child('connection_requests')
        .child(_auth.currentUser!.uid);

    // Just to make sure the reference is valid, create it if it doesn't exist
    requestsRef.update({
      'initialized': true,
      'timestamp': ServerValue.timestamp
    }).catchError((e) {
      print("Non-critical error initializing request node: $e");
    });

    // Return the stream of events for new requests
    return requestsRef.onChildAdded;
  }

  // Send a connection request with improved error handling and validation
  Future<bool> sendConnectionRequest({
    required String patientId,
    required String patientEmail,
    required String caregiverName,
    required String caregiverEmail,
  }) async {
    if (_auth.currentUser == null) {
      print("Cannot send connection request: No authenticated user");
      return false;
    }

    try {
      print("Preparing to send connection request to patient: $patientId");
      String requestId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create request data
      Map<String, dynamic> requestData = {
        'requestId': requestId,
        'caregiverId': _auth.currentUser!.uid,
        'caregiverName': caregiverName,
        'caregiverEmail': caregiverEmail,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'status': 'pending',
        'timestamp': ServerValue.timestamp,
        'message': '$caregiverName would like to track your location'
      };

      // Save request to Firebase Realtime Database
      // This is what triggers the notification in the patient's app
      await _database
          .ref()
          .child('connection_requests')
          .child(patientId)
          .child(requestId)
          .set(requestData);

      print("Connection request saved to Realtime Database");

      // Also save to Firestore for persistence and to maintain a history
      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .set({
        ...requestData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Connection request saved to Firestore");

      // Also ping the patient's location node to wake up their app if it's in background
      try {
        await _database.ref().child('locations').child(patientId).update({
          'hasConnectionRequest': true,
          'requestId': requestId,
          'requestTimestamp': ServerValue.timestamp,
        });
        print("Updated patient location node with request flag");
      } catch (e) {
        // Non-critical error, connection request will still work
        print("Non-critical error updating patient location node: $e");
      }

      return true;
    } catch (e) {
      print("Error sending connection request: $e");
      return false;
    }
  }

  // Accept a connection request with improved verification
  Future<bool> acceptConnectionRequest(String requestId) async {
    if (_auth.currentUser == null) {
      print("Cannot accept request: No authenticated user");
      return false;
    }

    try {
      print("Processing request acceptance for ID: $requestId");

      // Get the request data
      DatabaseReference requestRef = _database
          .ref()
          .child('connection_requests')
          .child(_auth.currentUser!.uid)
          .child(requestId);

      DataSnapshot snapshot = await requestRef.get();
      if (!snapshot.exists) {
        print("Request not found: $requestId");
        return false;
      }

      // Extract request data
      Map<String, dynamic> requestData = Map<String, dynamic>.from(snapshot.value as Map);
      String caregiverId = requestData['caregiverId'];
      String caregiverName = requestData['caregiverName'];
      String caregiverEmail = requestData['caregiverEmail'];
      String patientId = requestData['patientId'];
      String patientEmail = requestData['patientEmail'];

      // Verify that the current user is the patient in the request
      if (patientId != _auth.currentUser!.uid) {
        print("User ID mismatch. Current user: ${_auth.currentUser!.uid}, Expected: $patientId");
        return false;
      }

      // Update request status
      await requestRef.update({'status': 'accepted'});
      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

      print("Request status updated to 'accepted'");

      // Create connection records in Firestore
      // For caregiver
      await _firestore.collection('connections').doc(caregiverId).set({
        'connectedTo': patientId,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'caregiverId': caregiverId,
        'caregiverEmail': caregiverEmail,
        'caregiverName': caregiverName,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print("Connection record created for caregiver");

      // For patient
      await _firestore.collection('connections').doc(patientId).set({
        'connectedTo': caregiverId,
        'caregiverId': caregiverId,
        'caregiverEmail': caregiverEmail,
        'caregiverName': caregiverName,
        'patientId': patientId,
        'patientEmail': patientEmail,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print("Connection record created for patient");

      // Send notification to caregiver
      await _database
          .ref()
          .child('notifications')
          .child(caregiverId)
          .push()
          .set({
        'message': 'Your connection request was accepted',
        'type': 'connection_accepted',
        'patientEmail': patientEmail,
        'timestamp': ServerValue.timestamp,
      });

      print("Notification sent to caregiver");

      return true;
    } catch (e) {
      print("Error accepting connection request: $e");
      return false;
    }
  }

  // Reject a connection request
  Future<bool> rejectConnectionRequest(String requestId) async {
    if (_auth.currentUser == null) return false;

    try {
      print("Processing request rejection for ID: $requestId");

      // Get the request data
      DatabaseReference requestRef = _database
          .ref()
          .child('connection_requests')
          .child(_auth.currentUser!.uid)
          .child(requestId);

      DataSnapshot snapshot = await requestRef.get();
      if (!snapshot.exists) {
        print("Request not found: $requestId");
        return false;
      }

      // Extract caregiver ID for notification
      Map<String, dynamic> requestData = Map<String, dynamic>.from(snapshot.value as Map);
      String caregiverId = requestData['caregiverId'];
      String patientEmail = requestData['patientEmail'];

      // Update request status
      await requestRef.update({'status': 'rejected'});
      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'rejected'});

      print("Request status updated to 'rejected'");

      // Send notification to caregiver
      await _database
          .ref()
          .child('notifications')
          .child(caregiverId)
          .push()
          .set({
        'message': 'Your connection request was rejected',
        'type': 'connection_rejected',
        'patientEmail': patientEmail,
        'timestamp': ServerValue.timestamp,
      });

      print("Rejection notification sent to caregiver");

      return true;
    } catch (e) {
      print("Error rejecting connection request: $e");
      return false;
    }
  }

  // Delete a connection request
  Future<bool> deleteConnectionRequest(String requestId) async {
    if (_auth.currentUser == null) return false;

    try {
      print("Deleting connection request: $requestId");

      await _database
          .ref()
          .child('connection_requests')
          .child(_auth.currentUser!.uid)
          .child(requestId)
          .remove();

      // Also remove from Firestore if it exists
      try {
        await _firestore
            .collection('connection_requests')
            .doc(requestId)
            .delete();
      } catch (e) {
        // Non-critical error
        print("Non-critical error removing request from Firestore: $e");
      }

      print("Connection request deleted");
      return true;
    } catch (e) {
      print("Error deleting connection request: $e");
      return false;
    }
  }
}

// PermissionDialog - shown to patients when a caregiver requests to track their location
class PermissionDialog extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const PermissionDialog({
    Key? key,
    required this.requestData,
  }) : super(key: key);

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  final PermissionHandler _permissionHandler = PermissionHandler();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();

    // Print request data for debugging
    print("Permission dialog showing with request data: ${widget.requestData}");
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _acceptRequest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print("Accepting connection request: ${widget.requestData['requestId']}");
      bool success = await _permissionHandler.acceptConnectionRequest(widget.requestData['requestId']);

      if (success && mounted) {
        print("Successfully accepted connection request");
        Navigator.of(context).pop(true); // Return true for accepted
      } else if (mounted) {
        print("Failed to accept connection request");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print("Error accepting request: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _rejectRequest() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      print("Rejecting connection request: ${widget.requestData['requestId']}");
      bool success = await _permissionHandler.rejectConnectionRequest(widget.requestData['requestId']);

      if (success && mounted) {
        print("Successfully rejected connection request");
        Navigator.of(context).pop(false); // Return false for rejected
      } else if (mounted) {
        print("Failed to reject connection request");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject request. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      print("Error rejecting request: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract data from the request
    String caregiverName = widget.requestData['caregiverName'] ?? 'Caregiver';
    String caregiverEmail = widget.requestData['caregiverEmail'] ?? '';
    String message = widget.requestData['message'] ?? 'A caregiver would like to track your location';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF77588D),
                Color(0xFF503663),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              // Location icon with circle background
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 45,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Location Sharing Request',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // User info
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF503663),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caregiverName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            caregiverEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              // Warning about privacy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Allowing this request will share your location with this caregiver in real-time.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // Buttons - Deny/Allow
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _isProcessing ? null : _rejectRequest,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: _isProcessing
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Deny',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _isProcessing ? null : _acceptRequest,
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const SizedBox(
                            width: 20,
                            height: 20,
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// PermissionListener - A wrapper widget that listens for connection requests
// This can be used to wrap parts of the app to automatically show permission dialogs
class PermissionListener extends StatefulWidget {
  final Widget child;

  const PermissionListener({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PermissionListener> createState() => _PermissionListenerState();
}

class _PermissionListenerState extends State<PermissionListener> {
  final PermissionHandler _permissionHandler = PermissionHandler();
  StreamSubscription? _requestSubscription;

  @override
  void initState() {
    super.initState();
    _startListeningForRequests();
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }

  void _startListeningForRequests() {
    // Only set up the listener if the user is a patient
    if (FirebaseAuth.instance.currentUser == null) {
      print("User not authenticated, cannot listen for requests");
      return;
    }

    print("Starting to listen for connection requests in PermissionListener");

    _requestSubscription = _permissionHandler
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
          // Show permission dialog
          _showPermissionDialog(requestData);
        }
      }
    }, onError: (error) {
      print("Error in connection request stream: $error");
    });
  }

  void _showPermissionDialog(Map<String, dynamic> requestData) {
    if (!mounted) return;

    print("Showing permission dialog for request: ${requestData['requestId']}");

    // Show dialog on the main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PermissionDialog(
          requestData: requestData,
        ),
      ).then((accepted) {
        if (accepted == true) {
          // Request was accepted
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location sharing enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}