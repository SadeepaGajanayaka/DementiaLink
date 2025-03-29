import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Formatters {
  /// Format a DateTime to display in the app
  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  /// Format a TimeOfDay to display in the app
  static String formatTimeOfDay(TimeOfDay timeOfDay) {
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour.$minute$period';
  }

  /// Get the month abbreviation (SEP, OCT, etc.)
  static String getMonthAbbreviation(DateTime date) {
    return DateFormat('MMM').format(date).toUpperCase();
  }

  /// Get the day of week abbreviation (MON, TUE, etc.)
  static String getDayAbbreviation(DateTime date) {
    return DateFormat('E').format(date).toUpperCase();
  }
}