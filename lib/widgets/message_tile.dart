import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class MessageTile extends StatelessWidget {
  final Message message;
  final bool isOutgoing;
  final bool isLastMessage;

  const MessageTile({
    super.key,
    required this.message,
    required this.isOutgoing,
    this.isLastMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isOutgoing ? const Color(0xFF503663) : Colors.grey[300],
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText.rich(
                TextSpan(
                  children: _buildFormattedText(message.message),
                  style: TextStyle(
                    color: isOutgoing ? Colors.white : Colors.black,
                    fontSize: 16.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(message.createdAt),
                style: TextStyle(
                  color: isOutgoing ? Colors.white70 : Colors.black54,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\\(.?)\\*');
    int currentPosition = 0;

    // Find all bold text matches
    for (Match match in boldPattern.allMatches(text)) {
      // Add text before the bold part
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
        ));
      }

      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1), // The text between ** **
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));

      currentPosition = match.end;
    }

    // Add any remaining text after the last bold part
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
      ));
    }

    return spans;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}