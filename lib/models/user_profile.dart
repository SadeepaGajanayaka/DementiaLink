import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? profileImageUrl;
  final int followers;
  final int following;
  final String? role; // 'patient' or 'caregiver'
  final DateTime createdAt;
  final DateTime? lastActive;
  bool isFollowed; // This is set manually after fetching

  UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.profileImageUrl,
    required this.followers,
    required this.following,
    this.role,
    required this.createdAt,
    this.lastActive,
    this.isFollowed = false,
  });

  // Create a User Profile from a Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps being null or timestamps
    Timestamp createdTimestamp = data['createdAt'] is Timestamp
        ? data['createdAt']
        : Timestamp.now();

    Timestamp? lastActiveTimestamp = data['lastActive'] is Timestamp
        ? data['lastActive']
        : null;

    return UserProfile(
      id: doc.id,
      username: data['username'] ?? 'user_${doc.id.substring(0, 5)}',
      displayName: data['displayName'],
      bio: data['bio'],
      profileImageUrl: data['profileImageUrl'],
      followers: data['followers'] ?? 0,
      following: data['following'] ?? 0,
      role: data['role'],
      createdAt: createdTimestamp.toDate(),
      lastActive: lastActiveTimestamp?.toDate(),
    );
  }

  // Convert user profile to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'username_lowercase': username.toLowerCase(), // For case-insensitive search
      'displayName': displayName,
      'displayName_lowercase': displayName?.toLowerCase(), // For case-insensitive search
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'followers': followers,
      'following': following,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }

  // Create a copy of this profile with some changed properties
  UserProfile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? bio,
    String? profileImageUrl,
    int? followers,
    int? following,
    String? role,
    DateTime? createdAt,
    DateTime? lastActive,
    bool? isFollowed,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}