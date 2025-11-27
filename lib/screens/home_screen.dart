import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> storyTexts = [
    'ফসলগুলো জমিতে ভালোভাবে প্রস্তুত হয়েছে।',
    'কিন্তু বাজারে বিক্রি করতে সময়মতো পৌঁছাতে পারছে না।',
    'ফসল নষ্ট হচ্ছে, কৃষকের লোকসান হচ্ছে।',
    'দেশও খারাপ প্রভাবের মুখে।',
    'সঠিক প্রযুক্তি ব্যবহার করলে এই খাদ্য অপচয় অনেক কমানো সম্ভব।',
    'চলুন, প্রযুক্তির মাধ্যমে ফসল রক্ষা করি।',
  ];

  final List<String> storyImages = [
    'https://picsum.photos/id/1011/800/1200',
    'https://picsum.photos/id/1025/800/1200',
    'https://picsum.photos/id/1040/800/1200',
    'https://picsum.photos/id/1060/800/1200',
    'https://picsum.photos/id/1074/800/1200',
    'https://picsum.photos/id/1084/800/1200',
  ];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startStoryLoop();
  }

  void _startStoryLoop() async {
    for (int i = 0; i < storyTexts.length; i++) {
      await Future.delayed(const Duration(seconds: 4)); // slow text change
      if (mounted) {
        setState(() {
          currentIndex = i;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(393, 852));

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(seconds: 1),
              child: Image.network(
                storyImages[currentIndex],
                key: ValueKey<int>(currentIndex),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey,
                    alignment: Alignment.center,
                    child: const Text(
                      'ছবি আনতে সমস্যা হয়েছে',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  );
                },
              ).animate().fade(duration: 1200.ms),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 50.h),

                  Text(
                        'Harvest Guard-BD',
                        style: TextStyle(
                          fontSize: 32.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 800))
                      .slideY(begin: -0.2, end: 0, delay: 200.ms),

                  SizedBox(height: 80.h),

                  DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [
                        Shadow(
                          blurRadius: 6.0,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: AnimatedTextKit(
                        key: ValueKey<int>(currentIndex),
                        animatedTexts: [
                          TypewriterAnimatedText(
                            storyTexts[currentIndex],
                            speed: const Duration(milliseconds: 80),
                          ),
                        ],
                        totalRepeatCount: 1,
                        isRepeatingAnimation: false,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Get Started Button
                  Padding(
                    padding: EdgeInsets.only(bottom: 30.h),
                    child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AuthScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            elevation: 10,
                          ),
                          child: Text(
                            'শুরু করুন (Get Started)',
                            style: TextStyle(
                              fontSize: 22.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                        .animate()
                        .slideY(
                          delay: const Duration(milliseconds: 3500),
                          begin: 0.5,
                          end: 0,
                        )
                        .fadeIn(delay: const Duration(milliseconds: 3500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
