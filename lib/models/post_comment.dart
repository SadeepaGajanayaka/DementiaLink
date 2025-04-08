import 'package:cloud_firestore/cloud_firestore.dart';

class PostComment {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.text,
    required this.createdAt,
  });

  // Create a Comment from a Firestore document
  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps being null or timestamps
    Timestamp timestamp = data['createdAt'] is Timestamp
        ? data['createdAt']
        : Timestamp.now();

    return PostComment(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      text: data['text'] ?? '',
      createdAt: timestamp.toDate(),
    );
  }

  // Convert comment to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}