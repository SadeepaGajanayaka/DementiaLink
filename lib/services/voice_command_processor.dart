// // import 'package:flutter/material.dart';
// // import '../models/task_model.dart';
// //
// // enum CommandType {
// //   search,
// //   create,
// //   complete,
// //   filter,
// //   unknown
// // }
// //
// // class VoiceCommand {
// //   final CommandType type;
// //   final Map<String, dynamic> parameters;
// //
// //   VoiceCommand({
// //     required this.type,
// //     required this.parameters,
// //   });
// // }
// //
// // class VoiceCommandProcessor {
// //   // Process the spoken text into a command object
// //   static VoiceCommand processCommand(String text) {
// //     final lowerText = text.toLowerCase();
// //
// //     // Check for search commands
// //     if (lowerText.contains('search') ||
// //         lowerText.contains('find') ||
// //         lowerText.contains('look for')) {
// //       return VoiceCommand(
// //         type: CommandType.search,
// //         parameters: {'query': _extractSearchQuery(lowerText)},
// //       );
// //     }
// //
// //     // Check for priority filter commands
// //     if (lowerText.contains('priority') ||
// //         lowerText.contains('important')) {
// //
// //       if (lowerText.contains('high')) {
// //         return VoiceCommand(
// //           type: CommandType.filter,
// //           parameters: {'priority': Priority.high},
// //         );
// //       } else if (lowerText.contains('medium')) {
// //         return VoiceCommand(
// //           type: CommandType.filter,
// //           parameters: {'priority': Priority.medium},
// //         );
// //       } else if (lowerText.contains('low')) {
// //         return VoiceCommand(
// //           type: CommandType.filter,
// //           parameters: {'priority': Priority.low},
// //         );
// //       }
// //     }
// //
// //     // Check for date filter commands
// //     if (lowerText.contains('today') ||
// //         lowerText.contains('tomorrow') ||
// //         lowerText.contains('this week')) {
// //       return VoiceCommand(
// //         type: CommandType.filter,
// //         parameters: {'date': _extractDateFilter(lowerText)},
// //       );
// //     }
// //
// //     // Check for task creation commands
// //     if (lowerText.contains('create') ||
// //         lowerText.contains('add') ||
// //         lowerText.contains('new task')) {
// //       return VoiceCommand(
// //         type: CommandType.create,
// //         parameters: {'taskDetails': lowerText},
// //       );
// //     }
// //
// //     // Check for task completion commands
// //     if (lowerText.contains('complete') ||
// //         lowerText.contains('finish') ||
// //         lowerText.contains('mark as done')) {
// //       return VoiceCommand(
// //         type: CommandType.complete,
// //         parameters: {'taskName': _extractTaskName(lowerText)},
// //       );
// //     }
// //
// //     // If no known command pattern is found, default to search
// //     return VoiceCommand(
// //       type: CommandType.search,
// //       parameters: {'query': text},
// //     );
// //   }
// //
// //   // Extract the search query from the command
// //   static String _extractSearchQuery(String text) {
// //     final searchKeywords = ['search', 'find', 'look for', 'show me'];
// //
// //     for (final keyword in searchKeywords) {
// //       if (text.contains(keyword)) {
// //         // Get everything after the keyword
// //         final parts = text.split(keyword);
// //         if (parts.length > 1) {
// //           return parts[1].trim();
// //         }
// //       }
// //     }
// //
// //     // If no keyword is found, use the whole text
// //     return text.trim();
// //   }
// //
// //   // Extract task name from completion commands
// //   static String _extractTaskName(String text) {
// //     final completionKeywords = ['complete', 'finish', 'mark as done', 'mark done'];
// //
// //     for (final keyword in completionKeywords) {
// //       if (text.contains(keyword)) {
// //         // Get everything after the keyword
// //         final parts = text.split(keyword);
// //         if (parts.length > 1) {
// //           return parts[1].trim();
// //         }
// //       }
// //     }
// //
// //     // If no keyword is found, use the whole text
// //     return text.trim();
// //   }
// //
// //   // Extract date filter from the command
// //   static DateTime _extractDateFilter(String text) {
// //     final now = DateTime.now();
// //
// //     if (text.contains('tomorrow')) {
// //       return DateTime(now.year, now.month, now.day + 1);
// //     } else if (text.contains('this week')) {
// //       // Return the current date as a starting point
// //       return now;
// //     } else {
// //       // Default to today
// //       return now;
// //     }
// //   }
// //
// //   // Find a task that best matches the provided name
// //   static Task? findMatchingTask(List<Task> tasks, String taskName) {
// //     if (tasks.isEmpty || taskName.isEmpty) {
// //       return null;
// //     }
// //
// //     // Try to find an exact match first
// //     for (final task in tasks) {
// //       if (task.title.toLowerCase() == taskName.toLowerCase()) {
// //         return task;
// //       }
// //     }
// //
// //     // If no exact match, find the closest match
// //     Task? bestMatch;
// //     int highestMatchScore = 0;
// //
// //     for (final task in tasks) {
// //       final score = _calculateMatchScore(task.title.toLowerCase(), taskName.toLowerCase());
// //       if (score > highestMatchScore) {
// //         highestMatchScore = score;
// //         bestMatch = task;
// //       }
// //     }
// //
// //     // Only return a match if it's reasonably close
// //     return highestMatchScore > taskName.length ~/ 2 ? bestMatch : null;
// //   }
// //
// //   // Calculate a simple similarity score between two strings
// //   static int _calculateMatchScore(String s1, String s2) {
// //     int score = 0;
// //     for (int i = 0; i < s2.length; i++) {
// //       if (i < s1.length && s1[i] == s2[i]) {
// //         score++;
// //       }
// //     }
// //     return score;
// //   }
// // }
//
// import 'package:flutter/material.dart';
// import '../models/task_model.dart';
//
// enum CommandType {
//   search,
//   create,
//   complete,
//   filter,
//   unknown
// }
//
// class VoiceCommand {
//   final CommandType type;
//   final Map<String, dynamic> parameters;
//
//   VoiceCommand({
//     required this.type,
//     required this.parameters,
//   });
// }
//
// class VoiceCommandProcessor {
//   // The existing implementation remains the same
//   static VoiceCommand processCommand(String text) {
//     final lowerText = text.toLowerCase();
//
//     // Check for search commands
//     if (lowerText.contains('search') ||
//         lowerText.contains('find') ||
//         lowerText.contains('look for')) {
//       return VoiceCommand(
//         type: CommandType.search,
//         parameters: {'query': _extractSearchQuery(lowerText)},
//       );
//     }
//
//     // Check for priority filter commands
//     if (lowerText.contains('priority') ||
//         lowerText.contains('important')) {
//
//       if (lowerText.contains('high')) {
//         return VoiceCommand(
//           type: CommandType.filter,
//           parameters: {'priority': Priority.high},
//         );
//       } else if (lowerText.contains('medium')) {
//         return VoiceCommand(
//           type: CommandType.filter,
//           parameters: {'priority': Priority.medium},
//         );
//       } else if (lowerText.contains('low')) {
//         return VoiceCommand(
//           type: CommandType.filter,
//           parameters: {'priority': Priority.low},
//         );
//       }
//     }
//
//     // Check for date filter commands
//     if (lowerText.contains('today') ||
//         lowerText.contains('tomorrow') ||
//         lowerText.contains('this week')) {
//       return VoiceCommand(
//         type: CommandType.filter,
//         parameters: {'date': _extractDateFilter(lowerText)},
//       );
//     }
//
//     // Check for task creation commands
//     if (lowerText.contains('create') ||
//         lowerText.contains('add') ||
//         lowerText.contains('new task')) {
//       return VoiceCommand(
//         type: CommandType.create,
//         parameters: {'taskDetails': lowerText},
//       );
//     }
//
//     // Check for task completion commands
//     if (lowerText.contains('complete') ||
//         lowerText.contains('finish') ||
//         lowerText.contains('mark as done')) {
//       return VoiceCommand(
//         type: CommandType.complete,
//         parameters: {'taskName': _extractTaskName(lowerText)},
//       );
//     }
//
//     // If no known command pattern is found, default to search
//     return VoiceCommand(
//       type: CommandType.search,
//       parameters: {'query': text},
//     );
//   }
//
//   // Existing helper methods remain the same
//   static String _extractSearchQuery(String text) {
//     final searchKeywords = ['search', 'find', 'look for', 'show me'];
//
//     for (final keyword in searchKeywords) {
//       if (text.contains(keyword)) {
//         final parts = text.split(keyword);
//         if (parts.length > 1) {
//           return parts[1].trim();
//         }
//       }
//     }
//
//     return text.trim();
//   }
//
//   static String _extractTaskName(String text) {
//     final completionKeywords = ['complete', 'finish', 'mark as done', 'mark done'];
//
//     for (final keyword in completionKeywords) {
//       if (text.contains(keyword)) {
//         final parts = text.split(keyword);
//         if (parts.length > 1) {
//           return parts[1].trim();
//         }
//       }
//     }
//
//     return text.trim();
//   }
//
//   static DateTime _extractDateFilter(String text) {
//     final now = DateTime.now();
//
//     if (text.contains('tomorrow')) {
//       return DateTime(now.year, now.month, now.day + 1);
//     } else if (text.contains('this week')) {
//       return now;
//     } else {
//       return now;
//     }
//   }
//
//   static Task? findMatchingTask(List<Task> tasks, String taskName) {
//     if (tasks.isEmpty || taskName.isEmpty) {
//       return null;
//     }
//
//     // Try to find an exact match first
//     for (final task in tasks) {
//       if (task.title.toLowerCase() == taskName.toLowerCase()) {
//         return task;
//       }
//     }
//
//     // If no exact match, find the closest match
//     Task? bestMatch;
//     int highestMatchScore = 0;
//
//     for (final task in tasks) {
//       final score = _calculateMatchScore(task.title.toLowerCase(), taskName.toLowerCase());
//       if (score > highestMatchScore) {
//         highestMatchScore = score;
//         bestMatch = task;
//       }
//     }
//
//     // Only return a match if it's reasonably close
//     return highestMatchScore > taskName.length ~/ 2 ? bestMatch : null;
//   }
//
//   static int _calculateMatchScore(String s1, String s2) {
//     int score = 0;
//     for (int i = 0; i < s2.length; i++) {
//       if (i < s1.length && s1[i] == s2[i]) {
//         score++;
//       }
//     }
//     return score;
//   }
// }

import 'package:flutter/material.dart';
import '../models/task_model.dart';

enum CommandType {
  search,
  create,
  complete,
  filter,
  unknown
}

class VoiceCommand {
  final CommandType type;
  final Map<String, dynamic> parameters;

  VoiceCommand({
    required this.type,
    required this.parameters,
  });
}

class VoiceCommandProcessor {
  // Process the spoken text into a command object
  static VoiceCommand processCommand(String text) {
    final lowerText = text.toLowerCase();

    // Check for search commands
    if (lowerText.contains('search') ||
        lowerText.contains('find') ||
        lowerText.contains('look for')) {
      return VoiceCommand(
        type: CommandType.search,
        parameters: {'query': _extractSearchQuery(lowerText)},
      );
    }

    // Check for task creation commands
    if (lowerText.contains('create') ||
        lowerText.contains('add') ||
        lowerText.contains('new task')) {
      return VoiceCommand(
        type: CommandType.create,
        parameters: {'taskDetails': text},
      );
    }

    // Check for priority filter commands
    if (lowerText.contains('priority') ||
        lowerText.contains('important')) {

      if (lowerText.contains('high')) {
        return VoiceCommand(
          type: CommandType.filter,
          parameters: {'priority': Priority.high},
        );
      } else if (lowerText.contains('medium')) {
        return VoiceCommand(
          type: CommandType.filter,
          parameters: {'priority': Priority.medium},
        );
      } else if (lowerText.contains('low')) {
        return VoiceCommand(
          type: CommandType.filter,
          parameters: {'priority': Priority.low},
        );
      }
    }

    // Check for date filter commands
    if (lowerText.contains('today') ||
        lowerText.contains('tomorrow') ||
        lowerText.contains('this week')) {
      return VoiceCommand(
        type: CommandType.filter,
        parameters: {'date': _extractDateFilter(lowerText)},
      );
    }

    // Check for task completion commands
    if (lowerText.contains('complete') ||
        lowerText.contains('finish') ||
        lowerText.contains('mark as done')) {
      return VoiceCommand(
        type: CommandType.complete,
        parameters: {'taskName': _extractTaskName(lowerText)},
      );
    }

    // If no known command pattern is found, default to search
    return VoiceCommand(
      type: CommandType.search,
      parameters: {'query': text},
    );
  }

  // Extract the search query from the command
  static String _extractSearchQuery(String text) {
    final searchKeywords = ['search', 'find', 'look for', 'show me'];

    for (final keyword in searchKeywords) {
      if (text.contains(keyword)) {
        // Get everything after the keyword
        final parts = text.split(keyword);
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }
    }

    // If no keyword is found, use the whole text
    return text.trim();
  }

  // Extract task name from completion commands
  static String _extractTaskName(String text) {
    final completionKeywords = ['complete', 'finish', 'mark as done', 'mark done'];

    for (final keyword in completionKeywords) {
      if (text.contains(keyword)) {
        // Get everything after the keyword
        final parts = text.split(keyword);
        if (parts.length > 1) {
          return parts[1].trim();
        }
      }
    }

    // If no keyword is found, use the whole text
    return text.trim();
  }

  // Extract date filter from the command
  static DateTime _extractDateFilter(String text) {
    final now = DateTime.now();

    if (text.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1);
    } else if (text.contains('this week')) {
      // Return the current date as a starting point
      return now;
    } else {
      // Default to today
      return now;
    }
  }

  // Find a task that best matches the provided name
  static Task? findMatchingTask(List<Task> tasks, String taskName) {
    if (tasks.isEmpty || taskName.isEmpty) {
      return null;
    }

    // Try to find an exact match first
    for (final task in tasks) {
      if (task.title.toLowerCase() == taskName.toLowerCase()) {
        return task;
      }
    }

    // If no exact match, find the closest match
    Task? bestMatch;
    int highestMatchScore = 0;

    for (final task in tasks) {
      final score = _calculateMatchScore(task.title.toLowerCase(), taskName.toLowerCase());
      if (score > highestMatchScore) {
        highestMatchScore = score;
        bestMatch = task;
      }
    }

    // Only return a match if it's reasonably close
    return highestMatchScore > taskName.length ~/ 2 ? bestMatch : null;
  }

  // Calculate a simple similarity score between two strings
  static int _calculateMatchScore(String s1, String s2) {
    int score = 0;
    for (int i = 0; i < s2.length; i++) {
      if (i < s1.length && s1[i] == s2[i]) {
        score++;
      }
    }
    return score;
  }
}