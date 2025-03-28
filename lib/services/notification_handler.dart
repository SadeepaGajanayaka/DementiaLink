// lib/services/notification_handler.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import '../models/task_model.dart';
import 'task_service.dart';

class NotificationHandler {
  // Singleton instance
  static final NotificationHandler _instance = NotificationHandler._internal();
  static NotificationHandler get instance => _instance;

  // Stream controller for handling notification clicks
  final BehaviorSubject<String?> _onNotificationClick = BehaviorSubject<String?>();

  // Stream of notification clicks that can be listened to
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  // Constructor
  NotificationHandler._internal();

  // Handle when notification is clicked
  void handleNotificationClick(String? taskId) {
    if (taskId != null && taskId.isNotEmpty) {
      _onNotificationClick.add(taskId);
    }
  }

  // Get task from notification payload
  Future<Task?> getTaskFromNotification(String taskId) async {
    try {
      // Get all tasks
      final tasks = await TaskService.getAllTasks();

      // Find the task with matching ID
      return tasks.firstWhere(
            (task) => task.id == taskId,
        orElse: () => throw Exception('Task not found'),
      );
    } catch (e) {
      print('Error getting task from notification: $e');
      return null;
    }
  }

  // Navigate to task detail screen when notification is tapped
  void setupNotificationClickListener(GlobalKey<NavigatorState> navigatorKey) {
    onNotificationClick.listen((String? taskId) async {
      if (taskId == null) return;

      try {
        // Get the task
        final task = await getTaskFromNotification(taskId);

        if (task != null && navigatorKey.currentState != null) {
          // Navigate to task detail screen or show task options
          print('Notification tapped for task: ${task.title}');

          // You can navigate to a task detail screen here
          // navigatorKey.currentState!.push(
          //   MaterialPageRoute(
          //     builder: (context) => TaskDetailScreen(task: task),
          //   ),
          // );

          // Or show a dialog with task options
          // showDialog(
          //   context: navigatorKey.currentContext!,
          //   builder: (context) => AlertDialog(
          //     title: Text(task.title),
          //     content: Text(task.description),
          //     actions: [
          //       TextButton(
          //         onPressed: () => Navigator.pop(context),
          //         child: Text('Close'),
          //       ),
          //       TextButton(
          //         onPressed: () {
          //           // Mark task as complete
          //           TaskService.completeTask(taskId);
          //           Navigator.pop(context);
          //         },
          //         child: Text('Complete'),
          //       ),
          //     ],
          //   ),
          // );
        }
      } catch (e) {
        print('Error handling notification click: $e');
      }
    });
  }

  // Dispose the stream controller
  void dispose() {
    _onNotificationClick.close();
  }
}