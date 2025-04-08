import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/community_service.dart';
import '../models/community_post.dart';
import '../models/post_comment.dart';
import '../models/user_profile.dart';
import '../models/story.dart';

class CommunityController extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  List<CommunityPost> _posts = [];
  List<UserStories> _stories = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CommunityPost> get posts => _posts;
  List<UserStories> get stories => _stories;

  // Initialize and fetch data
  Future<void> initFeed() async {
    _setLoading(true);

    try {
      await Future.wait([
        _fetchPosts(),
        _fetchStories(),
      ]);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load feed: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Fetch posts for feed
  Future<void> _fetchPosts() async {
    try {
      // Get posts from Firestore
      QuerySnapshot postsSnapshot = await _communityService.getFeedPosts().first;

      // Convert to Post objects
      List<CommunityPost> fetchedPosts = postsSnapshot.docs
          .map((doc) => CommunityPost.fromFirestore(doc))
          .toList();

      // Check if current user liked each post
      for (var post in fetchedPosts) {
        post.isLiked = await _communityService.hasUserLikedPost(post.id);
      }

      _posts = fetchedPosts;
      notifyListeners();
    } catch (e) {
      print('Error fetching posts: $e');
      rethrow;
    }
  }

  // Fetch stories
  Future<void> _fetchStories() async {
    try {
      // Get active stories
      QuerySnapshot storiesSnapshot = await _communityService.getActiveStories().first;

      // Convert to Story objects
      List<Story> fetchedStories = storiesSnapshot.docs
          .map((doc) => Story.fromFirestore(doc))
          .toList();

      // Check if current user viewed each story
      for (var story in fetchedStories) {
        story.viewed = await _communityService.hasViewedStory(story.userId, story.id);
      }

      // Group stories by user
      _stories = UserStories.groupByUser(fetchedStories);
      notifyListeners();
    } catch (e) {
      print('Error fetching stories: $e');
      rethrow;
    }
  }

  // Create a new post
  Future<void> createPost({
    required String caption,
    required List<String> imageUrls,
    String? location,
  }) async {
    _setLoading(true);

    try {
      await _communityService.createPost(
        caption: caption,
        imageUrls: imageUrls,
        location: location,
      );

      // Refresh feed
      await _fetchPosts();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to create post: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Like or unlike a post
  Future<void> toggleLike(String postId) async {
    try {
      await _communityService.toggleLike(postId);

      // Update local state
      int index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        CommunityPost post = _posts[index];
        bool newLikeStatus = !post.isLiked;
        int newLikeCount = post.likeCount + (newLikeStatus ? 1 : -1);

        _posts[index] = post.copyWith(
          isLiked: newLikeStatus,
          likeCount: newLikeCount,
        );

        notifyListeners();
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Don't update UI if there's an error
    }
  }

  // Add a comment to a post
  Future<void> addComment({
    required String postId,
    required String text,
  }) async {
    try {
      await _communityService.addComment(
        postId: postId,
        text: text,
      );

      // Update local state
      int index = _posts.indexWhere((post) => post.id == postId);
      if (index != -1) {
        CommunityPost post = _posts[index];

        _posts[index] = post.copyWith(
          commentCount: post.commentCount + 1,
        );

        notifyListeners();
      }
    } catch (e) {
      print('Error adding comment: $e');
      // Don't update UI if there's an error
    }
  }

  // Get comments for a post
  Future<List<PostComment>> getComments(String postId) async {
    try {
      QuerySnapshot commentsSnapshot = await _communityService.getComments(postId).first;

      return commentsSnapshot.docs
          .map((doc) => PostComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  // Create a story
  Future<void> addStory(String imageUrl) async {
    _setLoading(true);

    try {
      await _communityService.addStory(imageUrl: imageUrl);

      // Refresh stories
      await _fetchStories();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to add story: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // View a story
  Future<void> viewStory(String userId, String storyId) async {
    try {
      await _communityService.viewStory(userId, storyId);

      // Update local state
      for (var userStories in _stories) {
        if (userStories.userId == userId) {
          for (var story in userStories.stories) {
            if (story.id == storyId && !story.viewed) {
              story.viewed = true;

              // Check if all stories are now viewed
              bool allViewed = true;
              for (var s in userStories.stories) {
                if (!s.viewed) {
                  allViewed = false;
                  break;
                }
              }

              if (allViewed) {
                userStories.hasUnviewedStories = false;
              }

              notifyListeners();
              break;
            }
          }
        }
      }
    } catch (e) {
      print('Error viewing story: $e');
      // Don't update UI if there's an error
    }
  }

  // Follow or unfollow a user
  Future<void> toggleFollow(String userId) async {
    try {
      // Check current follow status
      bool isFollowing = await _communityService.isFollowing(userId);

      if (isFollowing) {
        await _communityService.unfollowUser(userId);
      } else {
        await _communityService.followUser(userId);
      }

      // Refresh feed (since following status affects feed)
      await initFeed();
    } catch (e) {
      print('Error toggling follow: $e');
      // Don't update UI if there's an error
    }
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      Map<String, dynamic>? userData = await _communityService.getUserProfile(userId);
      if (userData == null) return null;

      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      UserProfile profile = UserProfile.fromFirestore(doc);

      // Check if current user follows this user
      profile.isFollowed = await _communityService.isFollowing(userId);

      return profile;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = _communityService.currentUser?.uid;
    if (userId == null) return null;

    return getUserProfile(userId);
  }

  // Get posts by a specific user
  Future<List<CommunityPost>> getUserPosts(String userId) async {
    try {
      QuerySnapshot postsSnapshot = await _communityService.getUserPosts(userId).first;

      // Convert to Post objects
      List<CommunityPost> userPosts = postsSnapshot.docs
          .map((doc) => CommunityPost.fromFirestore(doc))
          .toList();

      // Check if current user liked each post
      for (var post in userPosts) {
        post.isLiked = await _communityService.hasUserLikedPost(post.id);
      }

      return userPosts;
    } catch (e) {
      print('Error getting user posts: $e');
      return [];
    }
  }

  // Search for users
  Future<List<UserProfile>> searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      List<DocumentSnapshot> results = await _communityService.searchUsers(query);

      List<UserProfile> users = [];
      for (var doc in results) {
        UserProfile user = UserProfile.fromFirestore(doc);
        user.isFollowed = await _communityService.isFollowing(user.id);
        users.add(user);
      }

      return users;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Search posts by hashtag
  Future<List<CommunityPost>> searchPostsByHashtag(String hashtag) async {
    try {
      if (hashtag.isEmpty) return [];

      List<DocumentSnapshot> results = await _communityService.searchPostsByHashtag(hashtag);

      List<CommunityPost> posts = [];
      for (var doc in results) {
        CommunityPost post = CommunityPost.fromFirestore(doc);
        post.isLiked = await _communityService.hasUserLikedPost(post.id);
        posts.add(post);
      }

      return posts;
    } catch (e) {
      print('Error searching posts by hashtag: $e');
      return [];
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    _setLoading(true);

    try {
      await _communityService.deletePost(postId);

      // Update local state
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to delete post: $e';
      print(_errorMessage);
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}