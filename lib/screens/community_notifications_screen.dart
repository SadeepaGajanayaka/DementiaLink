import 'package:flutter/material.dart';

class CommunityNotificationsScreen extends StatefulWidget {
  const CommunityNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<CommunityNotificationsScreen> createState() => _CommunityNotificationsScreenState();
}

class _CommunityNotificationsScreenState extends State<CommunityNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock notifications data
  final List<Map<String, dynamic>> _activityNotifications = [
    {
      'type': 'like',
      'username': 'caregiver_tips',
      'userImage': 'https://i.pravatar.cc/150?img=15',
      'content': 'liked your photo',
      'time': '2m',
      'isFollowing': true,
      'contentImage': 'https://images.unsplash.com/photo-1493894473891-10fc1e5dbd22',
    },
    {
      'type': 'comment',
      'username': 'memory_support',
      'userImage': 'https://i.pravatar.cc/150?img=16',
      'content': 'commented: "This is so helpful! Thank you for sharing."',
      'time': '15m',
      'isFollowing': false,
      'contentImage': 'https://images.unsplash.com/photo-1556911220-bda9f7b2b187',
    },
    {
      'type': 'mention',
      'username': 'dr_brain_health',
      'userImage': 'https://i.pravatar.cc/150?img=17',
      'content': 'mentioned you in a comment',
      'time': '3h',
      'isFollowing': true,
      'contentImage': null,
    },
    {
      'type': 'follow',
      'username': 'dementia_research',
      'userImage': 'https://i.pravatar.cc/150?img=18',
      'content': 'started following you',
      'time': '5h',
      'isFollowing': false,
      'contentImage': null,
    },
    {
      'type': 'like',
      'username': 'daily_caregiver',
      'userImage': 'https://i.pravatar.cc/150?img=19',
      'content': 'and 24 others liked your photo',
      'time': '1d',
      'isFollowing': true,
      'contentImage': 'https://images.unsplash.com/photo-1471286174890-9c112ffca5b4',
    },
  ];

  // Mock follow requests data
  final List<Map<String, dynamic>> _followRequests = [
    {
      'username': 'new_caregiver22',
      'userImage': 'https://i.pravatar.cc/150?img=20',
      'fullName': 'James Wilson',
      'mutualConnections': 3,
      'time': '2d',
    },
    {
      'username': 'dementia_tips101',
      'userImage': 'https://i.pravatar.cc/150?img=21',
      'fullName': 'Dementia Tips & Tricks',
      'mutualConnections': 5,
      'time': '1w',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF503663),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF503663),
          tabs: const [
            Tab(text: 'Activity'),
            Tab(text: 'Follow Requests'),
          ],
          labelColor: Color(0xFF503663),
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildFollowRequestsTab(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return _activityNotifications.isEmpty
        ? _buildEmptyState('No recent activity')
        : ListView.builder(
      itemCount: _activityNotifications.length,
      itemBuilder: (context, index) {
        final notification = _activityNotifications[index];
        return _buildActivityNotificationItem(notification);
      },
    );
  }

  Widget _buildFollowRequestsTab() {
    return _followRequests.isEmpty
        ? _buildEmptyState('No pending follow requests')
        : ListView.builder(
      itemCount: _followRequests.length,
      itemBuilder: (context, index) {
        final request = _followRequests[index];
        return _buildFollowRequestItem(request);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityNotificationItem(Map<String, dynamic> notification) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(notification['userImage']),
          ),
          const SizedBox(width: 12),

          // Notification content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                        text: '${notification['username']} ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: notification['content']),
                      TextSpan(
                        text: ' • ${notification['time']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content image or follow button
          if (notification['contentImage'] != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  notification['contentImage'],
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else if (notification['type'] == 'follow')
            OutlinedButton(
              onPressed: () {
                // Handle follow back
                setState(() {
                  notification['isFollowing'] = true;
                });
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: notification['isFollowing']
                    ? Colors.white
                    : const Color(0xFF503663),
                side: BorderSide(
                  color: notification['isFollowing']
                      ? Colors.grey
                      : const Color(0xFF503663),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(80, 30),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
              child: Text(
                notification['isFollowing'] ? 'Following' : 'Follow',
                style: TextStyle(
                  color: notification['isFollowing']
                      ? Colors.black
                      : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFollowRequestItem(Map<String, dynamic> request) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          // User avatar
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(request['userImage']),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request['username'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  request['fullName'],
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  '${request['mutualConnections']} mutual connections • ${request['time']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  // Accept follow request
                  setState(() {
                    _followRequests.removeWhere((r) => r['username'] == request['username']);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF503663),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(80, 36),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  // Reject follow request
                  setState(() {
                    _followRequests.removeWhere((r) => r['username'] == request['username']);
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(80, 36),
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}