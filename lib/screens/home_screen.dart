import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isBangla = true;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(1200, 800),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    List<Map<String, dynamic>> graphData = [
      {'label': isBangla ? 'খাদ্য নষ্ট' : 'Food Loss', 'value': 45},
      {'label': isBangla ? 'কৃষকের ক্ষতি' : 'Farmer Loss', 'value': 30},
      {'label': isBangla ? 'দেশের ক্ষতি' : 'Country Loss', 'value': 25},
      {'label': isBangla ? 'রক্ষা করা সম্ভব' : 'Can Save', 'value': 60},
    ];

    List<Map<String, String>> stats = [
      {
        'title': isBangla ? 'খাদ্য নষ্ট' : 'Food Waste',
        'value': isBangla ? '৪৫ লাখ টন' : '4.5M Ton',
      },
      {
        'title': isBangla ? 'কৃষকের ক্ষতি' : 'Farmer Loss',
        'value': isBangla ? '৩০%' : '30%',
      },
      {
        'title': isBangla ? 'দেশের ক্ষতি' : 'Country Loss',
        'value': isBangla ? '২৫%' : '25%',
      },
      {
        'title': isBangla ? 'রক্ষা করা সম্ভব' : 'Can Save',
        'value': isBangla ? '৬০%' : '60%',
      },
    ];

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  "HarvestGuardBD",
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ),
            ListTile(
              title: Text(isBangla ? "প্রোফাইল" : "Profile"),
              leading: const Icon(Icons.person),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              title: Text(isBangla ? "ব্যাচ স্ক্রিন" : "Batch Screen"),
              leading: const Icon(Icons.storage),
              onTap: () => Navigator.pushNamed(context, '/batch'),
            ),
            ListTile(
              title: Text(isBangla ? "স্ক্যানার" : "Scanner"),
              leading: const Icon(Icons.qr_code_scanner),
              onTap: () => Navigator.pushNamed(context, '/scanner'),
            ),
            ListTile(
              title: Text(isBangla ? "সেটিংস" : "Settings"),
              leading: const Icon(Icons.settings),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              title: Text(isBangla ? "লগআউট" : "Logout"),
              leading: const Icon(Icons.logout),
              onTap: () {},
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(isBangla ? "English" : "বাংলা"),
              onTap: () {
                setState(() {
                  isBangla = !isBangla;
                });
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 75.h,
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                color: Colors.green.shade700,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder:
                          (context) => IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                    ),
                    Text(
                      'HarvestGuardBD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isBangla = !isBangla;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              isBangla ? "EN" : "BN",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/auth');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 12.h,
                            ),
                          ),
                          child: Text(
                            isBangla ? 'লগইন' : 'Login',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(40.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      isBangla
                          ? "খাদ্য বাঁচান • কৃষক বাঁচান • বাংলাদেশ বাঁচান"
                          : "Save Food • Save Farmers • Save Bangladesh",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30.h),
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 28.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      child: AnimatedTextKit(
                        animatedTexts: [
                          TypewriterAnimatedText(
                            isBangla
                                ? '৪৫ লাখ মেট্রিক টন খাদ্য নষ্ট হচ্ছে প্রতি বছর।'
                                : '4.5 million metric tons of food are wasted yearly.',
                            speed: const Duration(milliseconds: 70),
                          ),
                          TypewriterAnimatedText(
                            isBangla
                                ? 'কৃষকের লোকসান, দেশের ক্ষতি।'
                                : 'Farmers lose, the country loses.',
                            speed: const Duration(milliseconds: 70),
                          ),
                          TypewriterAnimatedText(
                            isBangla
                                ? 'প্রযুক্তির মাধ্যমে ফসল রক্ষা সম্ভব।'
                                : 'Technology can protect crops.',
                            speed: const Duration(milliseconds: 70),
                          ),
                        ],
                        totalRepeatCount: 1,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      stats.map((stat) {
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 10.w),
                            padding: EdgeInsets.symmetric(vertical: 30.h),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: const Offset(2, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  stat['value']!,
                                  style: TextStyle(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                SizedBox(height: 10.h),
                                Text(
                                  stat['title']!,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 800.ms),
                        );
                      }).toList(),
                ),
              ),

              SizedBox(height: 50.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Container(
                  height: 300.h,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        graphData.map((item) {
                          double barHeight = item['value'] * 3;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 40.w,
                                height: barHeight.h,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                item['label'],
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ).animate().fadeIn(duration: 1000.ms),
              ),

              SizedBox(height: 80.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(40.w),
                color: Colors.green.shade900,
                child: Column(
                  children: [
                    Text(
                      "HarvestGuardBD – Smart Agriculture Platform",
                      style: TextStyle(
                        fontSize: 22.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "© 2025 HarvestGuardBD. All Rights Reserved.",
                      style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
