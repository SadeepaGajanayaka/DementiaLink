class CommunityPost {
  final String id;
  final String username;
  final String userImage;
  final String imageUrl;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final bool isLiked;
  final bool isSaved;

  CommunityPost({
    required this.id,
    required this.username,
    required this.userImage,
    required this.imageUrl,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    this.isLiked = false,
    this.isSaved = false,
  });

  CommunityPost copyWith({
    String? id,
    String? username,
    String? userImage,
    String? imageUrl,
    String? caption,
    int? likes,
    int? comments,
    String? timeAgo,
    bool? isLiked,
    bool? isSaved,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      timeAgo: timeAgo ?? this.timeAgo,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  // Convert to map for sending to backend
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'userImage': userImage,
      'imageUrl': imageUrl,
      'caption': caption,
      'likes': likes,
      'comments': comments,
      'timeAgo': timeAgo,
      'isLiked': isLiked,
      'isSaved': isSaved,
    };
  }

  // Create from map received from backend
  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      userImage: map['userImage'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] ?? '',
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      timeAgo: map['timeAgo'] ?? '',
      isLiked: map['isLiked'] ?? false,
      isSaved: map['isSaved'] ?? false,
    );
  }
}

class CommunityComment {
  final String id;
  final String username;
  final String userImage;
  final String text;
  final String timeAgo;
  final int likes;
  final bool isLiked;

  CommunityComment({
    required this.id,
    required this.username,
    required this.userImage,
    required this.text,
    required this.timeAgo,
    required this.likes,
    this.isLiked = false,
  });

  CommunityComment copyWith({
    String? id,
    String? username,
    String? userImage,
    String? text,
    String? timeAgo,
    int? likes,
    bool? isLiked,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      username: username ?? this.username,
      userImage: userImage ?? this.userImage,
      text: text ?? this.text,
      timeAgo: timeAgo ?? this.timeAgo,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  // Convert to map for sending to backend
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'userImage': userImage,
      'text': text,
      'timeAgo': timeAgo,
      'likes': likes,
      'isLiked': isLiked,
    };
  }

  // Create from map received from backend
  factory CommunityComment.fromMap(Map<String, dynamic> map) {
    return CommunityComment(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      userImage: map['userImage'] ?? '',
      text: map['text'] ?? '',
      timeAgo: map['timeAgo'] ?? '',
      likes: map['likes'] ?? 0,
      isLiked: map['isLiked'] ?? false,
    );
  }
}

class CommunityUser {
  final String id;
  final String username;
  final String name;
  final String profileImage;
  final String bio;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final bool isFollowing;

  CommunityUser({
    required this.id,
    required this.username,
    required this.name,
    required this.profileImage,
    required this.bio,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    this.isVerified = false,
    this.isFollowing = false,
  });

  CommunityUser copyWith({
    String? id,
    String? username,
    String? name,
    String? profileImage,
    String? bio,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isVerified,
    bool? isFollowing,
  }) {
    return CommunityUser(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isVerified: isVerified ?? this.isVerified,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }

  // Convert to map for sending to backend
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'profileImage': profileImage,
      'bio': bio,
      'postsCount': postsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
      'isFollowing': isFollowing,
    };
  }

  // Create from map received from backend
  factory CommunityUser.fromMap(Map<String, dynamic> map) {
    return CommunityUser(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      profileImage: map['profileImage'] ?? '',
      bio: map['bio'] ?? '',
      postsCount: map['postsCount'] ?? 0,
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isFollowing: map['isFollowing'] ?? false,
    );
  }
}