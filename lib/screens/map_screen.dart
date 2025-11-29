import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final User? user = FirebaseAuth.instance.currentUser;
  final String weatherApiKey = "efd7529b3243b1f612734dc3664e89e4";
  
  bool _isLoading = true;
  String _statusMessage = "মানচিত্র লোড করা হচ্ছে...";
  
  LatLng? _farmerLocation;
  String _farmerCrop = "";
  String _farmerRiskLevel = "মাঝারি";
  
  List<Map<String, dynamic>> _neighborData = [];
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    try {
      await _fetchFarmerLocation();
      _generateMockNeighborData();
      await _fetchWeatherForFarmer();
      
      setState(() {
        _isLoading = false;
        _statusMessage = "মানচিত্র প্রস্তুত";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "ত্রুটি: $e";
      });
    }
  }
  
  Future<void> _fetchFarmerLocation() async {
    setState(() {
      _statusMessage = "কৃষকের অবস্থান খুঁজছি...";
    });
    
    if (user == null) {
      throw Exception("ব্যবহারকারী লগইন করেননি");
    }
    
    final snapshot = await FirebaseFirestore.instance
        .collection('create_batches')
        .where('uid', isEqualTo: user!.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) {
      throw Exception("কোন ব্যাচ পাওয়া যায়নি");
    }
    
    final data = snapshot.docs.first.data();
    _farmerCrop = data['cropNameBn'] ?? 'ধান';
    
    String location = data['location'] ?? 'Dhaka, Bangladesh';
    _farmerLocation = _getCoordinatesFromLocation(location);
  }
  
  LatLng _getCoordinatesFromLocation(String location) {
    Map<String, LatLng> locationMap = {
      'Dhaka': LatLng(23.8103, 90.4125),
      'Chattogram': LatLng(22.3569, 91.7832),
      'Chittagong': LatLng(22.3569, 91.7832),
      'Sylhet': LatLng(24.8949, 91.8687),
      'Rajshahi': LatLng(24.3745, 88.6042),
      'Khulna': LatLng(22.8456, 89.5403),
      'Barisal': LatLng(22.7010, 90.3535),
      'Rangpur': LatLng(25.7439, 89.2752),
      'Mymensingh': LatLng(24.7471, 90.4203),
      'Comilla': LatLng(23.4607, 91.1809),
    };
    
    for (var city in locationMap.keys) {
      if (location.contains(city)) {
        return locationMap[city]!;
      }
    }
    return LatLng(23.8103, 90.4125);
  }
  
  void _generateMockNeighborData() {
    setState(() {
      _statusMessage = "প্রতিবেশী তথ্য তৈরি করা হচ্ছে...";
    });
    
    if (_farmerLocation == null) return;
    
    final random = Random();
    final crops = ['ধান', 'গম', 'আলু', 'পাট', 'ভুট্টা', 'টমেটো', 'শসা'];
    final riskLevels = ['কম', 'মাঝারি', 'উচ্চ'];
    
    _neighborData = List.generate(15, (index) {
      double latOffset = (random.nextDouble() - 0.5) * 0.2;
      double lngOffset = (random.nextDouble() - 0.5) * 0.2;
      String risk = riskLevels[random.nextInt(3)];
      
      return {
        'location': LatLng(
          _farmerLocation!.latitude + latOffset,
          _farmerLocation!.longitude + lngOffset,
        ),
        'crop': crops[random.nextInt(crops.length)],
        'riskLevel': risk,
        'lastUpdate': _generateMockTime(),
        'color': _getRiskColor(risk),
      };
    });
  }
  
  String _generateMockTime() {
    final random = Random();
    int hoursAgo = random.nextInt(12) + 1;
    return '$hoursAgo ঘন্টা আগে';
  }
  
  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'কম':
        return Colors.green;
      case 'উচ্চ':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }
  
  Future<void> _fetchWeatherForFarmer() async {
    if (_farmerLocation == null) return;
    
    setState(() {
      _statusMessage = "আবহাওয়া তথ্য সংগ্রহ করা হচ্ছে...";
    });
    
    try {
      final url = "https://api.openweathermap.org/data/2.5/forecast"
          "?lat=${_farmerLocation!.latitude}"
          "&lon=${_farmerLocation!.longitude}"
          "&appid=$weatherApiKey"
          "&units=metric";
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _calculateFarmerRisk(data);
      }
    } catch (e) {
      print("Weather fetch error: $e");
    }
  }
  
  void _calculateFarmerRisk(Map<String, dynamic> weatherData) {
    try {
      var forecast = weatherData["list"].take(3).toList();
      double avgTemp = 0;
      double avgHumidity = 0;
      double maxRain = 0;
      
      for (var day in forecast) {
        avgTemp += (day["main"]["temp"] ?? 0).toDouble();
        avgHumidity += (day["main"]["humidity"] ?? 0).toDouble();
        double rain = ((day["pop"] ?? 0) * 100);
        if (rain > maxRain) maxRain = rain;
      }
      
      avgTemp /= 3;
      avgHumidity /= 3;
      
      if (maxRain > 80 || avgTemp > 35 || avgHumidity > 85) {
        _farmerRiskLevel = "উচ্চ";
      } else if (maxRain > 60 || avgTemp > 30 || avgHumidity > 75) {
        _farmerRiskLevel = "মাঝারি";
      } else {
        _farmerRiskLevel = "কম";
      }
    } catch (e) {
      print("Risk calculation error: $e");
    }
  }
  
  void _showNeighborInfo(Map<String, dynamic> neighbor) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                neighbor['color'].withOpacity(0.1),
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: neighbor['color'],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'প্রতিবেশী খামার',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildInfoItem(Icons.grass, 'ফসলের ধরন', neighbor['crop']),
              SizedBox(height: 12),
              _buildInfoItem(
                Icons.warning_amber_rounded,
                'ঝুঁকির মাত্রা',
                neighbor['riskLevel'],
                color: neighbor['color'],
              ),
              SizedBox(height: 12),
              _buildInfoItem(
                Icons.access_time,
                'শেষ আপডেট',
                neighbor['lastUpdate'],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'বন্ধ করুন',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.grey.shade900,
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text(
            'স্থানীয় ঝুঁকি মানচিত্র',
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
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_farmerLocation == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: Text('স্থানীয় ঝুঁকি মানচিত্র'),
          backgroundColor: Colors.green.shade700,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.orange.shade700,
                ),
                SizedBox(height: 16),
                Text(
                  'অবস্থান তথ্য পাওয়া যায়নি',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'স্থানীয় ঝুঁকি মানচিত্র',
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
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _initializeMap();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'মানচিত্রের চিহ্ন',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(Colors.blue, 'আপনার খামার'),
                    _buildLegendItem(Colors.green, 'কম ঝুঁকি'),
                    _buildLegendItem(Colors.orange, 'মাঝারি ঝুঁকি'),
                    _buildLegendItem(Colors.red, 'উচ্চ ঝুঁকি'),
                  ],
                ),
              ],
            ),
          ),
Expanded(
  child: FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      initialCenter: _farmerLocation!,
      initialZoom: 12.0,
      minZoom: 5.0,
      maxZoom: 18.0,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.example.app',
      ),
                MarkerLayer(
                  markers: _neighborData.map((neighbor) {
                    return Marker(
                      point: neighbor['location'],
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showNeighborInfo(neighbor),
                        child: Container(
                          decoration: BoxDecoration(
                            color: neighbor['color'],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _farmerLocation!,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showFarmerInfo(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade300,
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person_pin_circle,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  void _showFarmerInfo() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_pin_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'আপনার খামার',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildInfoItem(Icons.grass, 'ফসলের ধরন', _farmerCrop),
              SizedBox(height: 12),
              _buildInfoItem(
                Icons.warning_amber_rounded,
                'ঝুঁকির মাত্রা',
                _farmerRiskLevel,
                color: _getRiskColor(_farmerRiskLevel),
              ),
              SizedBox(height: 12),
              _buildInfoItem(
                Icons.access_time,
                'শেষ আপডেট',
                'এখনই',
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'বন্ধ করুন',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
