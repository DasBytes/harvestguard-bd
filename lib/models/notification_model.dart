import 'package:flutter/material.dart';

enum NotificationPriority { critical, high, medium, low }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationPriority priority;
  final bool isRead;
  final String actionRequired;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.priority,
    required this.isRead,
    required this.actionRequired,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationPriority? priority,
    bool? isRead,
    String? actionRequired,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      actionRequired: actionRequired ?? this.actionRequired,
    );
  }

  Color getPriorityColor() {
    switch (priority) {
      case NotificationPriority.critical:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.medium:
        return Colors.yellow.shade700;
      case NotificationPriority.low:
        return Colors.green;
    }
  }

  IconData getPriorityIcon() {
    switch (priority) {
      case NotificationPriority.critical:
        return Icons.error;
      case NotificationPriority.high:
        return Icons.warning;
      case NotificationPriority.medium:
        return Icons.info;
      case NotificationPriority.low:
        return Icons.check_circle;
    }
  }
}
