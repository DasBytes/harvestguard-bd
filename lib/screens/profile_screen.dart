import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'batch_screen.dart';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);

  String toStringAsFixed(int digits) {
    return 'Lat: ${latitude.toStringAsFixed(digits)}, Lon: ${longitude.toStringAsFixed(digits)}';
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LatLng _selectedLocation = const LatLng(23.8103, 90.4125);
  bool _isLocationSelected = true;

  void _mockLocationSelection() {
    setState(() {
      _selectedLocation = LatLng(
        24.0 + (1 * (0.5 - (DateTime.now().second / 60))),
        90.0 + (1 * (0.5 - (DateTime.now().minute / 60))),
      );
      _isLocationSelected = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'নতুন অবস্থান নির্বাচিত: ${_selectedLocation.toStringAsFixed(4)}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Center(
            child: Icon(
              Icons.map_outlined,
              size: 100.sp,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        if (_isLocationSelected)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.redAccent, size: 48.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(5.r),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  'আপনার ফার্মের অবস্থান',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        Positioned(
          bottom: 15.h,
          child: ElevatedButton.icon(
            onPressed: _mockLocationSelection,
            icon: const Icon(Icons.edit_location_alt, color: Colors.white),
            label: Text(
              'অবস্থান চিহ্নিত করুন',
              style: TextStyle(fontSize: 16.sp, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ফার্মের অবস্থান নির্ধারণ (A2)',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              'A2: ম্যাপে আপনার প্রধান ফার্মের অবস্থান চিহ্নিত করুন। এই ডেটা আবহাওয়ার পরামর্শের জন্য ব্যবহৃত হবে।',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15.r),
                child: _buildMapPlaceholder(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'নির্বাচিত অবস্থান (Mock): ${_selectedLocation.toStringAsFixed(4)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.blueGrey),
                ),
                SizedBox(height: 10.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const BatchScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    minimumSize: Size(double.infinity, 55.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'অবস্থান সেভ করুন ও শস্য ইনভেন্টরি শুরু করুন',
                    style: TextStyle(fontSize: 18.sp, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
