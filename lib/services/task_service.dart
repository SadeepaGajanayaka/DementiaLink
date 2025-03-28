// lib/services/task_service.dart - updated to include notification scheduling
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/task_model.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class TaskService {
  // Base URL of your API
  static const String baseUrl = 'http://10.0.2.2:5000/api/tasks'; // For Android emulator
  // static const String baseUrl = 'http://localhost:5000/api/tasks'; // For iOS simulator
  // static const String baseUrl = 'https://your-production-api.com/api/tasks'; // For production

  // Device ID
  static String? _deviceId;
  static String? _fcmToken;
  static bool _isInitialized = false;

  // Initialize the task service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print("TaskService: Initializing...");

      // Initialize Firebase (with fallback mode)
      await FirebaseService.initialize();

      // Initialize notification service
      await NotificationService.instance.initialize();
      await NotificationService.instance.requestPermissions();

      // Get device ID
      await _getDeviceId();

      // Try to get FCM token (may be null in fallback mode)
      _fcmToken = await FirebaseService.getFCMToken();

      print("TaskService: Initialization complete");
      print("TaskService: Device ID: $_deviceId");
      print("TaskService: FCM Token: ${_fcmToken != null ? 'Available' : 'Not available'}");

      if (_deviceId != null && _fcmToken != null) {
        try {
          await updateFcmToken();
        } catch (e) {
          print("TaskService: Failed to update FCM token: $e");
          // This is not critical, continue anyway
        }
      }

      _isInitialized = true;
    } catch (e) {
      print("TaskService: Error during initialization: $e");
      // Still mark as initialized to prevent repeated init attempts
      _isInitialized = true;
      rethrow;
    }
  }

  // Get or generate device ID
  static Future<void> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_id');

      if (_deviceId == null) {
        // Generate a new device ID
        final deviceInfo = DeviceInfoPlugin();
        String? id;

        // Check platform without using BuildContext
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          id = androidInfo.id;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          id = iosInfo.identifierForVendor;
        }

        _deviceId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
        await prefs.setString('device_id', _deviceId!);
      }
    } catch (e) {
      print("TaskService: Error getting device ID: $e");
      // Create a fallback ID in case of error
      _deviceId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Update FCM token on the server
  static Future<void> updateFcmToken() async {
    if (_deviceId == null || _fcmToken == null) return;

    try {
      await http.put(
        Uri.parse('$baseUrl/device/$_deviceId/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fcmToken': _fcmToken}),
      );
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }

  // Get all tasks for the current device
  static Future<List<Task>> getAllTasks() async {
    if (!_isInitialized) await initialize();
    if (_deviceId == null) await _getDeviceId();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/device/$_deviceId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = json.decode(response.body);
        final tasks = tasksJson.map((json) => _convertJsonToTask(json)).toList();

        // Schedule notifications for all active tasks
        _scheduleNotificationsForTasks(tasks);

        return tasks;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error getting all tasks: $e');
      return [];
    }
  }

  // Get tasks for a specific date
  static Future<List<Task>> getTasksByDate(DateTime date) async {
    if (!_isInitialized) await initialize();
    if (_deviceId == null) await _getDeviceId();

    try {
      final formattedDate = date.toIso8601String().split('T')[0];
      final url = '$baseUrl/device/$_deviceId/date/$formattedDate';

      print("TaskService: Fetching tasks by date from URL: $url");

      final response = await http.get(
        Uri.parse(url),
      );

      print("TaskService: Tasks by date response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> tasksJson = json.decode(response.body);
        print("TaskService: Retrieved ${tasksJson.length} tasks for date $formattedDate");
        final tasks = tasksJson.map((json) => _convertJsonToTask(json)).toList();

        // Schedule notifications for the tasks of this day
        _scheduleNotificationsForTasks(tasks);

        return tasks;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error getting tasks by date: $e');
      return [];
    }
  }

  // Create a new task
  static Future<Task?> createTask(Task task) async {
    if (!_isInitialized) await initialize();
    if (_deviceId == null) await _getDeviceId();

    try {
      print("TaskService: Creating new task: ${task.title}");

      // Create task data object
      final Map<String, dynamic> taskData = {
        ..._convertTaskToJson(task),
        'deviceId': _deviceId,
      };

      // Add FCM token if available
      if (_fcmToken != null) {
        taskData['fcmToken'] = _fcmToken;
      }

      print("TaskService: Sending task data to backend");
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(taskData),
      );

      print("TaskService: Create task response: ${response.statusCode}");

      if (response.statusCode == 201) {
        print("TaskService: Task created successfully");
        final createdTask = _convertJsonToTask(json.decode(response.body));

        // Schedule notification for the new task
        if (!createdTask.isCompleted) {
          await NotificationService.instance.scheduleTaskReminder(createdTask);
        }

        return createdTask;
      } else {
        print("TaskService: Failed to create task: ${response.body}");
        throw Exception('Failed to create task');
      }
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  // Update an existing task
  static Future<Task?> updateTask(Task task) async {
    if (task.id == null) return null;

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_convertTaskToJson(task)),
      );

      if (response.statusCode == 200) {
        final updatedTask = _convertJsonToTask(json.decode(response.body));

        // Cancel previous notifications and schedule new ones if task is not completed
        if (updatedTask.isCompleted) {
          await NotificationService.instance.cancelTaskReminders(updatedTask.id!);
        } else {
          await NotificationService.instance.scheduleTaskReminder(updatedTask);
        }

        return updatedTask;
      } else {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      print('Error updating task: $e');
      return null;
    }
  }

  // Mark a task as completed
  static Future<Task?> completeTask(String taskId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$taskId/complete'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final completedTask = _convertJsonToTask(json.decode(response.body));

        // Cancel notifications for completed task
        await NotificationService.instance.cancelTaskReminders(taskId);

        return completedTask;
      } else {
        throw Exception('Failed to complete task');
      }
    } catch (e) {
      print('Error completing task: $e');
      return null;
    }
  }

  // Delete a task
  static Future<bool> deleteTask(String taskId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$taskId'),
      );

      if (response.statusCode == 200) {
        // Cancel notifications for deleted task
        await NotificationService.instance.cancelTaskReminders(taskId);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  // Helper method to schedule notifications for a list of tasks
  static Future<void> _scheduleNotificationsForTasks(List<Task> tasks) async {
    for (final task in tasks) {
      if (!task.isCompleted && task.id != null) {
        // Only schedule for future tasks
        final taskDateTime = DateTime(
          task.date.year,
          task.date.month,
          task.date.day,
          task.startTime.hour,
          task.startTime.minute,
        );

        // Parse the remind before string to get the notification time
        Duration reminderOffset;
        switch (task.remindBefore) {
          case '5 minutes early':
            reminderOffset = Duration(minutes: 5);
            break;
          case '10 minutes early':
            reminderOffset = Duration(minutes: 10);
            break;
          case '15 minutes early':
            reminderOffset = Duration(minutes: 15);
            break;
          case '30 minutes early':
            reminderOffset = Duration(minutes: 30);
            break;
          default:
            reminderOffset = Duration(minutes: 10);
        }

        final reminderTime = taskDateTime.subtract(reminderOffset);

        // Only schedule if the reminder time is in the future
        if (reminderTime.isAfter(DateTime.now())) {
          await NotificationService.instance.scheduleTaskReminder(task);
        }
      }
    }
  }

  // Convert JSON from API to Task model
  static Task _convertJsonToTask(Map<String, dynamic> json) {
    return Task(
      id: json['_id'],
      title: json['title'],
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
      startTime: TimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: TimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      priority: _getPriorityFromString(json['priority']),
      remindBefore: json['remindBefore'],
      repeat: json['repeat'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  // Convert Task model to JSON for API
  static Map<String, dynamic> _convertTaskToJson(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'date': task.date.toIso8601String(),
      'startTime': {
        'hour': task.startTime.hour,
        'minute': task.startTime.minute,
      },
      'endTime': {
        'hour': task.endTime.hour,
        'minute': task.endTime.minute,
      },
      'priority': _getPriorityString(task.priority),
      'remindBefore': task.remindBefore,
      'repeat': task.repeat,
      'isCompleted': task.isCompleted,
    };
  }

  // Convert priority string to enum
  static Priority _getPriorityFromString(String priorityString) {
    switch (priorityString) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        return Priority.medium;
    }
  }

  // Convert priority enum to string
  static String _getPriorityString(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'low';
      case Priority.medium:
        return 'medium';
      case Priority.high:
        return 'high';
      default:
        return 'medium';
    }
  }
}