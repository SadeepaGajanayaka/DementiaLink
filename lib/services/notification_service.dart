import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream subscriptions
  Map<String, StreamSubscription> _subscriptions = {};

  // Notification listeners
  final List<Function(String, String, String)> _notificationListeners = [];

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Initialize the service
  Future<void> initialize() async {
    // No additional initialization needed for Firebase-only implementation
    print('NotificationService initialized');
  }

  // Add a notification listener
  void addListener(Function(String, String, String) listener) {
    _notificationListeners.add(listener);
  }

  // Remove a notification listener
  void removeListener(Function(String, String, String) listener) {
    _notificationListeners.remove(listener);
  }

  // Start listening for notifications
  Future<void> startListening() async {
    // Cancel any existing subscriptions
    await stopListening();

    // Listen for auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenForNotifications(user.uid);
      } else {
        stopListening();
      }
    });
  }

  // Stop listening for notifications
  Future<void> stopListening() async {
    for (var subscription in _subscriptions.values) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  // Listen for incoming messages
  void _listenForNotifications(String userId) {
    // Listen for new messages across all conversations
    final conversationsStream = _firestore
        .collection('conversations')
        .where('memberIds', arrayContains: userId)
        .snapshots();

    _subscriptions['conversations'] = conversationsStream.listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final conversationData = change.doc.data() as Map<String, dynamic>;

        // Check if this is a new message sent by someone else
        if (change.type == DocumentChangeType.modified &&
            conversationData['lastMessageSenderId'] != null &&
            conversationData['lastMessageSenderId'] != userId) {

          // Get conversation details
          final String conversationId = change.doc.id;
          final String lastMessageText = conversationData['lastMessageText'] ?? '';
          final String? senderName = _getSenderName(conversationData, conversationData['lastMessageSenderId']);

          // Notify listeners
          _notifyListeners(
            conversationId: conversationId,
            sender: senderName ?? 'New message',
            message: lastMessageText,
          );
        }
      }
    });

    // Listen for system notifications
    final notificationsStream = _firestore
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .where('read', isEqualTo: false)
        .snapshots();

    _subscriptions['notifications'] = notificationsStream.listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final notificationData = change.doc.data() as Map<String, dynamic>;

          final String notificationType = notificationData['type'] ?? '';
          final String notificationText = notificationData['text'] ?? '';
          final String? senderName = notificationData['senderUsername'];

          // Notify for likes, comments, follows, etc.
          if (notificationType != 'message') { // Skip message notifications as they're handled separately
            _notifyListeners(
              conversationId: notificationData['relatedId'] ?? '',
              sender: senderName ?? 'DementiaLink',
              message: notificationText,
              isSystemNotification: true,
            );
          }
        }
      }
    });
  }

  // Get sender name from conversation data
  String? _getSenderName(Map<String, dynamic> conversationData, String senderId) {
    if (conversationData['members'] != null &&
        conversationData['members'][senderId] != null) {
      final memberData = conversationData['members'][senderId] as Map<String, dynamic>;
      return memberData['displayName'] ?? memberData['username'];
    }
    return null;
  }

  // Notify all listeners of a new notification
  void _notifyListeners({
    required String conversationId,
    required String sender,
    required String message,
    bool isSystemNotification = false,
  }) {
    for (var listener in _notificationListeners) {
      listener(conversationId, sender, message);
    }

    // In a real app, you might want to show an in-app notification here
    print('📱 Notification: $sender - $message');
  }

  // Add a method to show in-app notifications (can be used from anywhere in the app)
  static void showInAppNotification(BuildContext context, String title, String message) {
    // Show a simple snackbar as an in-app notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(message),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Handle notification tap
          },
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}