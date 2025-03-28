import 'package:flutter/material.dart';

class CommunityPostDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const CommunityPostDetailScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<CommunityPostDetailScreen> createState() => _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  // Mock comments data
  final List<Map<String, dynamic>> _comments = [
    {
      'username': 'caregiver_advice',
      'userImage': 'https://i.pravatar.cc/150?img=5',
      'text': 'This is so helpful! I\'ve been trying to find activities like this for my mom.',
      'timeAgo': '45 min ago',
      'likes': 12
    },
    {
      'username': 'memory_support',
      'userImage': 'https://i.pravatar.cc/150?img=6',
      'text': 'I\'ve had similar experiences. Nature seems to have a calming effect for many people with dementia.',
      'timeAgo': '1 hour ago',
      'likes': 8
    },
    {
      'username': 'dr_brain_health',
      'userImage': 'https://i.pravatar.cc/150?img=7',
      'text': 'Great observation! Studies show that natural environments can reduce stress and anxiety, which is particularly beneficial for dementia patients.',
      'timeAgo': '1 hour ago',
      'likes': 20
    },
    {
      'username': 'daily_caregiver',
      'userImage': 'https://i.pravatar.cc/150?img=8',
      'text': 'Do you find morning or afternoon walks better? We struggle with sundowning in the evenings.',
      'timeAgo': '2 hours ago',
      'likes': 5
    }
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF503663)),
        title: const Text(
          'Post',
          style: TextStyle(
            color: Color(0xFF503663),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF503663)),
            onPressed: () {
              // Show post options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content (post and comments)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original post
                  _buildPostHeader(),
                  _buildPostImage(),
                  _buildPostActions(),
                  _buildPostLikes(),
                  _buildPostCaption(),
                  _buildPostTime(),

                  const Divider(),

                  // Comments section
                  _buildCommentsList(),
                ],
              ),
            ),
          ),

          // Comment input field at bottom
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostHeader() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(widget.post['userImage']),
          ),
          const SizedBox(width: 8),
          Text(
            widget.post['username'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_vert),
            iconSize: 20,
            onPressed: () {
              // Show post options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    return Image.network(
      widget.post['imageUrl'],
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: 300,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF503663),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 300,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Like post
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              // Focus on comment input
              FocusScope.of(context).requestFocus(FocusNode());
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined),
            onPressed: () {
              // Share post
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // Save post
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostLikes() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
      child: Text(
        '${widget.post['likes']} likes',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPostCaption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black),
          children: [
            TextSpan(
              text: '${widget.post['username']} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: widget.post['caption']),
          ],
        ),
      ),
    );
  }

  Widget _buildPostTime() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        widget.post['timeAgo'],
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      itemBuilder: (context, index) {
        final comment = _comments[index];
        return _buildCommentItem(comment);
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(comment['userImage']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '${comment['username']} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: comment['text']),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      comment['timeAgo'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${comment['likes']} likes',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reply',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 16),
            onPressed: () {
              // Like comment
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(widget.post['userImage']),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          TextButton(
            onPressed: _commentController.text.isEmpty
                ? null
                : () {
              // Submit comment
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comment posted!')),
              );
              _commentController.clear();
            },
            child: Text(
              'Post',
              style: TextStyle(
                color: _commentController.text.isEmpty
                    ? Colors.blue.withOpacity(0.5)
                    : const Color(0xFF503663),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}