import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'profile_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('লগইন / নিবন্ধন', style: TextStyle(fontSize: 18.sp)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'শস্য রক্ষা',
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4CAF50),
              ),
            ).animate().fade().slideY(delay: 50.ms),
            SizedBox(height: 10.h),
            Text(
              'আপনার ফসল সংরক্ষণের যাত্রা শুরু করুন',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 40.h),

            TextField(
              decoration: InputDecoration(
                labelText: 'ইমেইল',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ).animate().slideX(delay: 200.ms, begin: 0.1),
            SizedBox(height: 20.h),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'পাসওয়ার্ড',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ).animate().slideX(delay: 300.ms, begin: -0.1),
            SizedBox(height: 40.h),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                'প্রবেশ করুন',
                style: TextStyle(fontSize: 18.sp, color: Colors.white),
              ),
            ).animate().fadeIn(delay: 400.ms),

            SizedBox(height: 20.h),
            const Divider(),
            SizedBox(height: 20.h),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              icon: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/2048px-Google_%22G%22_logo.svg.png',
                height: 24.h,
                width: 24.w,
              ),
              label: Text(
                'Google দিয়ে প্রবেশ করুন',
                style: TextStyle(fontSize: 16.sp, color: Colors.black),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
