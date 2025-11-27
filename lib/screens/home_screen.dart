import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:harvestguard_bd/screens/login_screen.dart';
import 'package:harvestguard_bd/screens/registration_screen.dart';
import 'package:harvestguard_bd/screens/profile_screen.dart';
import 'package:harvestguard_bd/screens/batch_screen.dart';
import 'package:harvestguard_bd/screens/scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool isBangla = true;
  late AnimationController _flowController;
  late AnimationController _pulseController;

  String farmerName = "Farmer"; // Default
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fetchFarmerName();
  }

  Future<void> _fetchFarmerName() async {
    final user = AuthService().currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            farmerName = doc.data()?['name'] ?? "Farmer";
            isLoadingName = false;
          });
        } else {
          setState(() {
            farmerName = "Farmer";
            isLoadingName = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching farmer name: $e");
        setState(() {
          farmerName = "Farmer";
          isLoadingName = false;
        });
      }
    } else {
      setState(() {
        farmerName = "Farmer";
        isLoadingName = false;
      });
    }
  }

  @override
  void dispose() {
    _flowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get isLoggedIn => AuthService().currentUser != null;

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(
      context,
      designSize: const Size(1200, 800),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF4),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildHeroSection(),
              _buildProblemStatement(),
              _buildAnimatedFlowVisualization(),
              _buildImpactMetrics(),
              if (!isLoggedIn) _buildCallToAction(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ================= Drawer =================
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.green.shade500],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 48.sp, color: Colors.white),
                  SizedBox(height: 8.h),
                  Text(
                    "HarvestGuardBD",
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.language, color: Colors.green.shade700),
            title: Text(isBangla ? "বাংলা" : "English",
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            trailing: Switch(
              value: isBangla,
              onChanged: (val) {
                setState(() {
                  isBangla = val;
                });
              },
              activeColor: Colors.green.shade700,
            ),
          ),
          if (isLoggedIn) ...[
            _buildDrawerItem(Icons.person, isBangla ? "প্রোফাইল" : "Profile", '/profile'),
            _buildDrawerItem(Icons.storage, isBangla ? "ব্যাচ স্ক্রিন" : "Batch Screen", '/batch'),
            _buildDrawerItem(Icons.qr_code_scanner, isBangla ? "স্ক্যানার" : "Scanner", '/scanner'),
            _buildDrawerItem(Icons.logout, isBangla ? "লগআউট" : "Logout", '/logout'),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String? route) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(title, style: TextStyle(fontSize: 16.sp)),
      onTap: () {
        Navigator.pop(context);
        if (route == '/logout') {
          AuthService().signOut().then((_) {
            setState(() {
              farmerName = "Farmer";
              isLoadingName = true;
              _fetchFarmerName();
            });
          });
        } else if (route != null) {
          if (route == '/profile') {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => ProfileScreen(isBangla: isBangla)));
          } else if (route == '/batch') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CropBatchRegistrationScreen(isBangla: isBangla)));
          } else if (route == '/scanner') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerScreen()));
          }
        }
      },
    );
  }

  // ================= Header =================
  Widget _buildHeader() {
    return Container(
      height: 75.h,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.white, size: 32.sp),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Row(
            children: [
              Icon(Icons.agriculture, color: Colors.white, size: 32.sp),
              SizedBox(width: 12.w),
              Text(
                'HarvestGuardBD',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              isLoggedIn
                  ? isLoadingName
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 20.sp,
                              backgroundColor: Colors.white,
                              child: Text(
                                farmerName.isNotEmpty
                                    ? farmerName[0].toUpperCase()
                                    : "F",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20.sp,
                                    color: Colors.green.shade700),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              farmerName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                  : ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen(isBangla: isBangla)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade700,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        isBangla ? 'শুরু করুন' : 'Get Started',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          )
        ],
      ),
    );
  }

  // ================= Hero Section =================
  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      height: 500.h,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          children: [
            Text(
              isBangla
                  ? "খাদ্য বাঁচান • কৃষক বাঁচান • বাংলাদেশ বাঁচান"
                  : "Save Food • Save Farmers • Save Bangladesh",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 38.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2, end: 0),
            SizedBox(height: 40.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 26.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      isBangla
                          ? '৪৫ লাখ মেট্রিক টন খাদ্য নষ্ট হচ্ছে প্রতি বছর।'
                          : '4.5 million metric tons of food wasted yearly.',
                      speed: const Duration(milliseconds: 60),
                    ),
                    TypewriterAnimatedText(
                      isBangla
                          ? 'কৃষকের লোকসান মানে দেশের ক্ষতি।'
                          : 'Farmers lose, the nation loses.',
                      speed: const Duration(milliseconds: 60),
                    ),
                    TypewriterAnimatedText(
                      isBangla
                          ? 'স্মার্ট প্রযুক্তিতে ফসল রক্ষা করুন।'
                          : 'Smart technology saves harvests.',
                      speed: const Duration(milliseconds: 60),
                    ),
                  ],
                  repeatForever: true,
                  pause: const Duration(milliseconds: 2000),
                ),
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }

  // ================= Problem Statement =================
  // (The rest of the code remains the same as you provided)
  



  // ================= Problem Statement =================
  Widget _buildProblemStatement() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(50.w),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            isBangla ? "🚨 সমস্যা" : "🚨 The Problem",
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          SizedBox(height: 30.h),
          Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Column(
              children: [
                _buildProblemCard(Icons.warning_amber_rounded,
                    isBangla ? "প্রতি বছর ৪৫ লাখ মেট্রিক টন খাদ্য নষ্ট" : "4.5M metric tons of food lost annually", Colors.orange),
                SizedBox(height: 20.h),
                _buildProblemCard(Icons.trending_down,
                    isBangla ? "কৃষকরা হাজার কোটি টাকা হারাচ্ছেন" : "Farmers lose billions in revenue", Colors.red),
                SizedBox(height: 20.h),
                _buildProblemCard(Icons.bug_report,
                    isBangla ? "পোকামাকড় ও রোগে ফসল নষ্ট" : "Pests & diseases destroy crops", Colors.purple),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildProblemCard(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32.sp),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // ================= Flow Visualization =================
  Widget _buildAnimatedFlowVisualization() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(50.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            isBangla ? "💡 সমাধান" : "💡 The Solution",
            style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.green.shade800),
          ),
          SizedBox(height: 40.h),
          AnimatedBuilder(
            animation: _flowController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFlowStep(Icons.sensors, isBangla ? 'ডেটা সংগ্রহ' : 'Data', Colors.blue, 0),
                  _buildFlowArrow(),
                  _buildFlowStep(Icons.notification_important, isBangla ? 'সতর্কতা' : 'Warning', Colors.orange, 0.25),
                  _buildFlowArrow(),
                  _buildFlowStep(Icons.agriculture, isBangla ? 'কর্ম' : 'Action', Colors.red, 0.5),
                  _buildFlowArrow(),
                  _buildFlowStep(Icons.check_circle, isBangla ? 'ফসল রক্ষা' : 'Saved', Colors.green.shade700, 0.75),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep(IconData icon, String label, Color color, double delay) {
    final animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _flowController, curve: Interval(delay, delay + 0.25, curve: Curves.easeInOut)),
    );
    return Transform.scale(
      scale: animation.value,
      child: Column(
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)],
            ),
            child: Icon(icon, size: 48.sp, color: Colors.white),
          ),
          SizedBox(height: 15.h),
          Text(label, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        ],
      ),
    );
  }

  Widget _buildFlowArrow() {
    return Icon(Icons.arrow_forward, size: 36.sp, color: Colors.grey.shade400);
  }

  // ================= Impact Metrics =================
  Widget _buildImpactMetrics() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(50.w),
      color: Colors.green.shade800,
      child: Column(
        children: [
          Text(
            isBangla ? "আমাদের প্রভাব" : "Our Impact",
            style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 40.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMetricCard("10K+", isBangla ? "কৃষক" : "Farmers"),
              _buildMetricCard("50K+", isBangla ? "ব্যাচ" : "Batches"),
              _buildMetricCard("₹5Cr", isBangla ? "সঞ্চয়" : "Saved"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String value, String label) {
    return Container(
      width: 200.w,
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 42.sp, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
          SizedBox(height: 10.h),
          Text(label, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).scale(delay: 200.ms);
  }

  // ================= Call to Action =================
  Widget _buildCallToAction() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 80.h),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.green.shade600, Colors.green.shade800])),
      child: Column(
        children: [
          Text(isBangla ? "আজই শুরু করুন" : "Start Protecting Today",
              style: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.bold, color: Colors.white)),
          SizedBox(height: 30.h),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationScreen(isBangla: isBangla)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 60.w, vertical: 25.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                    elevation: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isBangla ? 'বিনামূল্যে নিবন্ধন করুন' : 'Register Free',
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 15.w),
                      Icon(Icons.arrow_forward, size: 28.sp),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= Footer =================
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(40.w),
      color: Colors.grey.shade900,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.agriculture, color: Colors.white, size: 28.sp),
              SizedBox(width: 12.w),
              Text(
                "HarvestGuardBD",
                style: TextStyle(fontSize: 24.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(isBangla ? "স্মার্ট কৃষি প্ল্যাটফর্ম" : "Smart Agriculture Platform",
              style: TextStyle(fontSize: 18.sp, color: Colors.white70)),
          SizedBox(height: 25.h),
          if (!isLoggedIn)
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegistrationScreen(isBangla: isBangla)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 15.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                isBangla ? 'বিনামূল্যে নিবন্ধন করুন' : 'Get Started',
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(height: 15.h),
          Text("© 2025 HarvestGuardBD. All Rights Reserved.",
              style: TextStyle(fontSize: 16.sp, color: Colors.white60)),
        ],
      ),
    );
  }
}
