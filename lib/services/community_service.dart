import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/community_post_model.dart';

class CommunityService {
  // This will be replaced with your actual API base URL
  static const String _baseUrl = 'http://localhost:3000/api';

  // Store the authentication token
  String? _authToken;

  // Setter for auth token
  set authToken(String? token) {
    _authToken = token;
  }

  // Create the headers for requests
  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Error handling helper
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      throw Exception('API Error: ${response.statusCode}: ${response.body}');
    }
  }

  // Get feed posts
  Future<List<CommunityPost>> getFeedPosts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts'),
        headers: _getHeaders(),
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((post) => CommunityPost.fromMap(post)).toList();
    } catch (e) {
      print('Error fetching feed posts: $e');
      // For now, we'll return mock data
      return _getMockPosts();
    }
  }

  // Get a specific post by id
  Future<CommunityPost> getPost(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId'),
        headers: _getHeaders(),
      );

      _handleError(response);

      return CommunityPost.fromMap(json.decode(response.body));
    } catch (e) {
      print('Error fetching post: $e');
      // Return a mock post
      return _getMockPosts().first;
    }
  }

  // Create a new post
  Future<CommunityPost> createPost({
    required File imageFile,
    required String caption,
  }) async {
    try {
      // In a real implementation, you would use a multipart request to upload the image
      // For now, we'll just simulate it

      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay

      // Mock response
      return CommunityPost(
        id: 'new-post-${DateTime.now().millisecondsSinceEpoch}',
        username: 'current_user',
        userImage: 'https://i.pravatar.cc/150?img=11',
        imageUrl: 'https://images.unsplash.com/photo-1556911220-bda9f7b2b187',
        caption: caption,
        likes: 0,
        comments: 0,
        timeAgo: 'just now',
      );
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }

  // Like a post
  Future<void> likePost(String postId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/like'),
        headers: _getHeaders(),
      );

      _handleError(response);
    } catch (e) {
      print('Error liking post: $e');
      // Just log for now
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/posts/$postId/like'),
        headers: _getHeaders(),
      );

      _handleError(response);
    } catch (e) {
      print('Error unliking post: $e');
      // Just log for now
    }
  }

  // Comment on a post
  Future<CommunityComment> commentOnPost({
    required String postId,
    required String comment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/posts/$postId/comments'),
        headers: _getHeaders(),
        body: json.encode({
          'text': comment,
        }),
      );

      _handleError(response);

      return CommunityComment.fromMap(json.decode(response.body));
    } catch (e) {
      print('Error commenting on post: $e');
      // Return mock comment
      return CommunityComment(
        id: 'new-comment-${DateTime.now().millisecondsSinceEpoch}',
        username: 'current_user',
        userImage: 'https://i.pravatar.cc/150?img=11',
        text: comment,
        timeAgo: 'just now',
        likes: 0,
      );
    }
  }

  // Get comments for a post
  Future<List<CommunityComment>> getPostComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/posts/$postId/comments'),
        headers: _getHeaders(),
      );

      _handleError(response);

      final List<dynamic> data = json.decode(response.body);
      return data.map((comment) => CommunityComment.fromMap(comment)).toList();
    } catch (e) {
      print('Error fetching post comments: $e');
      // Return mock comments
      return _getMockComments();
    }
  }

  // Get user profile
  Future<CommunityUser> getUserProfile(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$username'),
        headers: _getHeaders(),
      );

      _handleError(response);

      return CommunityUser.fromMap(json.decode(response.body));
    } catch (e) {
      print('Error fetching user profile: $e');
      // Return mock user
      return _getMockUser();
    }
  }

  // Follow a user
  Future<void> followUser(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/$userId/follow'),
        headers: _getHeaders(),
      );

      _handleError(response);
    } catch (e) {
      print('Error following user: $e');
      // Just log for now
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId/follow'),
        headers: _getHeaders(),
      );

      _handleError(response);
    } catch (e) {
      print('Error unfollowing user: $e');
      // Just log for now
    }
  }

  // Search users and hashtags
  Future<Map<String, dynamic>> search(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?q=$query'),
        headers: _getHeaders(),
      );

      _handleError(response);

      return json.decode(response.body);
    } catch (e) {
      print('Error searching: $e');
      // Return mock search results
      return {
        'users': [],
        'hashtags': [],
      };
    }
  }

  // Mock data for development
  List<CommunityPost> _getMockPosts() {
    return [
      CommunityPost(
        id: 'post1',
        username: 'sarah_caregiver',
        userImage: 'https://i.pravatar.cc/150?img=1',
        imageUrl: 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22',
        caption: 'Enjoying a peaceful afternoon together. Found that nature walks really help with anxiety. #DementiaCare #NatureTherapy',
        likes: 128,
        comments: 24,
        timeAgo: '2 hours ago',
      ),
      CommunityPost(
        id: 'post2',
        username: 'alzheimer_support',
        userImage: 'https://i.pravatar.cc/150?img=2',
        imageUrl: 'https://images.unsplash.com/photo-1556911220-bda9f7b2b187',
        caption: 'Today\'s memory activity was a huge success! Music from the 60s really sparked joy and recognition. #MusicTherapy #MemoryCare',
        likes: 256,
        comments: 42,
        timeAgo: '5 hours ago',
      ),
      CommunityPost(
        id: 'post3',
        username: 'memory_lane',
        userImage: 'https://i.pravatar.cc/150?img=3',
        imageUrl: 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4',
        caption: 'Creating a memory box with old photos and memorabilia. These tactile reminders can be incredibly grounding. #DementiaAwareness #MemoryBox',
        likes: 189,
        comments: 35,
        timeAgo: '1 day ago',
      ),
    ];
  }

  List<CommunityComment> _getMockComments() {
    return [
      CommunityComment(
        id: 'comment1',
        username: 'caregiver_advice',
        userImage: 'https://i.pravatar.cc/150?img=5',
        text: 'This is so helpful! I\'ve been trying to find activities like this for my mom.',
        timeAgo: '45 min ago',
        likes: 12,
      ),
      CommunityComment(
        id: 'comment2',
        username: 'memory_support',
        userImage: 'https://i.pravatar.cc/150?img=6',
        text: 'I\'ve had similar experiences. Nature seems to have a calming effect for many people with dementia.',
        timeAgo: '1 hour ago',
        likes: 8,
      ),
      CommunityComment(
        id: 'comment3',
        username: 'dr_brain_health',
        userImage: 'https://i.pravatar.cc/150?img=7',
        text: 'Great observation! Studies show that natural environments can reduce stress and anxiety, which is particularly beneficial for dementia patients.',
        timeAgo: '1 hour ago',
        likes: 20,
      ),
    ];
  }

  CommunityUser _getMockUser() {
    return CommunityUser(
      id: 'user1',
      username: 'john_caregiver',
      name: 'John Anderson',
      profileImage: 'https://i.pravatar.cc/300?img=11',
      bio: 'Caregiver for 5 years | Sharing tips and experiences to help others on this journey | Advocate for dementia awareness',
      postsCount: 24,
      followersCount: 348,
      followingCount: 215,
      isVerified: true,
    );
  }
}