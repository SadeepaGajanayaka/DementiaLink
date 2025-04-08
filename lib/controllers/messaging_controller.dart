import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/community_service.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import 'dart:async';

class MessagingController extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesByConversation = {};
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  Map<String, StreamSubscription<QuerySnapshot>> _messageSubscriptions = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Conversation> get conversations => _conversations;

  // Get messages for a specific conversation
  List<Message> getMessagesForConversation(String conversationId) {
    return _messagesByConversation[conversationId] ?? [];
  }

  // Initialize and fetch data
  Future<void> initMessaging() async {
    _setLoading(true);

    try {
      // Set up real-time subscription for conversations
      await _setupConversationsSubscription();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Set up real-time subscription for conversations
  Future<void> _setupConversationsSubscription() async {
    // Cancel existing subscription if any
    await _conversationsSubscription?.cancel();

    // Set up new subscription
    _conversationsSubscription = _communityService.getConversations().listen(
          (QuerySnapshot snapshot) async {
        List<Conversation> fetchedConversations = [];

        for (var doc in snapshot.docs) {
          // Get unread counts for this conversation
          Map<String, int> unreadCounts = {};

          String conversationId = doc.id;
          List<String> memberIds = List<String>.from(doc.get('memberIds') ?? []);

          for (var memberId in memberIds) {
            try {
              DocumentSnapshot metadataDoc = await _firestore
                  .collection('conversations')
                  .doc(conversationId)
                  .collection('metadata')
                  .doc(memberId)
                  .get();

              if (metadataDoc.exists) {
                unreadCounts[memberId] = metadataDoc.get('unreadCount') ?? 0;
              } else {
                unreadCounts[memberId] = 0;
              }
            } catch (e) {
              print('Error getting unread count for $memberId: $e');
              unreadCounts[memberId] = 0;
            }
          }

          // Create conversation object
          Conversation conversation = Conversation.fromFirestore(doc, unreadCounts);
          fetchedConversations.add(conversation);
        }

        // Sort conversations by last message time (newest first)
        fetchedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

        _conversations = fetchedConversations;
        notifyListeners();
      },
      onError: (e) {
        print('Error in conversations subscription: $e');
        _errorMessage = 'Failed to update conversations: $e';
        notifyListeners();
      },
    );
  }

  // Get or create conversation with user
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      String conversationId = await _communityService.createOrGetConversation(otherUserId);
      return conversationId;
    } catch (e) {
      print('Error getting/creating conversation: $e');
      rethrow;
    }
  }

  // Fetch messages for a conversation
  Future<void> fetchMessagesForConversation(String conversationId) async {
    _setLoading(true);

    try {
      // Mark messages as read
      await _communityService.markMessagesAsRead(conversationId);

      // Update unread count in UI
      int conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
      if (conversationIndex != -1) {
        String? currentUserId = _communityService.currentUser?.uid;
        if (currentUserId != null) {
          _conversations[conversationIndex].unreadCounts[currentUserId] = 0;
          notifyListeners();
        }
      }

      // Set up real-time subscription for messages
      await _setupMessagesSubscription(conversationId);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Set up real-time subscription for messages
  Future<void> _setupMessagesSubscription(String conversationId) async {
    // Cancel existing subscription if any
    await _messageSubscriptions[conversationId]?.cancel();

    // Set up new subscription
    _messageSubscriptions[conversationId] = _communityService.getMessages(conversationId).listen(
          (QuerySnapshot snapshot) {
        List<Message> messages = snapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .toList();

        // Store messages for this conversation
        _messagesByConversation[conversationId] = messages;
        notifyListeners();
      },
      onError: (e) {
        print('Error in messages subscription: $e');
        _errorMessage = 'Failed to update messages: $e';
        notifyListeners();
      },
    );
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
  }) async {
    try {
      await _communityService.sendMessage(
        conversationId: conversationId,
        receiverId: receiverId,
        text: text,
      );

      // Message will be added through the real-time subscription
    } catch (e) {
      print('Error sending message: $e');
      _errorMessage = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  // Start a new conversation with user
  Future<String> startConversation(UserProfile otherUser) async {
    try {
      // Get or create conversation
      String conversationId = await getOrCreateConversation(otherUser.id);

      // Load messages
      await fetchMessagesForConversation(conversationId);

      return conversationId;
    } catch (e) {
      print('Error starting conversation: $e');
      _errorMessage = 'Failed to start conversation: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clean up resources
  @override
  void dispose() {
    _conversationsSubscription?.cancel();
    for (var subscription in _messageSubscriptions.values) {
      subscription.cancel();
    }
    _messageSubscriptions.clear();
    super.dispose();
  }
}