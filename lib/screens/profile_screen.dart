import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'home_screen.dart'; // Make sure this exists

class ProfileScreen extends StatefulWidget {
  final bool isBangla;
  const ProfileScreen({super.key, this.isBangla = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;

  Stream<Map<String, dynamic>?> _profileStream() {
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('farmers')
        .doc(user!.uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  Stream<List<Map<String, dynamic>>> _batchesStream() {
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('create_batches')
        .where('uid', isEqualTo: user!.uid)
        .snapshots()
        .map((snapshot) {
      final batches = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'crop': data['cropNameBn'] ?? '',
          'weight': data['quantityKg'] ?? 0,
          'date': data['harvestDate'] != null
              ? (data['harvestDate'] as Timestamp).toDate()
              : null,
          'location': data['location'] ?? '',
          'storage': data['storageType'] ?? '',
          'completed': data['isCompleted'] ?? true,
          'timestamp': data['timestamp'] ?? Timestamp.now(),
        };
      }).toList();

      batches.sort((a, b) {
        final t1 = a['timestamp'] as Timestamp;
        final t2 = b['timestamp'] as Timestamp;
        return t2.compareTo(t1);
      });

      return batches;
    });
  }

  Future<void> _exportFirebaseData() async {
    try {
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isBangla ? 'ব্যবহারকারী লগইন করেননি' : 'User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Request storage permission for Android
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isBangla ? 'স্টোরেজ অনুমতি প্রয়োজন' : 'Storage permission required'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
      }

      final snapshot = await _firestore
          .collection('create_batches')
          .where('uid', isEqualTo: user!.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isBangla ? 'কোনও ডেটা নেই' : 'No data to export'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final batches = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'crop': data['cropNameBn'] ?? '',
          'weight': data['quantityKg'] ?? 0,
          'date': data['harvestDate'] != null
              ? (data['harvestDate'] as Timestamp).toDate().toIso8601String()
              : '',
          'location': data['location'] ?? '',
          'storage': data['storageType'] ?? '',
          'completed': data['isCompleted'] ?? true,
        };
      }).toList();

      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // JSON Export
      final jsonFile = File('${directory.path}/crop_batches_${DateTime.now().millisecondsSinceEpoch}.json');
      await jsonFile.writeAsString(json.encode(batches));

      // CSV Export
      final csvFile = File('${directory.path}/crop_batches_${DateTime.now().millisecondsSinceEpoch}.csv');
      final headers = ['Crop', 'Weight (kg)', 'Date', 'Location', 'Storage', 'Completed'];
      final csvBuffer = StringBuffer();
      csvBuffer.writeln(headers.join(','));
      
      for (var batch in batches) {
        final row = [
          '"${batch['crop']}"',
          batch['weight'],
          '"${batch['date']}"',
          '"${batch['location']}"',
          '"${batch['storage']}"',
          batch['completed']
        ];
        csvBuffer.writeln(row.join(','));
      }
      await csvFile.writeAsString(csvBuffer.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla 
                ? 'ডেটা সফলভাবে এক্সপোর্ট হয়েছে\n${directory.path}' 
                : 'Data exported successfully to\n${directory.path}'
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isBangla 
                ? 'এক্সপোর্ট ব্যর্থ হয়েছে: $e' 
                : 'Export failed: $e'
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  List<String> _earnedBadges(List<Map<String, dynamic>> batches) {
    final badges = <String>[];
    if (batches.isNotEmpty) badges.add('First Harvest Logged');
    if (batches.any((b) => b['completed'] == true)) badges.add('Risk Mitigated Expert');
    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isBangla;
    final primaryColor = const Color(0xFF2E7D32);

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            t ? "প্রোফাইল ড্যাশবোর্ড" : "Profile Dashboard",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            t ? "ব্যবহারকারী লগইন করেননি" : "User not logged in",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t ? "প্রোফাইল ড্যাশবোর্ড" : "Profile Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white, size: 26),
              tooltip: t ? 'ডেটা এক্সপোর্ট করুন' : 'Export Data',
              onPressed: _exportFirebaseData,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.home, color: Colors.white, size: 26),
              tooltip: t ? 'হোমস্ক্রিন' : 'Home',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _profileStream(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                strokeWidth: 4,
              ),
            );
          }
          final profileData = profileSnapshot.data;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _batchesStream(),
            builder: (context, batchSnapshot) {
              if (batchSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeWidth: 4,
                  ),
                );
              }

              final batches = batchSnapshot.data ?? [];
              final latestBatch = batches.isNotEmpty ? batches.first : null;
              final otherBatches = batches.length > 1 ? batches.sublist(1) : [];
              final badges = _earnedBadges(batches);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ================= Farmer Info =================
                    if (profileData != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green.shade100, Colors.green.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade300,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.shade400,
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "${profileData['name'] ?? 'Farmer'}",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                              SizedBox(height: 12),
                              _buildInfoChip(
                                Icons.email,
                                profileData['email'] ?? '',
                                Colors.blue,
                              ),
                              SizedBox(height: 8),
                              _buildInfoChip(
                                Icons.phone,
                                profileData['phone'] ?? '',
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ================= Achievement Badges =================
                    if (badges.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.emoji_events, color: Colors.amber.shade700, size: 28),
                              SizedBox(width: 8),
                              Text(
                                t ? "অর্জিত ব্যাজ" : "Achievement Badges",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: badges
                                .map((b) => Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade400,
                                            Colors.orange.shade400,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.shade200,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            b,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                          SizedBox(height: 24),
                        ],
                      ),

                    // ================= Latest Batch =================
                    Row(
                      children: [
                        Icon(Icons.new_releases, color: Colors.purple.shade700, size: 28),
                        SizedBox(width: 8),
                        Text(
                          t ? "সর্বশেষ ব্যাচ" : "Latest Batch",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (latestBatch != null) _batchCard(latestBatch, true),

                    SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.inventory_2, color: Colors.indigo.shade700, size: 28),
                        SizedBox(width: 8),
                        Text(
                          t ? "সকল ব্যাচ" : "All Batches",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (otherBatches.isEmpty)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            t ? "কোনও ব্যাচ নেই" : "No batches found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ...otherBatches
                        .map<Widget>((batch) => _batchCard(batch, false))
                        .toList(),

                    SizedBox(height: 24),
                    // ================= Intervention & Success Stats =================
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.teal.shade700, size: 28),
                        SizedBox(width: 8),
                        Text(
                          t ? "পরিসংখ্যান" : "Statistics",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade50, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          t ? "সফল হস্তক্ষেপ হার" : "Intervention Success Rate",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "80%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red.shade50, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.shade200,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.trending_down,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        title: Text(
                          t ? "ফসল ক্ষতি হার" : "Historical Crop Loss Rate",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "5%",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _batchCard(Map<String, dynamic> batch, bool isLatest) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLatest
              ? [Colors.purple.shade50, Colors.white]
              : [Colors.blue.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest ? Colors.purple.shade300 : Colors.blue.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isLatest ? Colors.purple.shade200 : Colors.blue.shade200,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLatest)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.purple.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_new, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      "Latest",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            _buildBatchInfoRow(Icons.grass, "Crop", batch['crop'], Colors.green),
            _buildBatchInfoRow(Icons.scale, "Weight", "${batch['weight']} kg", Colors.orange),
            if (batch['date'] != null)
              _buildBatchInfoRow(
                Icons.calendar_today,
                "Date",
                "${batch['date'].day}-${batch['date'].month}-${batch['date'].year}",
                Colors.blue,
              ),
            _buildBatchInfoRow(Icons.location_on, "Location", batch['location'], Colors.red),
            _buildBatchInfoRow(Icons.storage, "Storage", batch['storage'], Colors.purple),
            _buildBatchInfoRow(
              Icons.check_circle,
              "Completed",
              batch['completed'] ? 'Yes' : 'No',
              batch['completed'] ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchInfoRow(IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
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