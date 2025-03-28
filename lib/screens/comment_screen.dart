import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserPhotoUrl;
  final String postUserId;
  final String postUserName;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserPhotoUrl,
    required this.postUserId,
    required this.postUserName,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Add comment to the post's comments collection
      await _firestore
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': widget.currentUserId,
        'userName': widget.currentUserName,
        'userPhotoUrl': widget.currentUserPhotoUrl,
        'text': _commentController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update comment count in the post document
      await _firestore.collection('community_posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Clear the input field
      _commentController.clear();

      // Add a notification for the post owner (if it's not their own comment)
      if (widget.currentUserId != widget.postUserId) {
        await _firestore.collection('notifications').add({
          'receiverId': widget.postUserId,
          'senderId': widget.currentUserId,
          'senderName': widget.currentUserName,
          'senderPhotoUrl': widget.currentUserPhotoUrl,
          'type': 'comment',
          'postId': widget.postId,
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error submitting comment: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting comment: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      // Delete the comment document
      await _firestore
          .collection('community_posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Decrease the comment count
      await _firestore.collection('community_posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted')),
      );
    } catch (e) {
      print('Error deleting comment: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF503663),
      appBar: AppBar(
        backgroundColor: const Color(0xFF503663),
        title: const Text(
          'Comments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Comment list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('community_posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var comment = snapshot.data!.docs[index];
                    Map<String, dynamic> commentData = comment.data() as Map<String, dynamic>;

                    String userId = commentData['userId'] ?? '';
                    String userName = commentData['userName'] ?? 'User';
                    String? userPhotoUrl = commentData['userPhotoUrl'];
                    String text = commentData['text'] ?? '';

                    // Format timestamp
                    Timestamp? timestamp = commentData['timestamp'] as Timestamp?;
                    String timeAgo = timestamp != null
                        ? _getTimeAgo(timestamp.toDate())
                        : '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User avatar
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF77588D),
                              backgroundImage: userPhotoUrl != null
                                  ? NetworkImage(userPhotoUrl)
                                  : null,
                              child: userPhotoUrl == null
                                  ? const Icon(Icons.person, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),

                            // Comment content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF503663),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        timeAgo,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),

                                      // Delete option if current user's comment
                                      if (userId == widget.currentUserId)
                                        IconButton(
                                          icon: const Icon(Icons.delete, size: 16),
                                          color: Colors.grey[400],
                                          onPressed: () => _deleteComment(comment.id),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // User avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF77588D),
                    backgroundImage: widget.currentUserPhotoUrl != null
                        ? NetworkImage(widget.currentUserPhotoUrl!)
                        : null,
                    child: widget.currentUserPhotoUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),

                  // Comment text field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        isDense: true,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Post button
                  TextButton(
                    onPressed: _isSubmitting ? null : _submitComment,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF77588D),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF77588D),
                      ),
                    )
                        : const Text('Post'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}