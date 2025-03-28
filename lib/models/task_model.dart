import 'package:flutter/material.dart';

enum Priority { low, medium, high }

class Task {

  String? id;
  String title;
  String description;
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  Priority priority;
  String remindBefore;
  String repeat;
  bool isCompleted =false;

  Task({
    this.id,  // Add this line
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.priority,
    required this.remindBefore,
    required this.repeat,
    this.isCompleted = false,
  });
}