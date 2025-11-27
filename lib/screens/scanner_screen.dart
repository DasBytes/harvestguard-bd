import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:camera/camera.dart'; // Uncomment and initialize for real camera

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? _imagePath;
  String _mlResult = 'A5: ফলাফল এখানে আসবে...';
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _imagePath = image.path;
        _isLoading = true;
        _mlResult = 'Hugging Face ML মডেলে পাঠানো হচ্ছে...';
      });
      _processImage(image.path);
    }
  }

  Future<void> _processImage(String path) async {
    // MOCK A5 LOGIC: Simulate API call and result from Hugging Face
    await Future.delayed(const Duration(seconds: 3));

    // Mock ML Response
    final String mockDisease = 'ধানের ব্লাস্ট রোগ';
    final double mockConfidence = 0.92;

    setState(() {
      _isLoading = false;
      _mlResult =
          'শনাক্তকরণ সফল!\nরোগ: $mockDisease\nআত্মবিশ্বাস: ${(mockConfidence * 100).toStringAsFixed(1)}%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'শস্যের রোগ স্ক্যানার (A5)',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                ),
                child: Center(
                  child:
                      _imagePath == null
                          ? Icon(
                            Icons.camera_alt_outlined,
                            size: 80.sp,
                            color: Colors.grey,
                          )
                          : Image.network(
                            'https://picsum.photos/id/400/800/600', // Mock Network Image for display
                            fit: BoxFit.cover,
                            key: ValueKey(
                              _imagePath,
                            ), // Force rebuild on new image
                          ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ML Result Area
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.amber.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ML বিশ্লেষণের ফলাফল:',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  _isLoading
                      ? const LinearProgressIndicator()
                      : Text(_mlResult, style: TextStyle(fontSize: 16.sp)),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'গ্যালারি থেকে নিন',
                  onTap: () => _pickImage(ImageSource.gallery),
                  color: Colors.deepOrange,
                ),
                _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'ছবি তুলুন',
                  onTap: () => _pickImage(ImageSource.camera),
                  color: Colors.indigo,
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 30.sp),
        ).animate().scale(duration: 500.ms),
        SizedBox(height: 8.h),
        Text(label, style: TextStyle(fontSize: 14.sp)),
      ],
    );
  }
}
