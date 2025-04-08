import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/community_service.dart';
import '../models/message.dart';
import '../models/user_profile.dart';

class MessagingController extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messagesByConversation = {};

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
      await _fetchConversations();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Fetch conversations
  Future<void> _fetchConversations() async {
    try {
      // Get conversations from Firestore
      QuerySnapshot conversationsSnapshot = await _communityService.getConversations().first;

      // For each conversation, get unread counts
      List<Conversation> fetchedConversations = [];

      for (var doc in conversationsSnapshot.docs) {
        // Get unread counts for this conversation
        Map<String, int> unreadCounts = {};

        String conversationId = doc.id;
        List<String> memberIds = List<String>.from(doc.get('memberIds') ?? []);

        for (var memberId in memberIds) {
          try {
            DocumentSnapshot metadataDoc = await FirebaseFirestore.instance
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

      _conversations = fetchedConversations;
      notifyListeners();
    } catch (e) {
      print('Error fetching conversations: $e');
      rethrow;
    }
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

      // Get messages stream
      QuerySnapshot messagesSnapshot = await _communityService.getMessages(conversationId).first;

      // Convert to Message objects
      List<Message> messages = messagesSnapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();

      // Store messages for this conversation
      _messagesByConversation[conversationId] = messages;
      notifyListeners();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load messages: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
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

      // Refresh messages for this conversation
      await fetchMessagesForConversation(conversationId);

      // Refresh conversations list to update last message
      await _fetchConversations();
    } catch (e) {
      print('Error sending message: $e');
      // Show error but don't update state
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

      // Refresh conversations list
      await _fetchConversations();

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
}