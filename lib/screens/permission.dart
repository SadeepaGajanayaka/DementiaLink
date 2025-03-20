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

  // Listen for connection requests
  Stream<DatabaseEvent> listenForConnectionRequests() {
    if (_auth.currentUser == null) {
      return const Stream.empty();
    }

    // Create reference to the patient's connection requests node
    DatabaseReference requestsRef = _database
        .ref()
        .child('connection_requests')
        .child(_auth.currentUser!.uid);

    // Return the stream of events
    return requestsRef.onChildAdded;
  }

  // Send a connection request
  Future<bool> sendConnectionRequest({
    required String patientId,
    required String patientEmail,
    required String caregiverName,
    required String caregiverEmail,
  }) async {
    if (_auth.currentUser == null) return false;

    try {
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
      await _database
          .ref()
          .child('connection_requests')
          .child(patientId)
          .child(requestId)
          .set(requestData);

      // Also save to Firestore for persistence
      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .set({
        ...requestData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Connection request sent to patient: $patientId");
      return true;
    } catch (e) {
      print("Error sending connection request: $e");
      return false;
    }
  }

  // Accept a connection request
  Future<bool> acceptConnectionRequest(String requestId) async {
    if (_auth.currentUser == null) return false;

    try {
      // Get the request data
      DatabaseReference requestRef = _database
          .ref()
          .child('connection_requests')
          .child(_auth.currentUser!.uid)
          .child(requestId);

      DataSnapshot snapshot = await requestRef.get();
      if (!snapshot.exists) {
        print("Request not found");
        return false;
      }

      // Extract request data
      Map<String, dynamic> requestData = Map<String, dynamic>.from(snapshot.value as Map);
      String caregiverId = requestData['caregiverId'];
      String caregiverName = requestData['caregiverName'];
      String caregiverEmail = requestData['caregiverEmail'];
      String patientId = requestData['patientId'];
      String patientEmail = requestData['patientEmail'];

      // Update request status
      await requestRef.update({'status': 'accepted'});
      await _firestore
          .collection('connection_requests')
          .doc(requestId)
          .update({'status': 'accepted'});

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

      print("Connection request accepted");
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
      // Get the request data
      DatabaseReference requestRef = _database
          .ref()
          .child('connection_requests')
          .child(_auth.currentUser!.uid)
          .child(requestId);

      DataSnapshot snapshot = await requestRef.get();
      if (!snapshot.exists) {
        print("Request not found");
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

      print("Connection request rejected");
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
      await _database
          .ref()
          .child('connection_requests')
          .child(_auth.currentUser!.uid)
          .child(requestId)
          .remove();

      print("Connection request deleted");
      return true;
    } catch (e) {
      print("Error deleting connection request: $e");
      return false;
    }
  }
}

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
      bool success = await _permissionHandler.acceptConnectionRequest(widget.requestData['requestId']);

      if (success && mounted) {
        Navigator.of(context).pop(true); // Return true for accepted
      } else if (mounted) {
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
      bool success = await _permissionHandler.rejectConnectionRequest(widget.requestData['requestId']);

      if (success && mounted) {
        Navigator.of(context).pop(false); // Return false for rejected
      } else if (mounted) {
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
    _requestSubscription = _permissionHandler
        .listenForConnectionRequests()
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        print("New connection request received: ${event.snapshot.key}");

        // Extract request data
        final requestData = Map<String, dynamic>.from(event.snapshot.value as Map);

        // Show permission dialog
        _showPermissionDialog(requestData);
      }
    }, onError: (error) {
      print("Error in connection request stream: $error");
    });
  }

  void _showPermissionDialog(Map<String, dynamic> requestData) {
    // Check if request is already processed
    if (requestData['status'] != 'pending') {
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}