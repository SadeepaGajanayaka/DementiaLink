import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  // Create a Message from a Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps being null or timestamps
    Timestamp timestamp = data['createdAt'] is Timestamp
        ? data['createdAt']
        : Timestamp.now();

    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      createdAt: timestamp.toDate(),
      read: data['read'] ?? false,
    );
  }

  // Convert message to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'read': read,
    };
  }
}

class Conversation {
  final String id;
  final List<String> memberIds;
  final Map<String, Map<String, dynamic>> members;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final DateTime lastMessageTime;
  final DateTime createdAt;
  final Map<String, int> unreadCounts;

  Conversation({
    required this.id,
    required this.memberIds,
    required this.members,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.lastMessageTime,
    required this.createdAt,
    required this.unreadCounts,
  });

  // Create a Conversation from a Firestore document
  factory Conversation.fromFirestore(DocumentSnapshot doc, Map<String, int> unreadCounts) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps being null or timestamps
    Timestamp lastMessageTimestamp = data['lastMessageTime'] is Timestamp
        ? data['lastMessageTime']
        : Timestamp.now();

    Timestamp createdTimestamp = data['createdAt'] is Timestamp
        ? data['createdAt']
        : Timestamp.now();

    return Conversation(
      id: doc.id,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members: Map<String, Map<String, dynamic>>.from(data['members'] ?? {}),
      lastMessageText: data['lastMessageText'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: lastMessageTimestamp.toDate(),
      createdAt: createdTimestamp.toDate(),
      unreadCounts: unreadCounts,
    );
  }

  // Get the other user's ID
  String getOtherUserId(String currentUserId) {
    return memberIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  // Get the other user's display name
  String getOtherUserName(String currentUserId) {
    String otherUserId = getOtherUserId(currentUserId);
    if (otherUserId.isEmpty) return '';

    return members[otherUserId]?['displayName'] ??
        members[otherUserId]?['username'] ??
        'User';
  }

  // Get the other user's profile image
  String? getOtherUserImage(String currentUserId) {
    String otherUserId = getOtherUserId(currentUserId);
    if (otherUserId.isEmpty) return null;

    return members[otherUserId]?['profileImageUrl'];
  }

  // Get unread message count for current user
  int getUnreadCount(String currentUserId) {
    return unreadCounts[currentUserId] ?? 0;
  }
}