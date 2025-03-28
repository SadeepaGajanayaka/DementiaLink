// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/task_model.dart' as task_models;
import 'notification_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Add sound configurations
  final String _defaultSoundAndroid = 'task_alarm';
  final String _defaultSoundIOS = 'task_alarm.aiff';

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz_data.initializeTimeZones();

    // Initialize notification settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize notification settings for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // For iOS 10 and above, this callback won't be fired
      },
    );

    // Combine platform-specific settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
    print('NotificationService: Initialized successfully');
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      // High priority channel for reminders with sound
      const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
        'reminders_channel',
        'Task Reminders',
        description: 'Notifications for upcoming tasks',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        sound: RawResourceAndroidNotificationSound('task_alarm'), // Reference to sound file in raw folder
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(remindersChannel);

      print('NotificationService: Created Android notification channels');
    }
  }

  // Handle notification click
  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('NotificationService: Notification clicked: ${response.payload}');

    // Parse the payload - it contains the task ID
    final String? taskId = response.payload;
    if (taskId != null && taskId.isNotEmpty) {
      // Use notification handler to process the click
      NotificationHandler.instance.handleNotificationClick(taskId);
      print('NotificationService: Sent task ID to notification handler');
    }
  }

  // Request notification permissions (especially important for iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final bool? result = await androidPlugin?.requestPermission();
      return result ?? false;
    }
    return false;
  }

  // Schedule a notification for a task
  Future<void> scheduleTaskReminder(task_models.Task task) async {
    if (!_isInitialized) await initialize();

    // Delete any existing notifications for this task (in case of rescheduling)
    if (task.id != null) {
      await cancelTaskReminders(task.id!);
    }

    // Skip scheduling if task is already completed
    if (task.isCompleted) return;

    // Determine when to send the notification based on task.remindBefore
    final DateTime taskDateTime = _combineDateTime(task.date, task.startTime);
    final Duration reminderOffset = _parseRemindBeforeString(task.remindBefore);
    final DateTime reminderTime = taskDateTime.subtract(reminderOffset);

    // Don't schedule if the reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      print('NotificationService: Reminder time is in the past, not scheduling');
      return;
    }

    // Create unique notification ID from task ID or other properties
    final int notificationId = task.id?.hashCode ?? task.title.hashCode;

    // Set up notification details with sound
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_defaultSoundAndroid),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      enableLights: true,
      color: const Color(0xFF503663),
      ledColor: const Color(0xFF503663),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _defaultSoundIOS,  // iOS sound file in the app bundle
      interruptionLevel: InterruptionLevel.active, // Makes sound play even in silent mode
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Create priority string for notification
    String priorityStr = '';
    switch (task.priority) {
      case task_models.Priority.high:
        priorityStr = 'High Priority';
        break;
      case task_models.Priority.medium:
        priorityStr = 'Medium Priority';
        break;
      case task_models.Priority.low:
        priorityStr = 'Low Priority';
        break;
    }

    // Format start time for the notification
    final String formattedTime = _formatTimeOfDay(task.startTime);
    final String formattedDate = _isSameDay(task.date, DateTime.now())
        ? 'Today'
        : '${task.date.day}/${task.date.month}/${task.date.year}';

    // Schedule the notification with detailed information
    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      'Task Reminder: ${task.title}',
      '${task.description}\n$priorityStr • $formattedDate at $formattedTime',
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      payload: task.id,
    );

    print('NotificationService: Scheduled reminder with sound for task ${task.title} at ${reminderTime.toString()}');

    // If task repeats, schedule for future occurrences
    if (task.repeat != 'None') {
      _scheduleRepeatingTask(task);
    }
  }

  // Helper method to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Schedule repeating notifications based on the repeat type
  Future<void> _scheduleRepeatingTask(task_models.Task task) async {
    // Implementation for repeating tasks
    if (task.id == null) return;

    String repeatType = task.repeat;
    DateTime baseDate = task.date;
    TimeOfDay baseTime = task.startTime;

    // Schedule for the next occurrence based on repeat type
    DateTime nextDate;
    switch (repeatType) {
      case 'Daily':
        nextDate = baseDate.add(Duration(days: 1));
        break;
      case 'Weekly':
        nextDate = baseDate.add(Duration(days: 7));
        break;
      case 'Monthly':
      // Add 1 month
        nextDate = DateTime(baseDate.year, baseDate.month + 1, baseDate.day);
        break;
      default:
        return; // No repeat
    }

    // Create a new task with the new date but same other properties
    task_models.Task nextTask = task_models.Task(
      id: task.id,
      title: task.title,
      description: task.description,
      date: nextDate,
      startTime: baseTime,
      endTime: task.endTime,
      priority: task.priority,
      remindBefore: task.remindBefore,
      repeat: task.repeat,
      isCompleted: false,
    );

    // Schedule this new occurrence
    await scheduleTaskReminder(nextTask);
  }

  // Cancel all notifications for a task
  Future<void> cancelTaskReminders(String taskId) async {
    final int notificationId = taskId.hashCode;
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    print('NotificationService: Cancelled reminders for task $taskId');
  }

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('NotificationService: Cancelled all notifications');
  }

  // Show an immediate notification (useful for testing)
  Future<void> showImmediateNotification(String title, String body, {String? payload}) async {
    if (!_isInitialized) await initialize();

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(_defaultSoundAndroid),
      ticker: 'Task reminder',
      enableLights: true,
      color: const Color(0xFF503663),
      ledColor: const Color(0xFF503663),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _defaultSoundIOS,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    print('NotificationService: Showed immediate notification with sound');
  }

  // Utility: Combine date and time into a single DateTime
  DateTime _combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // Utility: Format TimeOfDay for display
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // Utility: Parse remind before string to Duration
  Duration _parseRemindBeforeString(String remindBefore) {
    switch (remindBefore) {
      case '5 minutes early':
        return Duration(minutes: 5);
      case '10 minutes early':
        return Duration(minutes: 10);
      case '15 minutes early':
        return Duration(minutes: 15);
      case '30 minutes early':
        return Duration(minutes: 30);
      default:
        return Duration(minutes: 10); // Default
    }
  }
}