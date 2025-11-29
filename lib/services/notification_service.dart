// ==================== notification_service.dart ====================
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _monitoringTimer;
  List<NotificationModel> _notifications = [];
  final _notificationController = StreamController<List<NotificationModel>>.broadcast();
  final String weatherApiKey = "efd7529b3243b1f612734dc3664e89e4";

  Stream<List<NotificationModel>> get notificationStream => _notificationController.stream;
  List<NotificationModel> get allNotifications => _notifications;

  // Start continuous monitoring
  void startMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      checkAndGenerateNotifications();
    });
    // Check immediately on start
    checkAndGenerateNotifications();
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
  }

  Future<void> checkAndGenerateNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch latest batch data
      final snapshot = await _firestore
          .collection('create_batches')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batchData = snapshot.docs.first.data();

      // Get real weather data
      final weatherData = await _getRealWeatherData();

      // Generate notifications based on conditions
      await _generateRealNotifications(batchData, weatherData);

      // Update stream
      _notificationController.add(_notifications);
    } catch (e) {
      print('Notification monitoring error: $e');
    }
  }

  Future<Map<String, dynamic>> _getRealWeatherData() async {
    try {
      final double lat = 23.8103;
      final double lon = 90.4125;

      final url =
          "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final currentWeather = data["list"][0];
        final forecast = data["list"].take(5).toList();

        // Calculate max rain chance in next 3 days
        double maxRain = 0;
        for (var day in forecast.take(3)) {
          double rain = ((day["pop"] ?? 0) * 100);
          if (rain > maxRain) maxRain = rain;
        }

        return {
          'temp': (currentWeather["main"]["temp"] ?? 0).toDouble(),
          'humidity': (currentWeather["main"]["humidity"] ?? 0).toDouble(),
          'rain': maxRain,
          'description': currentWeather["weather"][0]["description"] ?? "হালকা মেঘ",
        };
      }
    } catch (e) {
      print('Weather API error: $e');
    }

    // Fallback data
    return {
      'temp': 30.0,
      'humidity': 75.0,
      'rain': 40.0,
      'description': 'হালকা মেঘ',
    };
  }

  Future<void> _generateRealNotifications(
      Map<String, dynamic> batchData, Map<String, dynamic> weatherData) async {
    
    final crop = batchData['cropNameBn'] ?? '';
    final storage = batchData['storageType'] ?? '';
    final weight = batchData['quantityKg'] ?? 0;

    final temp = weatherData['temp'] ?? 0.0;
    final humidity = weatherData['humidity'] ?? 0.0;
    final rain = weatherData['rain'] ?? 0.0;

    // Clear old notifications (keep only last 24 hours)
    final twentyFourHoursAgo = DateTime.now().subtract(Duration(hours: 24));
    _notifications.removeWhere((n) => n.timestamp.isBefore(twentyFourHoursAgo));

    // ========== REAL ALERTS BASED ON CONDITIONS ==========

    // 1. Critical Rain Alert
    if (rain > 80 && !_hasSimilarNotification("🚨 জরুরি সতর্কতা!")) {
      _sendNotification(
        title: "🚨 জরুরি সতর্কতা!",
        message: "আগামীকাল ${rain.toStringAsFixed(0)}% বৃষ্টির সম্ভাবনা! আপনার $crop এখনই ঢেকে রাখুন অথবা কাটুন। গুদামের দরজা-জানালা বন্ধ করুন।",
        priority: NotificationPriority.critical,
        actionRequired: "এখনই ব্যবস্থা নিন",
        icon: Icons.error,
      );
    }

    // 2. High Humidity Alert
    if (humidity > 85 && storage.contains('গুদাম') && !_hasSimilarNotification("⚠️ আর্দ্রতা সতর্কতা")) {
      _sendNotification(
        title: "⚠️ আর্দ্রতা সতর্কতা",
        message: "গুদামে আর্দ্রতা ${humidity.toStringAsFixed(0)}%। $crop এ ছত্রাক লাগার উচ্চ ঝুঁকি! এখনই ফ্যান চালু করুন এবং বাতাস চলাচল বাড়ান।",
        priority: NotificationPriority.high,
        actionRequired: "ফ্যান চালু করুন",
        icon: Icons.water_damage,
      );
    }

    // 3. High Temperature Alert
    if (temp > 35 && !_hasSimilarNotification("🌡️ তাপমাত্রা সতর্কতা")) {
      _sendNotification(
        title: "🌡️ তাপমাত্রা সতর্কতা",
        message: "তাপমাত্রা ${temp.toStringAsFixed(0)}°C! $crop অতিরিক্ত গরমে নষ্ট হতে পারে। গুদাম ঠান্ডা রাখুন এবং বাতাস চলাচল নিশ্চিত করুন।",
        priority: NotificationPriority.high,
        actionRequired: "বাতাস চলাচল বাড়ান",
        icon: Icons.thermostat,
      );
    }

    // 4. Medium Rain Warning
    if (rain > 60 && rain <= 80 && !_hasSimilarNotification("☔ বৃষ্টির সম্ভাবনা")) {
      _sendNotification(
        title: "☔ বৃষ্টির সম্ভাবনা",
        message: "আগামী ২-৩ দিনে ${rain.toStringAsFixed(0)}% বৃষ্টির সম্ভাবনা। $crop শুকানোর কাজ দ্রুত শেষ করুন। সংরক্ষণের প্রস্তুতি নিন।",
        priority: NotificationPriority.medium,
        actionRequired: "প্রস্তুতি নিন",
        icon: Icons.beach_access,
      );
    }

    // 5. Good Conditions
    if (rain < 30 && temp < 32 && humidity < 70 && !_hasSimilarNotification("✅ অনুকূল আবহাওয়া")) {
      _sendNotification(
        title: "✅ অনুকূল আবহাওয়া",
        message: "আবহাওয়া ভালো আছে (তাপ: ${temp.toStringAsFixed(0)}°C, আর্দ্রতা: ${humidity.toStringAsFixed(0)}%)। $crop শুকানো এবং সংরক্ষণের জন্য এটি উত্তম সময়।",
        priority: NotificationPriority.low,
        actionRequired: "স্বাভাবিক যত্ন",
        icon: Icons.check_circle,
      );
    }

    // 6. Batch Information (only add if no batch info exists today)
    if (!_hasSimilarNotification("📦 ফসলের ব্যাচ")) {
      _sendNotification(
        title: "📦 ফসলের ব্যাচ",
        message: "আপনার $crop ফসলের ব্যাচ সক্রিয় আছে। ওজন: $weight কেজি, সংরক্ষণ: $storage",
        priority: NotificationPriority.low,
        actionRequired: "পর্যালোচনা করুন",
        icon: Icons.agriculture,
      );
    }
  }

  bool _hasSimilarNotification(String title) {
    return _notifications.any((n) => 
      n.title == title && 
      n.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 6)))
    );
  }

  void _sendNotification({
    required String title,
    required String message,
    required NotificationPriority priority,
    required String actionRequired,
    required IconData icon,
  }) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      priority: priority,
      isRead: false,
      actionRequired: actionRequired,
      icon: icon,
    );

    _notifications.insert(0, notification);

    // Update stream
    _notificationController.add(_notifications);

    // Save to Firestore
    _saveNotificationToFirestore(notification);

    // Browser notification for critical alerts
    if (priority == NotificationPriority.critical || priority == NotificationPriority.high) {
      _showBrowserNotification(title, message);
    }

    print('🔔 NEW NOTIFICATION: $title');
  }

  void _showBrowserNotification(String title, String body) {
    try {
      if (html.Notification.supported) {
        html.Notification.requestPermission().then((permission) {
          if (permission == 'granted') {
            html.Notification(title, body: body);
          }
        });
      }
    } catch (e) {
      print('Browser notification error: $e');
    }
  }

  Future<void> _saveNotificationToFirestore(NotificationModel notification) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await _firestore.collection('notifications').add({
        'uid': user.uid,
        'title': notification.title,
        'message': notification.message,
        'timestamp': notification.timestamp,
        'priority': notification.priority.toString(),
        'isRead': notification.isRead,
        'actionRequired': notification.actionRequired,
        'iconCode': notification.icon.codePoint,
      });
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationController.add(_notifications);
    }
  }

  void clearAll() {
    _notifications.clear();
    _notificationController.add(_notifications);
  }

  int get unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  void dispose() {
    _monitoringTimer?.cancel();
    _notificationController.close();
  }
}

// ==================== notification_model.dart ====================
enum NotificationPriority { critical, high, medium, low }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationPriority priority;
  final bool isRead;
  final String actionRequired;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.priority,
    required this.isRead,
    required this.actionRequired,
    required this.icon,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationPriority? priority,
    bool? isRead,
    String? actionRequired,
    IconData? icon,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      actionRequired: actionRequired ?? this.actionRequired,
      icon: icon ?? this.icon,
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
}