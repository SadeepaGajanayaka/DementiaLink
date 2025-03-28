import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String receiverId;
  final String receiverName;
  final String? receiverPhotoUrl;

  const ChatDetailScreen({
    Key? key,
    required this.chatRoomId,
    required this.receiverId,
    required this.receiverName,
    this.receiverPhotoUrl,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();

  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserPhotoUrl;
  bool _isLoading = true;
  bool _isSendingMessage = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _currentUserId = _authService.currentUser?.uid;

      if (_currentUserId != null) {
        Map<String, dynamic> userData = await _authService.getUserData(_currentUserId!);
        setState(() {
          _currentUserName = userData['name'] ?? 'User';
          _currentUserPhotoUrl = userData['photoUrl'];
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });

        // Upload and send immediately
        _sendMessage(isImage: true);
      }
    } catch (e) {
      print('Error selecting image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _sendMessage({bool isImage = false}) async {
    if (isImage && _selectedImage == null) return;
    if (!isImage && _messageController.text.trim().isEmpty) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      String? imageUrl;

      // Upload image if needed
      if (isImage && _selectedImage != null) {
        String filePath = 'chat_images/${widget.chatRoomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child(filePath);

        await ref.putFile(
          _selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        imageUrl = await ref.getDownloadURL();
      }

      // Get message text or empty string for image messages
      String messageText = isImage ? '' : _messageController.text.trim();

      // Create message document
      await _firestore
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'receiverId': widget.receiverId,
        'text': messageText,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Update last message in chat room
      await _firestore
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .update({
        'lastMessage': isImage ? 'Image' : messageText,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUserId,
      });

      // Clear input
      if (!isImage) {
        _messageController.clear();
      }

      setState(() {
        _selectedImage = null;
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EBF8), // Light purple background
      appBar: AppBar(
        backgroundColor: const Color(0xFF503663),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF77588D),
              backgroundImage: widget.receiverPhotoUrl != null
                  ? NetworkImage(widget.receiverPhotoUrl!)
                  : null,
              child: widget.receiverPhotoUrl == null
                  ? const Icon(Icons.person, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              widget.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF503663),
        ),
      )
          : Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF503663),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF77588D),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation with ${widget.receiverName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Mark messages as read
                _markMessagesAsRead(snapshot.data!.docs);

                // Build message list
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    Map<String, dynamic> messageData = message.data() as Map<String, dynamic>;

                    String senderId = messageData['senderId'] ?? '';
                    bool isCurrentUser = senderId == _currentUserId;
                    String text = messageData['text'] ?? '';
                    String? imageUrl = messageData['imageUrl'];

                    // Format timestamp
                    Timestamp? timestamp = messageData['timestamp'] as Timestamp?;
                    String timeString = timestamp != null
                        ? _formatTime(timestamp.toDate())
                        : '';

                    return _buildMessageBubble(
                      isCurrentUser: isCurrentUser,
                      text: text,
                      imageUrl: imageUrl,
                      time: timeString,
                    );
                  },
                );
              },
            ),
          ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isSendingMessage ? null : () => _sendMessage(isImage: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF77588D),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSendingMessage
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Send'),
                  ),
                ],
              ),
            ),

          // Message input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Image picker button
                IconButton(
                  icon: const Icon(Icons.photo, color: Color(0xFF77588D)),
                  onPressed: _selectImage,
                ),

                // Text input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),

                // Send button
                IconButton(
                  icon: _isSendingMessage
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Color(0xFF77588D),
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.send, color: Color(0xFF77588D)),
                  onPressed: _isSendingMessage ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isCurrentUser,
    required String text,
    String? imageUrl,
    required String time,
  }) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? const Color(0xFF77588D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                          color: isCurrentUser ? Colors.white : const Color(0xFF77588D),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

            // Text and timestamp
            Padding(
              padding: EdgeInsets.all(
                  text.isEmpty && imageUrl != null ? 8 : 12
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (text.isNotEmpty)
                    Text(
                      text,
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markMessagesAsRead(List<QueryDocumentSnapshot> messages) async {
    try {
      // Find unread messages sent by the other user
      final batch = _firestore.batch();
      bool needsUpdate = false;

      for (var message in messages) {
        Map<String, dynamic> messageData = message.data() as Map<String, dynamic>;

        if (messageData['senderId'] == widget.receiverId &&
            messageData['read'] == false) {
          // Mark as read
          batch.update(message.reference, {'read': true});
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        await batch.commit();
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (messageDate == today) {
      return timeStr;
    } else if (messageDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, $timeStr';
    }
  }
}