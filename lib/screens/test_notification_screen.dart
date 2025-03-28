// lib/screens/test_notification_screen.dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';

class TestNotificationScreen extends StatefulWidget {
  @override
  _TestNotificationScreenState createState() => _TestNotificationScreenState();
}

class _TestNotificationScreenState extends State<TestNotificationScreen> {
  final TextEditingController _titleController = TextEditingController(text: 'Test Notification');
  final TextEditingController _bodyController = TextEditingController(text: 'This is a test notification');
  final TextEditingController _delayController = TextEditingController(text: '5');

  // Added priority selection
  Priority _selectedPriority = Priority.medium;

  // For simulating a real task
  bool _simulateFullTask = true;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  Future<void> _sendImmediateNotification() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Test Notification';

    final body = _bodyController.text.trim().isNotEmpty
        ? _bodyController.text.trim()
        : 'This is a test notification';

    try {
      await NotificationService.instance.showImmediateNotification(
        title,
        body,
        payload: 'test_notification',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification sent successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sendDelayedNotification() async {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Test Notification';

    final body = _bodyController.text.trim().isNotEmpty
        ? _bodyController.text.trim()
        : 'This is a test notification';

    final delaySeconds = int.tryParse(_delayController.text) ?? 5;

    try {
      if (_simulateFullTask) {
        // Create a real Task object for testing
        final now = DateTime.now();
        final scheduledTime = now.add(Duration(seconds: delaySeconds));

        final testTask = Task(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          description: body,
          date: now,
          startTime: TimeOfDay.fromDateTime(scheduledTime),
          endTime: TimeOfDay.fromDateTime(scheduledTime.add(Duration(hours: 1))),
          priority: _selectedPriority,
          remindBefore: '5 minutes early',
          repeat: 'None',
        );

        // Show feedback that notification is scheduled
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Full task notification scheduled for $delaySeconds seconds from now'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        // For testing, we'll simulate the reminder time being now + delay
        // Normally we'd calculate this from task time - remindBefore
        await Future.delayed(Duration(seconds: delaySeconds));

        await NotificationService.instance.scheduleTaskReminder(testTask);
      } else {
        // Simple delayed notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification scheduled for $delaySeconds seconds from now'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );

        await Future.delayed(Duration(seconds: delaySeconds));

        await NotificationService.instance.showImmediateNotification(
          title,
          body,
          payload: 'test_notification',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Simulate a task reminder that will trigger immediately
  Future<void> _testFullTaskReminder() async {
    try {
      final now = DateTime.now();
      // Make a task that should trigger immediately
      final testTask = Task(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : 'Important Task',
        description: _bodyController.text.trim().isNotEmpty ? _bodyController.text.trim() : 'This is an important task with a sound notification',
        date: now,
        startTime: TimeOfDay.fromDateTime(now.add(Duration(minutes: 1))),
        endTime: TimeOfDay.fromDateTime(now.add(Duration(hours: 1))),
        priority: _selectedPriority,
        remindBefore: '5 minutes early',
        repeat: 'None',
      );

      await NotificationService.instance.scheduleTaskReminder(testTask);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Task reminder scheduled and should appear immediately with sound'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule task reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Priority selection
  String _getPriorityString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      default:
        return 'Medium';
    }
  }

  // Priority color
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.orange;
      case Priority.high:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notifications'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Test Notification Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Notification Title',
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notification Body',
                  fillColor: Colors.white.withOpacity(0.1),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _delayController,
                      decoration: InputDecoration(
                        labelText: 'Delay (seconds)',
                        fillColor: Colors.white.withOpacity(0.1),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      style: TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<Priority>(
                      value: _selectedPriority,
                      dropdownColor: const Color(0xFF503663),
                      style: TextStyle(color: Colors.white),
                      underline: Container(),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                      onChanged: (Priority? newValue) {
                        setState(() {
                          if (newValue != null) {
                            _selectedPriority = newValue;
                          }
                        });
                      },
                      items: [
                        DropdownMenuItem<Priority>(
                          value: Priority.low,
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text('Low Priority'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<Priority>(
                          value: Priority.medium,
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.orange, size: 16),
                              SizedBox(width: 8),
                              Text('Medium Priority'),
                            ],
                          ),
                        ),
                        DropdownMenuItem<Priority>(
                          value: Priority.high,
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text('High Priority'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SwitchListTile(
                title: Text(
                  'Simulate Full Task',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  'Create a complete task object with all properties',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
                value: _simulateFullTask,
                activeColor: const Color(0xFF77588D),
                onChanged: (bool value) {
                  setState(() {
                    _simulateFullTask = value;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _sendImmediateNotification,
                icon: Icon(Icons.notifications_active),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF77588D),
                ),
                label: Text(
                  'Send Immediate Notification',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _sendDelayedNotification,
                icon: Icon(Icons.timer),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: const Color(0xFF77588D),
                ),
                label: Text(
                  'Send Delayed Notification',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _testFullTaskReminder,
                icon: Icon(Icons.alarm),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(16),
                  backgroundColor: Color(0xFFA64452),
                ),
                label: Text(
                  'Test Immediate Task Reminder with Sound',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 24),
              Card(
                color: Colors.white.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Notes:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• You must have sound files in your app to hear notification sounds.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      Text(
                        '• For Android: Make sure you have task_alarm.mp3 in android/app/src/main/res/raw/',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      Text(
                        '• For iOS: Make sure you have task_alarm.aiff in the app bundle.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      Text(
                        '• Ensure notification permissions are granted in device settings.',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}