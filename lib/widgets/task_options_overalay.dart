import 'package:flutter/material.dart';

class TaskOptionsOverlay extends StatelessWidget {
  final VoidCallback onEditTask;
  final VoidCallback onTaskCompleted;
  final VoidCallback onDeleteTask;

  const TaskOptionsOverlay({
    Key? key,
    required this.onEditTask,
    required this.onTaskCompleted,
    required this.onDeleteTask,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            _buildActionButton(
              label: 'Edit Task',
              onPressed: onEditTask,
              backgroundColor: const Color(0xFF77588D),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'Task Completed',
              onPressed: onTaskCompleted,
              backgroundColor: const Color(0xFF77588D),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              label: 'Delete Task',
              onPressed: onDeleteTask,
              backgroundColor: const Color(0xFF77588D),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}