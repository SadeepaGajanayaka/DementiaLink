import 'package:cloud_firestore/cloud_firestore.dart';

class Story {
  final String id;
  final String userId;
  final String username;
  final String? profileImageUrl;
  final String imageUrl;
  final int viewCount;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool viewed; // This is set manually after fetching

  Story({
    required this.id,
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.imageUrl,
    required this.viewCount,
    required this.createdAt,
    required this.expiresAt,
    this.viewed = false,
  });

  // Create a Story from a Firestore document
  factory Story.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Handle timestamps being null or timestamps
    Timestamp createdTimestamp = data['createdAt'] is Timestamp
        ? data['createdAt']
        : Timestamp.now();

    Timestamp expiresTimestamp = data['expiresAt'] is Timestamp
        ? data['expiresAt']
        : Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));

    return Story(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      imageUrl: data['imageUrl'] ?? '',
      viewCount: data['viewCount'] ?? 0,
      createdAt: createdTimestamp.toDate(),
      expiresAt: expiresTimestamp.toDate(),
    );
  }

  // Convert story to a map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'imageUrl': imageUrl,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  // Check if story is still active
  bool isActive() {
    return DateTime.now().isBefore(expiresAt);
  }

  // Time remaining until expiration
  Duration timeRemaining() {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }
    return expiresAt.difference(now);
  }
}

class UserStories {
  final String userId;
  final String username;
  final String? profileImageUrl;
  final List<Story> stories;
  bool hasUnviewedStories; // Set manually after checking each story

  UserStories({
    required this.userId,
    required this.username,
    this.profileImageUrl,
    required this.stories,
    this.hasUnviewedStories = false,
  });

  // Group stories by user
  static List<UserStories> groupByUser(List<Story> allStories) {
    Map<String, UserStories> userStoriesMap = {};

    for (var story in allStories) {
      if (!userStoriesMap.containsKey(story.userId)) {
        userStoriesMap[story.userId] = UserStories(
          userId: story.userId,
          username: story.username,
          profileImageUrl: story.profileImageUrl,
          stories: [],
        );
      }

      userStoriesMap[story.userId]!.stories.add(story);

      // Update unviewed status
      if (!story.viewed) {
        userStoriesMap[story.userId]!.hasUnviewedStories = true;
      }
    }

    // Sort each user's stories by creation time
    for (var userStories in userStoriesMap.values) {
      userStories.stories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return userStoriesMap.values.toList();
  }
}