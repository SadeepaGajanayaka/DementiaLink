import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // ===== USER PROFILE OPERATIONS =====

  // Get user profile by user ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? username,
    String? bio,
    String? displayName,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> updateData = {};

      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (displayName != null) updateData['displayName'] = displayName;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // ===== POST OPERATIONS =====

  // Create a new post
  Future<String> createPost({
    required String caption,
    required List<String> imageUrls,
    String? location,
  }) async {
    try {
      // Ensure user is authenticated
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user data
      final userData = await getUserProfile(userId);
      if (userData == null) {
        throw Exception('User profile not found');
      }

      // Create post document
      DocumentReference postRef = await _firestore.collection('posts').add({
        'userId': userId,
        'username': userData['username'] ?? 'user_${userId.substring(0, 5)}',
        'displayName': userData['displayName'],
        'profileImageUrl': userData['profileImageUrl'],
        'caption': caption,
        'imageUrls': imageUrls,
        'location': location ?? '',
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return postRef.id;
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Get posts for feed (from current user and users they follow)
  Stream<QuerySnapshot> getFeedPosts() {
    final userId = currentUser?.uid;
    if (userId == null) {
      // Return empty stream if not authenticated
      return Stream.empty();
    }

    // For simplicity, we'll just return all posts ordered by creation time
    // In a real app, you'd filter based on followed users
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Get posts by specific user
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify post ownership
      DocumentSnapshot post = await _firestore.collection('posts').doc(postId).get();
      if (!post.exists) {
        throw Exception('Post not found');
      }

      Map<String, dynamic> postData = post.data() as Map<String, dynamic>;
      if (postData['userId'] != userId) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete post
      await _firestore.collection('posts').doc(postId).delete();

      // Delete associated likes and comments
      // Note: In a production app, use Firebase Functions for this cleanup
      await _firestore.collection('likes').doc(postId).delete();

      // Delete all comments for the post
      QuerySnapshot commentsSnapshot = await _firestore
          .collection('comments')
          .doc(postId)
          .collection('postComments')
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }

  // ===== LIKE OPERATIONS =====

  // Like or unlike a post
  Future<void> toggleLike(String postId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Reference to the like document
      final likeRef = _firestore
          .collection('likes')
          .doc(postId)
          .collection('userLikes')
          .doc(userId);

      // Check if user already liked the post
      DocumentSnapshot likeDoc = await likeRef.get();

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      if (likeDoc.exists) {
        // Unlike the post
        batch.delete(likeRef);
        batch.update(
            _firestore.collection('posts').doc(postId),
            {'likeCount': FieldValue.increment(-1)}
        );
      } else {
        // Like the post
        batch.set(likeRef, {
          'timestamp': FieldValue.serverTimestamp(),
        });
        batch.update(
            _firestore.collection('posts').doc(postId),
            {'likeCount': FieldValue.increment(1)}
        );
      }

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  // Check if user liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      DocumentSnapshot likeDoc = await _firestore
          .collection('likes')
          .doc(postId)
          .collection('userLikes')
          .doc(userId)
          .get();

      return likeDoc.exists;
    } catch (e) {
      print('Error checking if user liked post: $e');
      return false;
    }
  }

  // Get users who liked a post
  Stream<QuerySnapshot> getLikes(String postId) {
    return _firestore
        .collection('likes')
        .doc(postId)
        .collection('userLikes')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ===== COMMENT OPERATIONS =====

  // Add comment to a post
  Future<String> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user data
      final userData = await getUserProfile(userId);
      if (userData == null) {
        throw Exception('User profile not found');
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Create comment document
      DocumentReference commentRef = _firestore
          .collection('comments')
          .doc(postId)
          .collection('postComments')
          .doc();

      batch.set(commentRef, {
        'userId': userId,
        'username': userData['username'] ?? 'user_${userId.substring(0, 5)}',
        'profileImageUrl': userData['profileImageUrl'],
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update comment count on post
      batch.update(
          _firestore.collection('posts').doc(postId),
          {'commentCount': FieldValue.increment(1)}
      );

      // Commit the batch
      await batch.commit();

      return commentRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  // Get comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('comments')
        .doc(postId)
        .collection('postComments')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Delete a comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify comment ownership
      DocumentSnapshot comment = await _firestore
          .collection('comments')
          .doc(postId)
          .collection('postComments')
          .doc(commentId)
          .get();

      if (!comment.exists) {
        throw Exception('Comment not found');
      }

      Map<String, dynamic> commentData = comment.data() as Map<String, dynamic>;
      if (commentData['userId'] != userId) {
        throw Exception('Not authorized to delete this comment');
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Delete comment
      batch.delete(_firestore
          .collection('comments')
          .doc(postId)
          .collection('postComments')
          .doc(commentId));

      // Update comment count on post
      batch.update(
          _firestore.collection('posts').doc(postId),
          {'commentCount': FieldValue.increment(-1)}
      );

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  // ===== FOLLOW/UNFOLLOW OPERATIONS =====

  // Follow a user
  Future<void> followUser(String targetUserId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (userId == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Add to current user's following
      batch.set(
          _firestore.collection('following').doc(userId).collection('userFollowing').doc(targetUserId),
          {'timestamp': FieldValue.serverTimestamp()}
      );

      // Add to target user's followers
      batch.set(
          _firestore.collection('followers').doc(targetUserId).collection('userFollowers').doc(userId),
          {'timestamp': FieldValue.serverTimestamp()}
      );

      // Update follower/following counts
      batch.update(
          _firestore.collection('users').doc(userId),
          {'following': FieldValue.increment(1)}
      );

      batch.update(
          _firestore.collection('users').doc(targetUserId),
          {'followers': FieldValue.increment(1)}
      );

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error following user: $e');
      rethrow;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String targetUserId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (userId == targetUserId) {
        throw Exception('Cannot unfollow yourself');
      }

      // Start a batch write
      WriteBatch batch = _firestore.batch();

      // Remove from current user's following
      batch.delete(
          _firestore.collection('following').doc(userId).collection('userFollowing').doc(targetUserId)
      );

      // Remove from target user's followers
      batch.delete(
          _firestore.collection('followers').doc(targetUserId).collection('userFollowers').doc(userId)
      );

      // Update follower/following counts
      batch.update(
          _firestore.collection('users').doc(userId),
          {'following': FieldValue.increment(-1)}
      );

      batch.update(
          _firestore.collection('users').doc(targetUserId),
          {'followers': FieldValue.increment(-1)}
      );

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error unfollowing user: $e');
      rethrow;
    }
  }

  // Check if current user follows a specific user
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) return false;

      DocumentSnapshot doc = await _firestore
          .collection('following')
          .doc(userId)
          .collection('userFollowing')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking following status: $e');
      return false;
    }
  }

  // Get user's followers
  Stream<QuerySnapshot> getFollowers(String userId) {
    return _firestore
        .collection('followers')
        .doc(userId)
        .collection('userFollowers')
        .snapshots();
  }

  // Get users that a user follows
  Stream<QuerySnapshot> getFollowing(String userId) {
    return _firestore
        .collection('following')
        .doc(userId)
        .collection('userFollowing')
        .snapshots();
  }

  // ===== STORY OPERATIONS =====

  // Add a story
  Future<String> addStory({
    required String imageUrl,
    int expiresInHours = 24,
  }) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get user data
      final userData = await getUserProfile(userId);
      if (userData == null) {
        throw Exception('User profile not found');
      }

      // Calculate expiration time
      DateTime now = DateTime.now();
      DateTime expiresAt = now.add(Duration(hours: expiresInHours));

      // Create story document
      DocumentReference storyRef = await _firestore
          .collection('stories')
          .doc(userId)
          .collection('userStories')
          .add({
        'userId': userId,
        'username': userData['username'] ?? 'user_${userId.substring(0, 5)}',
        'profileImageUrl': userData['profileImageUrl'],
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'viewCount': 0,
      });

      return storyRef.id;
    } catch (e) {
      print('Error adding story: $e');
      rethrow;
    }
  }

  // Get active stories for feed (from users they follow)
  Stream<QuerySnapshot> getActiveStories() {
    final userId = currentUser?.uid;
    if (userId == null) {
      // Return empty stream if not authenticated
      return Stream.empty();
    }

    // For simplicity, we'll just get all active stories
    // In a real app, you'd filter based on followed users
    DateTime now = DateTime.now();

    return _firestore
        .collectionGroup('userStories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt', descending: false)
        .snapshots();
  }

  // Get stories by specific user
  Stream<QuerySnapshot> getUserStories(String userId) {
    DateTime now = DateTime.now();

    return _firestore
        .collection('stories')
        .doc(userId)
        .collection('userStories')
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt', descending: false)
        .snapshots();
  }

  // Mark story as viewed
  Future<void> viewStory(String userId, String storyId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('stories')
          .doc(userId)
          .collection('userStories')
          .doc(storyId)
          .collection('views')
          .doc(currentUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update view count
      await _firestore
          .collection('stories')
          .doc(userId)
          .collection('userStories')
          .doc(storyId)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error viewing story: $e');
      // Don't rethrow for this operation
    }
  }

  // Check if user has viewed a story
  Future<bool> hasViewedStory(String userId, String storyId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) return false;

      DocumentSnapshot viewDoc = await _firestore
          .collection('stories')
          .doc(userId)
          .collection('userStories')
          .doc(storyId)
          .collection('views')
          .doc(currentUserId)
          .get();

      return viewDoc.exists;
    } catch (e) {
      print('Error checking if story viewed: $e');
      return false;
    }
  }

  // Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('stories')
          .doc(userId)
          .collection('userStories')
          .doc(storyId)
          .delete();
    } catch (e) {
      print('Error deleting story: $e');
      rethrow;
    }
  }

  // ===== DIRECT MESSAGE OPERATIONS =====

  // Create or get conversation with another user
  Future<String> createOrGetConversation(String otherUserId) async {
    try {
      final currentUserId = currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      if (currentUserId == otherUserId) {
        throw Exception('Cannot create conversation with yourself');
      }

      // Create a sorted conversation ID to ensure uniqueness
      List<String> memberIds = [currentUserId, otherUserId];
      memberIds.sort(); // Sort alphabetically
      String conversationId = memberIds.join('_');

      // Check if conversation already exists
      DocumentSnapshot conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!conversationDoc.exists) {
        // Get user profiles
        final currentUserData = await getUserProfile(currentUserId);
        final otherUserData = await getUserProfile(otherUserId);

        if (currentUserData == null || otherUserData == null) {
          throw Exception('User profiles not found');
        }

        // Create the conversation
        await _firestore.collection('conversations').doc(conversationId).set({
          'memberIds': memberIds,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageText': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'members': {
            currentUserId: {
              'username': currentUserData['username'] ?? 'user_${currentUserId.substring(0, 5)}',
              'displayName': currentUserData['displayName'],
              'profileImageUrl': currentUserData['profileImageUrl'],
            },
            otherUserId: {
              'username': otherUserData['username'] ?? 'user_${otherUserId.substring(0, 5)}',
              'displayName': otherUserData['displayName'],
              'profileImageUrl': otherUserData['profileImageUrl'],
            },
          },
        });
      }

      return conversationId;
    } catch (e) {
      print('Error creating/getting conversation: $e');
      rethrow;
    }
  }

  // Send a message
  Future<String> sendMessage({
    required String conversationId,
    required String receiverId,
    required String text,
  }) async {
    try {
      final senderId = currentUser?.uid;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      // Create message document
      DocumentReference messageRef = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update conversation with last message info
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessageText': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': senderId,
      });

      // Update unread count for receiver
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('metadata')
          .doc(receiverId)
          .set({
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      return messageRef.id;
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Get messages for a conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Get all conversations for current user
  Stream<QuerySnapshot> getConversations() {
    final userId = currentUser?.uid;
    if (userId == null) {
      // Return empty stream if not authenticated
      return Stream.empty();
    }

    return _firestore
        .collection('conversations')
        .where('memberIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get unread messages
      QuerySnapshot unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      // Mark messages as read in a batch
      if (unreadMessages.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }

      // Reset unread count
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('metadata')
          .doc(userId)
          .set({
        'unreadCount': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error marking messages as read: $e');
      // Don't rethrow for this operation
    }
  }

  // ===== SEARCH OPERATIONS =====

  // Search for users
  Future<List<DocumentSnapshot>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    try {
      // Convert query to lowercase for case-insensitive search
      String searchQuery = query.toLowerCase();

      // Search by username (starting with query)
      QuerySnapshot usernameResults = await _firestore
          .collection('users')
          .where('username_lowercase', isGreaterThanOrEqualTo: searchQuery)
          .where('username_lowercase', isLessThan: searchQuery + 'z')
          .limit(20)
          .get();

      // Search by display name (starting with query)
      QuerySnapshot displayNameResults = await _firestore
          .collection('users')
          .where('displayName_lowercase', isGreaterThanOrEqualTo: searchQuery)
          .where('displayName_lowercase', isLessThan: searchQuery + 'z')
          .limit(20)
          .get();

      // Combine results (remove duplicates)
      Map<String, DocumentSnapshot> uniqueResults = {};

      for (var doc in usernameResults.docs) {
        uniqueResults[doc.id] = doc;
      }

      for (var doc in displayNameResults.docs) {
        uniqueResults[doc.id] = doc;
      }

      return uniqueResults.values.toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Search for posts by hashtag
  Future<List<DocumentSnapshot>> searchPostsByHashtag(String hashtag) async {
    if (hashtag.isEmpty) return [];

    try {
      // Remove # symbol if present
      if (hashtag.startsWith('#')) {
        hashtag = hashtag.substring(1);
      }

      // Search for posts with matching hashtag
      QuerySnapshot results = await _firestore
          .collection('posts')
          .where('hashtags', arrayContains: hashtag.toLowerCase())
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return results.docs;
    } catch (e) {
      print('Error searching posts by hashtag: $e');
      return [];
    }
  }

  // ===== NOTIFICATION OPERATIONS =====

  // Create a notification
  Future<void> createNotification({
    required String recipientId,
    required String type,
    required String text,
    String? relatedId,
  }) async {
    try {
      final senderId = currentUser?.uid;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      // Don't notify yourself
      if (senderId == recipientId) return;

      // Get sender data
      final senderData = await getUserProfile(senderId);
      if (senderData == null) {
        throw Exception('User profile not found');
      }

      // Create notification document
      await _firestore
          .collection('notifications')
          .doc(recipientId)
          .collection('userNotifications')
          .add({
        'senderId': senderId,
        'senderUsername': senderData['username'] ?? 'user_${senderId.substring(0, 5)}',
        'senderProfileImage': senderData['profileImageUrl'],
        'type': type, // like, comment, follow, etc.
        'text': text,
        'relatedId': relatedId, // postId, commentId, etc.
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error creating notification: $e');
      // Don't rethrow for this operation
    }
  }

  // Get notifications for current user
  Stream<QuerySnapshot> getNotifications() {
    final userId = currentUser?.uid;
    if (userId == null) {
      // Return empty stream if not authenticated
      return Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('userNotifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('userNotifications')
          .doc(notificationId)
          .update({
        'read': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      // Don't rethrow for this operation
    }
  }

  // Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get unread notifications
      QuerySnapshot unreadNotifications = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('userNotifications')
          .where('read', isEqualTo: false)
          .get();

      // Mark notifications as read in a batch
      if (unreadNotifications.docs.isNotEmpty) {
        WriteBatch batch = _firestore.batch();
        for (var doc in unreadNotifications.docs) {
          batch.update(doc.reference, {'read': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      // Don't rethrow for this operation
    }
  }

  // ===== EXPLORE/DISCOVER OPERATIONS =====

  // Get trending posts
  Future<List<DocumentSnapshot>> getTrendingPosts() async {
    try {
      // For simplicity, we'll define trending as posts with the most likes/comments
      // In a real app, you'd have a more sophisticated algorithm
      QuerySnapshot results = await _firestore
          .collection('posts')
          .orderBy('likeCount', descending: true)
          .limit(20)
          .get();

      return results.docs;
    } catch (e) {
      print('Error getting trending posts: $e');
      return [];
    }
  }

  // Get suggested users to follow
  Future<List<DocumentSnapshot>> getSuggestedUsers() async {
    try {
      final userId = currentUser?.uid;
      if (userId == null) {
        return [];
      }

      // For simplicity, we'll just return some recent users
      // In a real app, you'd have a more sophisticated algorithm
      QuerySnapshot results = await _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .orderBy(FieldPath.documentId)
          .limit(10)
          .get();

      // Filter out users already being followed
      List<DocumentSnapshot> filteredResults = [];
      for (var doc in results.docs) {
        bool isFollowing = await this.isFollowing(doc.id);
        if (!isFollowing) {
          filteredResults.add(doc);
        }
      }

      return filteredResults;
    } catch (e) {
      print('Error getting suggested users: $e');
      return [];
    }
  }

  // Get popular hashtags
  Future<List<Map<String, dynamic>>> getPopularHashtags() async {
    try {
      // In a real app, you'd have a collection to track hashtag usage
      // For simplicity, we'll return mock data
      return [
        {'tag': 'dementia', 'count': 1245},
        {'tag': 'caregiver', 'count': 856},
        {'tag': 'memory', 'count': 734},
        {'tag': 'support', 'count': 612},
        {'tag': 'community', 'count': 589},
      ];
    } catch (e) {
      print('Error getting popular hashtags: $e');
      return [];
    }
  }
}