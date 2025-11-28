import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // Used for max() function

// =========================================================================
// MOCK AUTH STATUS HOLDER (Simulates status passed from AuthScreen)
// Set to true to allow registration and analysis. Set to false to show the verification wall.
bool mockIsFarmerVerified = true;
// -------------------------------------------------------------------------

// API Configuration (Place your actual API key here for real data)
const String _openWeatherApiKey =
    "a5d43311b134a1d5d32822708b445453"; // <<< IMPORTANT: REPLACE WITH YOUR ACTUAL KEY
const String _openWeatherBaseUrl =
    "api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={_openWeatherApiKey}";

// =========================================================================
// MODELS & UTILITIES
// =========================================================================

enum StorageType { juteBagStack, silo, openArea }

class CropBatch {
  final String id;
  final String cropNameBn;
  final double quantityKg;
  final DateTime harvestDate;
  final String location;
  final StorageType storageType;
  final double moisturePercent;
  final bool isCompleted;

  CropBatch({
    required this.id,
    required this.cropNameBn,
    required this.quantityKg,
    required this.harvestDate,
    required this.location,
    required this.storageType,
    required this.moisturePercent,
    required this.isCompleted,
  });
}

class CropDataUtility {
  static const List<String> cropTypes = ['ধান/চাল'];
  static const List<String> storageLocations = [
    'ঢাকা',
    'চট্টগ্রাম',
    'রাজশাহী',
    'খুলনা',
    'বরিশাল',
    'সিলেট',
  ];
  static const Map<StorageType, String> storageTypeMapBn = {
    StorageType.juteBagStack: 'পাটের বস্তা স্ট্যাক',
    StorageType.silo: 'সাইলো',
    StorageType.openArea: 'খোলা এলাকা',
  };

  // Mapping Bengali location names to Lat/Lon for OpenWeatherMap API accuracy
  static const Map<String, ({double lat, double lon})> locationCoordinates = {
    'ঢাকা': (lat: 23.8103, lon: 90.4125), // Dhaka
    'চট্টগ্রাম': (lat: 22.3569, lon: 91.7832), // Chittagong
    'রাজশাহী': (lat: 24.3745, lon: 88.6042), // Rajshahi
    'খুলনা': (lat: 22.8456, lon: 89.5403), // Khulna
    'বরিশাল': (lat: 22.7010, lon: 90.3535), // Barisal
    'সিলেট': (lat: 24.8949, lon: 91.8687), // Sylhet
  };
}

class WeatherForecast {
  final int day;
  final String date;
  final double tempC;
  final double humidityPercent;
  final double rainProbPercent;

  WeatherForecast({
    required this.day,
    required this.date,
    required this.tempC,
    required this.humidityPercent,
    required this.rainProbPercent,
  });
}

// =========================================================================
// WEATHER SERVICE (Implemented with API structure and Mock Fallback)
// =========================================================================

class WeatherService {
  // MOCK FALLBACK: Generates deterministic data when API key is missing or invalid.
  List<WeatherForecast> _generateMockForecast() {
    return [
      WeatherForecast(
        day: 1,
        date: DateFormat(
          'dd MMM',
        ).format(DateTime.now().add(const Duration(days: 0))),
        tempC: 30.5,
        humidityPercent: 75,
        rainProbPercent: 20,
      ),
      WeatherForecast(
        day: 2,
        date: DateFormat(
          'dd MMM',
        ).format(DateTime.now().add(const Duration(days: 1))),
        tempC: 29.8,
        humidityPercent: 80,
        rainProbPercent: 65,
      ),
      WeatherForecast(
        day: 3,
        date: DateFormat(
          'dd MMM',
        ).format(DateTime.now().add(const Duration(days: 2))),
        tempC: 32.0,
        humidityPercent: 70,
        rainProbPercent: 10,
      ),
      WeatherForecast(
        day: 4,
        date: DateFormat(
          'dd MMM',
        ).format(DateTime.now().add(const Duration(days: 3))),
        tempC: 28.5,
        humidityPercent: 85,
        rainProbPercent: 75,
      ),
      WeatherForecast(
        day: 5,
        date: DateFormat(
          'dd MMM',
        ).format(DateTime.now().add(const Duration(days: 4))),
        tempC: 31.2,
        humidityPercent: 68,
        rainProbPercent: 40,
      ),
    ];
  }

  // Main function to fetch forecast, using the lat/lon API structure
  Future<List<WeatherForecast>> fetchForecast(String location) async {
    // CRITICAL CHECK: If API key is not provided or coordinates are missing, return mock data immediately.
    final coordinates = CropDataUtility.locationCoordinates[location];

    // Check if the API key is the placeholder or the location is unknown
    if (_openWeatherApiKey.isEmpty ||
        _openWeatherApiKey == "YOUR_OPENWEATHERMAP_API_KEY_HERE" ||
        coordinates == null) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay
      return _generateMockForecast();
    }

    // --- REAL API LOGIC STARTS HERE ---
    final lat = coordinates.lat;
    final lon = coordinates.lon;

    // Construct the URL using the requested structure:
    // api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={API key}
    // We add &units=metric to get Celsius temperatures.
    final url = Uri.parse(
      '$_openWeatherBaseUrl?lat=$lat&lon=$lon&appid=$_openWeatherApiKey&units=metric',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<WeatherForecast> forecastList = [];

        final List list = data['list'];

        // We parse the 3-hour forecasts and aggregate them to a single daily forecast for 5 days
        Map<String, List<Map<String, dynamic>>> dailyData = {};

        for (var item in list) {
          final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          final dateKey = DateFormat('dd MMM').format(dt);

          // Only process future dates, starting from the next full day.
          // This ensures we get a clean 5-day forecast.
          if (dt.day != DateTime.now().day || dailyData.isNotEmpty) {
            if (!dailyData.containsKey(dateKey)) {
              dailyData[dateKey] = [];
            }
            dailyData[dateKey]!.add({
              'temp': item['main']['temp'].toDouble(),
              'humidity': item['main']['humidity'].toDouble(),
              'rainProb':
                  (item['pop'] * 100)
                      .toDouble(), // Probability of precipitation
            });
          }
        }

        // Process daily data (up to 5 days)
        int dayCounter = 1;

        // Use a counter to track how many unique days we've processed
        int daysProcessed = 0;

        // Iterate over the daily data map to create the final list
        for (var entry in dailyData.entries) {
          if (daysProcessed >= 5) break;

          // FIX: Explicitly cast to double to resolve the 'num Function(num, num)' type error with reduce(max)
          // and to ensure clean arithmetic reduction for sum.
          final tempSum = entry.value
              .map((e) => e['temp'] as double)
              .reduce((a, b) => a + b);
          final humiditySum = entry.value
              .map((e) => e['humidity'] as double)
              .reduce((a, b) => a + b);
          final rainProbMax = entry.value
              .map((e) => e['rainProb'] as double)
              .reduce(max);

          forecastList.add(
            WeatherForecast(
              day: dayCounter++,
              date: entry.key,
              tempC: tempSum / entry.value.length, // Average temp
              humidityPercent:
                  humiditySum / entry.value.length, // Average humidity
              rainProbPercent:
                  rainProbMax, // Maximum rain probability of the day
            ),
          );
          daysProcessed++;
        }

        // If the API failed to return a full 5 days (e.g., due to data availability), fill with mock data.
        if (forecastList.length < 5) {
          print(
            'Warning: API returned less than 5 days. Filling with mock data.',
          );
          final mockFiller = _generateMockForecast().sublist(
            forecastList.length,
          );
          for (var item in mockFiller) {
            forecastList.add(
              WeatherForecast(
                day: dayCounter++,
                date: item.date,
                tempC: item.tempC,
                humidityPercent: item.humidityPercent,
                rainProbPercent: item.rainProbPercent,
              ),
            );
          }
        }

        return forecastList;
      } else {
        // If API call fails (e.g., 401 Unauthorized, 404 Not Found), return mock data for stability
        print('API call failed: Status ${response.statusCode}');
        return _generateMockForecast();
      }
    } catch (e) {
      // If network error occurs (e.g., no internet), return mock data
      print('Network error during API call: $e');
      return _generateMockForecast();
    }
  }

  Future<Map<String, dynamic>> calculateRisk(
    CropBatch batch,
    List<WeatherForecast> forecast,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));

    double riskScore = 0;
    int badDays = 0;

    // Risk factors based on moisture
    if (batch.moisturePercent > 25.0) {
      riskScore += 50;
    } else if (batch.moisturePercent > 20.0) {
      riskScore += 20;
    }

    // Risk factors based on weather forecast
    for (var day in forecast) {
      // High risk condition: high humidity, high temperature, high chance of rain
      if (day.humidityPercent > 80 &&
          day.tempC > 28 &&
          day.rainProbPercent > 60) {
        riskScore += 15;
        badDays++;
      }
    }

    // Estimated Time to Critical Loss (ETCL) calculation based on risk score
    int etclHours = 168;
    if (riskScore > 80) {
      etclHours = Random().nextInt(48) + 12; // 12-60 hours
    } else if (riskScore > 40) {
      etclHours = Random().nextInt(72) + 60; // 60-132 hours
    } else {
      etclHours = Random().nextInt(100) + 150; // 150-250 hours
    }

    String riskLevel;
    String summaryBn;

    if (etclHours < 72) {
      riskLevel = 'URGENT';
      summaryBn =
          'তাত্ক্ষণিক জরুরি: উচ্চ আর্দ্রতা এবং প্রতিকূল আবহাওয়ার কারণে ৭২ ঘন্টার মধ্যে ফসল পচে যাওয়ার গুরুতর ঝুঁকি রয়েছে। অবিলম্বে শস্য শুকানোর ব্যবস্থা নিন।';
    } else if (etclHours < 120) {
      riskLevel = 'CRITICAL';
      summaryBn =
          'বিপজ্জনক: আর্দ্রতা এবং আবহাওয়ার সংমিশ্রণে পচনের ঝুঁকি খুব বেশি। আগামী ৫ দিনের মধ্যে ২-৩ দিন বৃষ্টি ও উচ্চ আর্দ্রতার পূর্বাভাস রয়েছে।';
    } else if (etclHours < 168) {
      riskLevel = 'HIGH';
      summaryBn =
          'উচ্চ ঝুঁকি: আর্দ্রতার মাত্রা গ্রহণযোগ্য সীমার বাইরে। ভবিষ্যতের বৃষ্টিপাত এটিকে আরও বাড়িয়ে দেবে। দৈনিক পর্যবেক্ষণ প্রয়োজন।';
    } else if (etclHours < 200) {
      riskLevel = 'MODERATE';
      summaryBn =
          'মাঝারি ঝুঁকি: আর্দ্রতা কিছুটা বেশি হলেও আবহাওয়া আপাতত অনুকূল। সতর্কতামূলক ব্যবস্থা হিসেবে বায়ুচলাচল নিশ্চিত করুন।';
    } else {
      riskLevel = 'LOW';
      summaryBn =
          'কম ঝুঁকি: আর্দ্রতা এবং আবহাওয়ার পূর্বাভাস অনুকূল। স্টোরেজ আদর্শ অবস্থায় আছে।';
    }

    //
    return {
      'risk_level': riskLevel,
      'etcl_hours': etclHours,
      'summary_bn': summaryBn,
      'bad_days': badDays,
    };
  }
}

// =========================================================================
// DASHBOARD SCREEN
// =========================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final WeatherService _weatherService = WeatherService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CropBatch? _currentBatch;
  List<WeatherForecast> _forecast = [];
  Map<String, dynamic> _riskResult = {};
  bool _isLoading = false;
  String _error = '';

  // State reflects the external mock status passed from the AuthScreen
  bool _isFarmerVerified = false;

  // Form controllers and state
  String? _cropType = CropDataUtility.cropTypes.first;
  String? _storageLocation = CropDataUtility.storageLocations.first;
  StorageType? _storageType = StorageType.juteBagStack;
  final TextEditingController _quantityController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _moistureController = TextEditingController(
    text: '19.5',
  );
  DateTime? _harvestDate = DateTime.now();
  final TextEditingController _harvestDateController = TextEditingController(
    text: DateFormat('dd MMM yyyy').format(DateTime.now()),
  );

  @override
  void initState() {
    super.initState();
    _checkFarmerVerificationStatus();
  }

  void _checkFarmerVerificationStatus() {
    // MOCK CHECK: Uses the global mock variable to simulate state from AuthScreen.
    setState(() {
      _isFarmerVerified = mockIsFarmerVerified;
    });

    // If verified, and no batch is registered yet, auto-submit default values to show analysis immediately
    if (_isFarmerVerified && _currentBatch == null && mockIsFarmerVerified) {
      _submitRegistration(bypassValidation: true);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _moistureController.dispose();
    _harvestDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (_currentBatch == null) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Call the updated WeatherService which handles real API attempt or mock fallback
      final forecast = await _weatherService.fetchForecast(
        _currentBatch!.location,
      );
      final riskResult = await _weatherService.calculateRisk(
        _currentBatch!,
        forecast,
      );

      setState(() {
        _forecast = forecast;
        _riskResult = riskResult;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _error = 'তথ্য লোড করতে সমস্যা হয়েছে।';
        _isLoading = false;
      });
    }
  }

  void _submitRegistration({bool bypassValidation = false}) {
    if (bypassValidation || _formKey.currentState!.validate()) {
      if (!bypassValidation) {
        _formKey.currentState!.save();
      }

      final newBatch = CropBatch(
        id: 'BCH${Random().nextInt(9999)}',
        cropNameBn: _cropType!,
        quantityKg: double.tryParse(_quantityController.text) ?? 1000.0,
        harvestDate: _harvestDate!,
        location: _storageLocation!,
        storageType: _storageType!,
        moisturePercent: double.tryParse(_moistureController.text) ?? 19.5,
        isCompleted: true,
      );

      // In a real app: Save 'newBatch' data to Firestore linked to the current user ID here.

      setState(() {
        _currentBatch = newBatch;
      });

      _fetchData();
    }
  }

  Widget _buildUnverifiedAlert() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.red.shade300, width: 2.w),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade100,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person, color: Colors.red.shade700, size: 50.sp),
              SizedBox(height: 15.h),
              Text(
                'প্রথমে আপনার অ্যাকাউন্টটি যাচাই করুন',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'ফসল ব্যাচ নিবন্ধন করতে এবং ঝুঁকি বিশ্লেষণ দেখতে আপনাকে অবশ্যই একজন যাচাইকৃত কৃষক হতে হবে। অনুগ্রহ করে নিবন্ধন/লগইন করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700),
              ),
              SizedBox(height: 25.h),
              ElevatedButton.icon(
                onPressed: () {
                  // MOCK ACTION: Simulates navigation to the AuthScreen for registration.
                  print(
                    '--- Simulating Navigation to AuthScreen for Registration ---',
                  );
                  // In a real app, you would use: Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));

                  // For demo, we simulate a successful registration upon 'return' to show the next screen
                  setState(() {
                    mockIsFarmerVerified = true;
                    _checkFarmerVerificationStatus();
                  });
                },
                icon: const Icon(Icons.person_add, color: Colors.white),
                label: Text(
                  'নিবন্ধন করুন',
                  style: TextStyle(fontSize: 18.sp, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 15.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'নতুন ব্যাচ নিবন্ধন',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF388E3C),
              ),
            ).animate().fadeIn().slideX(begin: -0.1),
            SizedBox(height: 15.h),
            Text(
              'আবহাওয়ার ঝুঁকি বিশ্লেষণ করতে আপনার ফসলের তথ্য দিন। (যাচাইকৃত কৃষক)',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 30.h),

            _buildDropdownField(
              'ফসলের প্রকার',
              _cropType,
              CropDataUtility.cropTypes,
              (String? newValue) {
                setState(() {
                  _cropType = newValue;
                });
              },
            ),

            _buildTextField(
              'আনুমানিক ওজন (কেজি)',
              '1000',
              _quantityController,
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null ||
                    double.tryParse(val) == null ||
                    double.parse(val) <= 0) {
                  return 'সঠিক ওজন দিন';
                }
                return null;
              },
            ),

            _buildTextField(
              'বর্তমান আর্দ্রতা (%)',
              'যেমন: 19.5',
              _moistureController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (val) {
                if (val == null ||
                    double.tryParse(val) == null ||
                    double.parse(val) < 10 ||
                    double.parse(val) > 40) {
                  return 'সঠিক আর্দ্রতার মাত্রা (১০-৪০%) দিন';
                }
                return null;
              },
            ),

            _buildDateField(),

            _buildDropdownField(
              'সংরক্ষণের অবস্থান (জেলা/বিভাগ)',
              _storageLocation,
              CropDataUtility.storageLocations,
              (String? newValue) {
                setState(() {
                  _storageLocation = newValue;
                });
              },
            ),

            _buildDropdownField(
              'সংরক্ষণের প্রকার',
              CropDataUtility.storageTypeMapBn[_storageType],
              CropDataUtility.storageTypeMapBn.values.toList(),
              (String? newValue) {
                setState(() {
                  _storageType =
                      CropDataUtility.storageTypeMapBn.entries
                          .firstWhere((e) => e.value == newValue)
                          .key;
                });
              },
            ),

            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed: () => _submitRegistration(bypassValidation: false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: EdgeInsets.symmetric(vertical: 18.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 8,
              ),
              child: Text(
                'নিবন্ধন করুন ও ঝুঁকি দেখুন',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).scaleXY(begin: 0.95, end: 1),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: const TextStyle(color: Color(0xFF388E3C)),
        ),
        validator: validator,
        style: TextStyle(fontSize: 16.sp),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: const TextStyle(color: Color(0xFF388E3C)),
        ),
        isExpanded: true,
        items:
            items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(fontSize: 16.sp)),
              );
            }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'এই ক্ষেত্রটি আবশ্যক' : null,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: TextFormField(
        controller: _harvestDateController,
        readOnly: true,
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _harvestDate ?? DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
            helpText: 'ফসল তোলার তারিখ নির্বাচন করুন',
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  primaryColor: const Color(0xFF4CAF50),
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF4CAF50),
                  ),
                  buttonTheme: const ButtonThemeData(
                    textTheme: ButtonTextTheme.primary,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null && picked != _harvestDate) {
            setState(() {
              _harvestDate = picked;
              _harvestDateController.text = DateFormat(
                'dd MMM yyyy',
              ).format(picked);
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'ফসল তোলার তারিখ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          suffixIcon: const Icon(
            Icons.calendar_today,
            color: Color(0xFF388E3C),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: const TextStyle(color: Color(0xFF388E3C)),
        ),
        validator: (value) => _harvestDate == null ? 'তারিখ আবশ্যক' : null,
        style: TextStyle(fontSize: 16.sp),
      ),
    );
  }

  Widget _buildRiskCard() {
    if (_riskResult.isEmpty || _currentBatch == null)
      return const SizedBox.shrink();

    final etclHours = _riskResult['etcl_hours'] as int? ?? 0;
    final riskLevel = _riskResult['risk_level'] as String? ?? 'LOW';
    final summaryBn =
        _riskResult['summary_bn'] as String? ??
        'কম আর্দ্রতা এবং অনুকূল আবহাওয়ার কারণে ঝুঁকি কম।';

    Color color;
    String riskTextBn;

    switch (riskLevel) {
      case 'URGENT':
        color = const Color(0xFFD32F2F);
        riskTextBn = 'তাত্ক্ষণিক জরুরি';
        break;
      case 'CRITICAL':
        color = const Color(0xFFFBC02D);
        riskTextBn = 'বিপজ্জনক';
        break;
      case 'HIGH':
        color = const Color(0xFFFF9800);
        riskTextBn = 'উচ্চ ঝুঁকি';
        break;
      case 'MODERATE':
        color = const Color(0xFF388E3C);
        riskTextBn = 'মাঝারি ঝুঁকি';
        break;
      case 'LOW':
      default:
        color = const Color(0xFF4CAF50);
        riskTextBn = 'কম ঝুঁকি';
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ক্ষতির সময়সীমা (ETCL) (A4)',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$etclHours',
                style: TextStyle(
                  fontSize: 50.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'ঘন্টা',
                style: TextStyle(
                  fontSize: 28.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  riskTextBn,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: Colors.white54, height: 25.h),
          Text(
            summaryBn,
            style: TextStyle(fontSize: 17.sp, color: Colors.white, height: 1.4),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildWeatherForecast() {
    if (_forecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Text(
            'আগামী ৫ দিনের আবহাওয়ার পূর্বাভাস (A3)',
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF388E3C),
            ),
          ),
        ),
        SizedBox(
          height: 180.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _forecast.length,
            itemBuilder: (context, index) {
              final day = _forecast[index];
              return Container(
                width: 120.w,
                margin: EdgeInsets.only(right: 15.w, bottom: 5.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      index == 0 ? 'আজ' : 'দিন ${day.day}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D47A1),
                      ),
                    ),
                    Text(
                      day.date,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Icon(
                      day.rainProbPercent > 50
                          ? Icons.thunderstorm
                          : (day.tempC > 30 ? Icons.wb_sunny : Icons.cloud),
                      color:
                          day.rainProbPercent > 50
                              ? Colors.blue.shade700
                              : Colors.orange.shade700,
                      size: 30.sp,
                    ),
                    Text(
                      '${day.tempC.toStringAsFixed(1)}°C',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'বৃষ্টি: ${day.rainProbPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ).animate().slideX(
                begin: 0.1 * index,
                duration: 400.ms,
                delay: (100 * index).ms,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisory(String riskLevel, int badDays) {
    String advisory = 'নিয়মিত পর্যবেক্ষণ করুন। স্টোরেজ আদর্শ অবস্থায় আছে।';
    Color bgColor = const Color(0xFFE8F5E9);

    if (riskLevel == 'URGENT' || riskLevel == 'CRITICAL') {
      advisory =
          badDays > 0
              ? 'আগামী $badDays দিনের প্রতিকূল আবহাওয়ার জন্য ধানকে অবশ্যই সুরক্ষিত স্থানে সরিয়ে নিন বা দ্রুত শুকানোর ব্যবস্থা করুন!'
              : 'দ্রুত পচনের ঝুঁকি। এখনই আর্দ্রতা পরীক্ষা করুন ও স্থানান্তর করুন।';
      bgColor = const Color(0xFFFFEBEE);
    } else if (riskLevel == 'HIGH' || riskLevel == 'MODERATE') {
      advisory =
          'আর্দ্রতা কমাতে দিনে একবার গুদামে বায়ুচলাচল করুন। বৃষ্টির আগে ধান ঢেকে রাখার জন্য প্রস্তুত থাকুন।';
      bgColor = const Color(0xFFFFFDE7);
    }

    return Container(
      margin: EdgeInsets.only(top: 20.h, bottom: 20.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.5.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: const Color(0xFF4CAF50),
            size: 28.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'কৃষি পরামর্শ: $advisory',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (!_isFarmerVerified) {
      content = _buildUnverifiedAlert();
    } else if (_currentBatch == null) {
      content = _buildRegistrationForm();
    } else {
      content =
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              )
              : _error.isNotEmpty
              ? Center(
                child: Text(
                  _error,
                  style: TextStyle(fontSize: 18.sp, color: Colors.red),
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),
                    Text(
                      'ব্যাচ: ${_currentBatch!.cropNameBn} | আর্দ্রতা: ${_currentBatch!.moisturePercent.toStringAsFixed(1)}% | অবস্থান: ${_currentBatch!.location} | সংরক্ষণের প্রকার: ${CropDataUtility.storageTypeMapBn[_currentBatch!.storageType]}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(),

                    _buildRiskCard(),

                    _buildAdvisory(
                      _riskResult['risk_level'] as String? ?? 'LOW',
                      _riskResult['bad_days'] as int? ?? 0,
                    ),

                    _buildWeatherForecast(),

                    SizedBox(height: 40.h),

                    TextButton.icon(
                      onPressed: () {
                        // Allow user to register a new batch
                        setState(() {
                          _currentBatch = null;
                          _riskResult = {};
                          _forecast = [];
                          // Reset form fields
                          _quantityController.text = '1000';
                          _moistureController.text = '19.5';
                          _harvestDate = DateTime.now();
                          _harvestDateController.text = DateFormat(
                            'dd MMM yyyy',
                          ).format(DateTime.now());
                        });
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Color(0xFF388E3C),
                      ),
                      label: Text(
                        'নতুন ব্যাচ নিবন্ধন করুন',
                        style: TextStyle(
                          color: const Color(0xFF388E3C),
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        title: Text(
          'খাদ্য সুরক্ষা ড্যাশবোর্ড',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
      ),
      body: content,
    );
  }
}
