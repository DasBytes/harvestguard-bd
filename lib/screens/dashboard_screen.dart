import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:harvestguard_bd/screens/map_screen.dart'; // Import your MapScreen here

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? batchData;
  Map<String, dynamic>? weather;
  List<dynamic> forecast = [];
  String advisory = "";
  String riskSummary = "";
  int etclHours = 0;
  final String weatherApiKey = "efd7529b3243b1f612734dc3664e89e4";
  bool _isLoading = true;
  String _apiStatus = "";
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchBatchData();
  }

  Future<void> fetchBatchData() async {
    try {
      setState(() {
        _apiStatus = "ব্যাচের তথ্য লোড করা হচ্ছে...";
        _isLoading = true;
      });

      if (user == null) {
        setState(() {
          _apiStatus = "ব্যবহারকারী লগইন করেননি";
          _isLoading = false;
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('create_batches')
          .where('uid', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _apiStatus = "কোন ব্যাচ পাওয়া যায়নি";
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.docs.first.data();

      batchData = {
        "crop": data['cropNameBn'] ?? '',
        "weight": data['quantityKg'] ?? 0,
        "date": data['harvestDate'] != null
            ? (data['harvestDate'] as Timestamp)
                .toDate()
                .toString()
                .substring(0, 10)
            : '',
        "location": data['location'] ?? '',
        "storage": data['storageType'] ?? '',
      };

      setState(() {
        _apiStatus = "ব্যাচের তথ্য লোড হয়েছে";
      });

      await fetchWeather();
    } catch (e) {
      setState(() {
        _apiStatus = "ব্যাচ ডেটা ত্রুটি: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> fetchWeather() async {
    try {
      double lat = 23.8103;
      double lon = 90.4125;

      setState(() {
        _apiStatus = "আবহাওয়া API কল করা হচ্ছে...";
      });

      final url =
          "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$weatherApiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        setState(() {
          _apiStatus = "আবহাওয়া API ত্রুটি";
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);

      setState(() {
        weather = data["list"][0];
        forecast = data["list"].take(5).toList();
        _apiStatus = "ডেটা লোড হয়েছে";
        _isLoading = false;
      });

      generateAdvisoryAndPrediction();
    } catch (e) {
      setState(() {
        _apiStatus = "নেটওয়ার্ক ত্রুটি: $e";
        _isLoading = false;
      });
    }
  }

  void generateAdvisoryAndPrediction() {
    if (forecast.isEmpty || batchData == null) return;

    String crop = batchData!["crop"];
    String storage = batchData!["storage"];

    double avgTemp = 0;
    double avgHumidity = 0;
    double maxRain = 0;

    for (var day in forecast.take(3)) {
      avgTemp += (day["main"]["temp"] ?? 0).toDouble();
      avgHumidity += (day["main"]["humidity"] ?? 0).toDouble();
      double rain = ((day["pop"] ?? 0) * 100);
      if (rain > maxRain) maxRain = rain;
    }

    avgTemp /= 3;
    avgHumidity /= 3;

    generateAdvisory(crop, storage, avgTemp, avgHumidity, maxRain);
    generateETCLPrediction(avgTemp, avgHumidity, maxRain);
  }

  void generateAdvisory(
      String crop, String storage, double temp, double humidity, double rain) {
    if (rain > 80) {
      advisory =
          "আগামী ৩ দিনে বৃষ্টি ${rain.toStringAsFixed(0)}% → আপনার $crop আজই কাটুন অথবা ভালো করে ঢেকে রাখুন";
    } else if (rain > 60) {
      advisory =
          "বৃষ্টি সম্ভাবনা ${rain.toStringAsFixed(0)}% → $crop শুকানোর সময় পাচ্ছেন না, দ্রুত সংরক্ষণ করুন";
    } else if (temp > 35) {
      advisory =
          "তাপমাত্রা ${temp.toStringAsFixed(0)}°C → $crop অতিরিক্ত গরমে নষ্ট হতে পারে, বাতাস চলাচল বাড়ান";
    } else if (humidity > 85) {
      advisory =
          "আর্দ্রতা ${humidity.toStringAsFixed(0)}% → $crop এ ছত্রাক লাগার সম্ভাবনা, শুকানোর ব্যবস্থা করুন";
    } else {
      advisory = "আবহাওয়া স্বাভাবিক। $crop এর নিয়মিত যত্ন নিন এবং পর্যবেক্ষণ করুন";
    }
  }

  void generateETCLPrediction(double temp, double humidity, double rain) {
    etclHours = 168;

    if (temp > 35)
      etclHours -= 40;
    else if (temp > 30) etclHours -= 20;

    if (humidity > 85)
      etclHours -= 35;
    else if (humidity > 75) etclHours -= 20;

    if (rain > 80)
      etclHours -= 30;
    else if (rain > 60) etclHours -= 15;

    if (etclHours < 24) etclHours = 24;
    if (etclHours > 168) etclHours = 168;

    if (etclHours <= 48) {
      riskSummary =
          "খুব বেশি ঝুঁকি! ফসল নষ্ট হতে পারে মাত্র $etclHours ঘন্টার মধ্যে। এখনই ব্যবস্থা নিন";
    } else if (etclHours <= 72) {
      riskSummary =
          "বেশি ঝুঁকি। ফসল নষ্ট হতে পারে $etclHours ঘন্টার মধ্যে। সতর্ক থাকুন";
    } else if (etclHours <= 120) {
      riskSummary =
          "মাঝারি ঝুঁকি। ফসল নিরাপদ থাকবে $etclHours ঘন্টা। নিয়মিত দেখভাল করুন";
    } else {
      riskSummary =
          "কম ঝুঁকি। ফসল নিরাপদ থাকবে $etclHours ঘন্টা পর্যন্ত। স্বাভাবিক যত্ন নিন";
    }
  }

  IconData _getWeatherIcon(double temp, double rainChance) {
    if (rainChance > 70) return Icons.beach_access;
    if (temp > 35) return Icons.wb_sunny;
    if (temp < 20) return Icons.ac_unit;
    return Icons.cloud;
  }

  Color _getRiskColor() {
    if (etclHours <= 48) return Colors.red;
    if (etclHours <= 72) return Colors.orange;
    if (etclHours <= 120) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || batchData == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            "ফসল ড্যাশবোর্ড",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green.shade700,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                strokeWidth: 4,
              ),
              SizedBox(height: 24),
              Text(
                "লোড হচ্ছে...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (_apiStatus.isNotEmpty) ...[
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _apiStatus,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final crop = batchData!["crop"] ?? "";
    final weight = batchData!["weight"] ?? "";
    final date = batchData!["date"] ?? "";
    final location = batchData!["location"] ?? "";
    final storage = batchData!["storage"] ?? "";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "ফসল ড্যাশবোর্ড",
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
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _apiStatus = "";
                });
                fetchBatchData();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= Error Widget =================
            if (_apiStatus.contains("ত্রুটি"))
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade100, Colors.orange.shade50],
                  ),
                  border: Border.all(color: Colors.orange.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade800, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _apiStatus,
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ================= Batch Info Card =================
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade200,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.agriculture,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "ব্যাচের তথ্য",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildInfoRow(Icons.grass, "ফসল", crop),
                    _buildInfoRow(Icons.scale, "ওজন", "$weight kg"),
                    _buildInfoRow(Icons.calendar_today, "তারিখ", date),
                    _buildInfoRow(Icons.location_on, "অবস্থান", location),
                    _buildInfoRow(Icons.storage, "সংরক্ষণ পদ্ধতি", storage),
                  ],
                ),
              ),
            ),

            SizedBox(height: 28),

            // ================= Weather Forecast Section =================
            Row(
              children: [
                Icon(Icons.wb_cloudy, color: Colors.blue.shade700, size: 28),
                SizedBox(width: 8),
                Text(
                  "আবহাওয়া পূর্বাভাস (৫ দিন)",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            ...forecast.asMap().entries.map((entry) {
              final index = entry.key;
              final f = entry.value;
              final temp = (f["main"]["temp"] ?? 0).toDouble();
              final humidity = f["main"]["humidity"] ?? 0;
              final rain = ((f["pop"] ?? 0) * 100);
              final description = f["weather"][0]["description"] ?? "হালকা মেঘ";

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade300,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getWeatherIcon(temp, rain),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    "${temp.toStringAsFixed(0)}°C",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(
                        description.toString(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "আর্দ্রতা: $humidity% • বৃষ্টি: ${rain.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Day ${index + 1}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 28),

            // ================= Advisory Card =================
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.shade200,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.lightbulb,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "পরামর্শ",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      advisory,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 28),

            // ================= Risk Summary Card =================
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.pink.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getRiskColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.warning,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "ঝুঁকি সংক্ষিপ্তসার",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      riskSummary,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.5,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 28),

            // ================= Map Screen Card Button =================
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>  MapScreen()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 28, color: Colors.blue.shade900),
                      SizedBox(width: 12),
                      Text(
                        "মানচিত্র দেখুন",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.green.shade700),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade900,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
