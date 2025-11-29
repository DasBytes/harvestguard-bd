// ==================== notification_screen.dart ====================
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<SmartAlert> _alerts = [];
  bool _isLoading = true;
  String _status = '';
  Timer? _monitoringTimer;
  
  final String weatherApiKey = "efd7529b3243b1f612734dc3664e89e4";

  @override
  void initState() {
    super.initState();
    _startSmartMonitoring();
  }

  void _startSmartMonitoring() {
    // Check immediately
    _checkAndGenerateSmartAlerts();
    
    // Check every 30 minutes
    _monitoringTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      _checkAndGenerateSmartAlerts();
    });
  }

  Future<void> _checkAndGenerateSmartAlerts() async {
    try {
      setState(() {
        _isLoading = true;
        _status = 'ফসল ও আবহাওয়া ডেটা বিশ্লেষণ করা হচ্ছে...';
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _status = 'ব্যবহারকারী লগইন করেননি';
          _isLoading = false;
        });
        return;
      }

      // Fetch latest batch data
      final batchSnapshot = await _firestore
          .collection('create_batches')
          .where('uid', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (batchSnapshot.docs.isEmpty) {
        setState(() {
          _status = 'কোন ফসলের ব্যাচ পাওয়া যায়নি';
          _isLoading = false;
        });
        return;
      }

      final batchData = batchSnapshot.docs.first.data();
      final crop = batchData['cropNameBn'] ?? '';
      final storage = batchData['storageType'] ?? '';
      final location = batchData['location'] ?? '';

      // Get weather data
      final weatherData = await _getWeatherData(location);
      
      // Generate smart alerts
      await _generateSmartAlerts(crop, storage, weatherData);

      setState(() {
        _isLoading = false;
        _status = 'মনিটরিং সক্রিয়';
      });

    } catch (e) {
      setState(() {
        _status = 'ত্রুটি: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getWeatherData(String location) async {
    try {
      // Get coordinates for location
      final coords = await _getCoordinates(location);
      
      final url = "https://api.openweathermap.org/data/2.5/forecast?"
          "lat=${coords['lat']}&lon=${coords['lon']}&appid=$weatherApiKey&units=metric";

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data["list"][0];
        final forecast = data["list"].take(5).toList();

        // Calculate max rain in next 3 days
        double maxRain = 0;
        for (var day in forecast.take(3)) {
          double rain = ((day["pop"] ?? 0) * 100);
          if (rain > maxRain) maxRain = rain;
        }

        return {
          'temp': (current["main"]["temp"] ?? 0).toDouble(),
          'humidity': (current["main"]["humidity"] ?? 0).toDouble(),
          'rain': maxRain,
          'description': current["weather"][0]["description"] ?? '',
        };
      }
    } catch (e) {
      print('Weather API error: $e');
    }

    return {
      'temp': 30.0,
      'humidity': 75.0,
      'rain': 40.0,
      'description': 'হালকা মেঘ',
    };
  }

  Future<Map<String, dynamic>> _getCoordinates(String city) async {
    try {
      city = city.trim();
      final url = Uri.parse(
          "https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(city)}&count=1&format=json");
      
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final results = (data['results'] as List?) ?? [];
        
        if (results.isNotEmpty) {
          final m = results.first as Map<String, dynamic>;
          return {
            'lat': (m['latitude'] as num).toDouble(),
            'lon': (m['longitude'] as num).toDouble(),
          };
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }

    // Fallback to Dhaka
    return {'lat': 23.8103, 'lon': 90.4125};
  }

  Future<void> _generateSmartAlerts(
      String crop, String storage, Map<String, dynamic> weather) async {
    
    final temp = weather['temp'] ?? 0.0;
    final humidity = weather['humidity'] ?? 0.0;
    final rain = weather['rain'] ?? 0.0;

    _alerts.clear();

    // ========== SMART DECISION ENGINE ==========

    // 1. Critical Rain + Storage Combination
    if (rain > 80) {
      if (storage.contains('গুদাম')) {
        _addSmartAlert(
          title: "🚨 জরুরি: ভারী বৃষ্টি ও গুদাম ঝুঁকি",
          message: "আগামীকাল ${rain.toStringAsFixed(0)}% বৃষ্টির সম্ভাবনা! আপনার $crop গুদামে সংরক্ষিত আছে। এখনই গুদামের দরজা-জানালা বন্ধ করুন এবং ফ্যান চালু করুন।",
          priority: AlertPriority.critical,
          action: "গুদাম সুরক্ষিত করুন",
          combination: "বৃষ্টি + গুদাম সংরক্ষণ",
        );
        _simulateSMS("CRITICAL_RAIN_STORAGE", rain);
      } else {
        _addSmartAlert(
          title: "🚨 জরুরি: ভারী বৃষ্টি সতর্কতা",
          message: "আগামীকাল ${rain.toStringAsFixed(0)}% বৃষ্টির সম্ভাবনা! আপনার $crop এখনই কাটুন অথবা পলিথিন দিয়ে ঢেকে রাখুন।",
          priority: AlertPriority.critical,
          action: "ফসল কাটুন/ঢাকুন",
          combination: "বৃষ্টি + ক্ষেতের ফসল",
        );
        _simulateSMS("CRITICAL_RAIN_FIELD", rain);
      }
    }

    // 2. High Humidity + Storage Combination
    if (humidity > 85 && storage.contains('গুদাম')) {
      _addSmartAlert(
        title: "⚠️ উচ্চ আর্দ্রতা: ছত্রাক ঝুঁকি",
        message: "গুদামে আর্দ্রতা ${humidity.toStringAsFixed(0)}%। $crop এ ছত্রাক লাগার উচ্চ ঝুঁকি! এখনই ফ্যান চালু করুন এবং বাতাস চলাচল বাড়ান।",
        priority: AlertPriority.high,
        action: "বাতাস চলাচল বাড়ান",
        combination: "আর্দ্রতা + গুদাম সংরক্ষণ",
      );
    }

    // 3. High Temperature + Crop Specific Advice
    if (temp > 35) {
      String cropSpecificAdvice = _getCropSpecificAdvice(crop, temp);
      _addSmartAlert(
        title: "🌡️ উচ্চ তাপমাত্রা: ফসল ঝুঁকি",
        message: "তাপমাত্রা ${temp.toStringAsFixed(0)}°C! $cropSpecificAdvice",
        priority: AlertPriority.high,
        action: "শীতলীকরণ ব্যবস্থা নিন",
        combination: "তাপমাত্রা + ফসল প্রকার",
      );
    }

    // 4. Moderate Rain + Harvest Timing
    if (rain > 60 && rain <= 80) {
      _addSmartAlert(
        title: "☔ বৃষ্টির পূর্বাভাস: সময় ব্যবস্থাপনা",
        message: "আগামী ২-৩ দিনে ${rain.toStringAsFixed(0)}% বৃষ্টির সম্ভাবনা। $crop শুকানোর কাজ দ্রুত শেষ করুন এবং সংরক্ষণের প্রস্তুতি নিন।",
        priority: AlertPriority.medium,
        action: "দ্রুত শুকানো শেষ করুন",
        combination: "মাঝারি বৃষ্টি + সময় ব্যবস্থাপনা",
      );
    }

    // 5. Good Conditions + Storage Maintenance
    if (rain < 30 && temp < 32 && humidity < 70) {
      _addSmartAlert(
        title: "✅ অনুকূল আবহাওয়া: রক্ষণাবেক্ষণ সময়",
        message: "আবহাওয়া অনুকূলে আছে (তাপ: ${temp.toStringAsFixed(0)}°C, আর্দ্রতা: ${humidity.toStringAsFixed(0)}%)। $crop এর নিয়মিত যত্ন নিন এবং গুদাম পরিদর্শন করুন।",
        priority: AlertPriority.low,
        action: "নিয়মিত যত্ন নিন",
        combination: "অনুকূল আবহাওয়া + রক্ষণাবেক্ষণ",
      );
    }

    // 6. Pest Risk Analysis
    if (humidity > 80 && temp > 25 && temp < 32) {
      _addSmartAlert(
        title: "🐛 পোকামাকড়ের ঝুঁকি: প্রতিরোধ প্রয়োজন",
        message: "আর্দ্রতা ও তাপমাত্রা পোকামাকড়ের জন্য অনুকূল। $crop এ জৈব কীটনাশক স্প্রে করার কথা বিবেচনা করুন।",
        priority: AlertPriority.medium,
        action: "কীটনাশক স্প্রে করুন",
        combination: "আর্দ্রতা + তাপমাত্রা + পোকা ঝুঁকি",
      );
    }

    // Show browser alerts for critical notifications
    _showBrowserAlerts();
  }

  String _getCropSpecificAdvice(String crop, double temp) {
    if (crop.contains('ধান')) {
      return "ধান অতিরিক্ত গরমে চিটা হতে পারে। জমিতে পানি ধরে রাখুন এবং বাতাস চলাচলের ব্যবস্থা করুন।";
    } else if (crop.contains('আলু')) {
      return "আলু গরমে অঙ্কুরিত হতে পারে। গুদাম ঠান্ডা রাখুন এবং বায়ু চলাচল বাড়ান।";
    } else if (crop.contains('গম')) {
      return "গমের গুণগত মান কমতে পারে। দ্রুত সংরক্ষণ করুন এবং সরাসরি সূর্যালোক এড়ান।";
    } else {
      return "$crop অতিরিক্ত গরমে নষ্ট হতে পারে। ছায়া ব্যবস্থা করুন এবং নিয়মিত পানি দিন।";
    }
  }

  void _addSmartAlert({
    required String title,
    required String message,
    required AlertPriority priority,
    required String action,
    required String combination,
  }) {
    // Check if similar alert already exists
    final existingIndex = _alerts.indexWhere((alert) => alert.title == title);
    
    if (existingIndex == -1) {
      _alerts.insert(0, SmartAlert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        timestamp: DateTime.now(),
        priority: priority,
        action: action,
        combination: combination,
        isRead: false,
      ));
    }
  }

  void _showBrowserAlerts() {
    // Show browser alert for critical alerts
    final criticalAlerts = _alerts.where((alert) => 
      alert.priority == AlertPriority.critical && !alert.isRead
    ).toList();

    for (final alert in criticalAlerts) {
      _showBrowserAlert(alert.title, alert.message);
    }

    // Show summary alert if multiple critical alerts
    if (criticalAlerts.length > 1) {
      _showBrowserAlert(
        "🚨 একাধিক জরুরি বিজ্ঞপ্তি", 
        "আপনার ফসলের জন্য ${criticalAlerts.length} টি জরুরি বিজ্ঞপ্তি আছে। এখনই ব্যবস্থা নিন।"
      );
    }
  }

  void _showBrowserAlert(String title, String message) {
    html.window.alert("$title\n\n$message");
  }

  void _simulateSMS(String alertType, double value) {
    html.window.console.log('''
╔═══════════════════════════════════════════════════════════╗
║  SMS NOTIFICATION - HarvestGuard BD Smart Alert          ║
╠═══════════════════════════════════════════════════════════╣
║  Alert Type: $alertType
║  Value: ${value.toStringAsFixed(1)}%
║  Time: ${DateTime.now().toString()}
║  Status: CRITICAL - Immediate Action Required
║  Message: Farmer advised to take immediate action
╚═══════════════════════════════════════════════════════════╝
    ''');
  }

  void _markAsRead(String alertId) {
    setState(() {
      final index = _alerts.indexWhere((alert) => alert.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "স্মার্ট বিজ্ঞপ্তি",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _checkAndGenerateSmartAlerts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.green.shade50],
              ),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  _isLoading ? Icons.refresh : Icons.check_circle,
                  color: _isLoading ? Colors.orange : Colors.green,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                if (!_isLoading)
                  Text(
                    '${_alerts.length} টি বিজ্ঞপ্তি',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "স্মার্ট অ্যালার্ট তৈরি করা হচ্ছে...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : _alerts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              "কোন স্মার্ট বিজ্ঞপ্তি নেই",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "যখন ফসল ও আবহাওয়ার ডেটা বিশ্লেষণ করে\nস্মার্ট বিজ্ঞপ্তি তৈরি হবে, তখন এখানে দেখানো হবে",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return _buildSmartAlertCard(alert);
                        },
                      ),
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _checkAndGenerateSmartAlerts,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: Icon(Icons.psychology_alt),
        tooltip: "স্মার্ট অ্যালার্ট চেক করুন",
      ),
    );
  }

  Widget _buildSmartAlertCard(SmartAlert alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: alert.isRead ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.priorityColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: alert.priorityColor.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _markAsRead(alert.id);
          });
          _showBrowserAlert(alert.title, alert.message);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with priority and combination
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: alert.priorityColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      alert.priorityIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          alert.combination,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!alert.isRead)
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              // Smart Message
              Text(
                alert.message,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 12),
              // Action and Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      alert.action,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(alert.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'এখনই';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} মিনিট আগে';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ঘন্টা আগে';
    } else {
      return '${difference.inDays} দিন আগে';
    }
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }
}

// ==================== SMART ALERT MODEL ====================
enum AlertPriority { critical, high, medium, low }

class SmartAlert {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final AlertPriority priority;
  final String action;
  final String combination;
  final bool isRead;

  SmartAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.priority,
    required this.action,
    required this.combination,
    required this.isRead,
  });

  Color get priorityColor {
    switch (priority) {
      case AlertPriority.critical:
        return Colors.red;
      case AlertPriority.high:
        return Colors.orange;
      case AlertPriority.medium:
        return Colors.yellow.shade700;
      case AlertPriority.low:
        return Colors.green;
    }
  }

  IconData get priorityIcon {
    switch (priority) {
      case AlertPriority.critical:
        return Icons.error;
      case AlertPriority.high:
        return Icons.warning;
      case AlertPriority.medium:
        return Icons.info;
      case AlertPriority.low:
        return Icons.check_circle;
    }
  }

  SmartAlert copyWith({
    bool? isRead,
  }) {
    return SmartAlert(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      priority: priority,
      action: action,
      combination: combination,
      isRead: isRead ?? this.isRead,
    );
  }
}