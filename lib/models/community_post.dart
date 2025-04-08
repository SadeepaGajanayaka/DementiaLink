import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? profileImageUrl;
  final String caption;
  final List<String> imageUrls;
  final String? location;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  bool isLiked; // This is set manually after fetching the post

  CommunityPost({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.profileImageUrl,
    required this.caption,
    required this.imageUrls,
    this.location,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.isLiked = false,
  });

  // Create a Post from a Firestore document
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps being null or timestamps
    Timestamp timestamp = data['createdAt'] is Timestamp
        ? data['createdAt']
        : Timestamp.now();

    return CommunityPost(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      displayName: data['displayName'],
      profileImageUrl: data['profileImageUrl'],
      caption: data['caption'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      location: data['location'],
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: timestamp.toDate(),
    );
  }

  // Convert post to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'caption': caption,
      'imageUrls': imageUrls,
      'location': location,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy of this post with some changed properties
  CommunityPost copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? profileImageUrl,
    String? caption,
    List<String>? imageUrls,
    String? location,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    bool? isLiked,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      caption: caption ?? this.caption,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}