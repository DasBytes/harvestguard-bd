import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

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
        .collection('crop_batches')
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
    final snapshot = await _firestore
        .collection('crop_batches')
        .where('uid', isEqualTo: user!.uid)
        .get();

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

    final directory = await getApplicationDocumentsDirectory();

    // JSON
    final jsonFile = File('${directory.path}/batches.json');
    await jsonFile.writeAsString(json.encode(batches));

    // CSV
    final csvFile = File('${directory.path}/batches.csv');
    final headers = ['crop', 'weight', 'date', 'location', 'storage', 'completed'];
    final csvBuffer = StringBuffer();
    csvBuffer.writeln(headers.join(','));
    for (var batch in batches) {
      final row = [
        batch['crop'],
        batch['weight'],
        batch['date'],
        batch['location'],
        batch['storage'],
        batch['completed']
      ];
      csvBuffer.writeln(row.join(','));
    }
    await csvFile.writeAsString(csvBuffer.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data exported to ${directory.path}'),
        backgroundColor: Colors.green,
      ),
    );
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
        appBar: AppBar(
          title: Text(t ? "প্রোফাইল ড্যাশবোর্ড" : "Profile Dashboard"),
          backgroundColor: primaryColor,
        ),
        body: Center(
          child: Text(t ? "ব্যবহারকারী লগইন করেননি" : "User not logged in"),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t ? "প্রোফাইল ড্যাশবোর্ড" : "Profile Dashboard"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: t ? 'ডেটা এক্সপোর্ট করুন' : 'Export Data',
            onPressed: _exportFirebaseData,
          ),
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            tooltip: t ? 'হোমস্ক্রিন' : 'Home',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _profileStream(),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profileData = profileSnapshot.data;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _batchesStream(),
            builder: (context, batchSnapshot) {
              if (batchSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
                      Card(
                        color: Colors.green.shade50,
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Name: ${profileData['name'] ?? 'Farmer'}",
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Email: ${profileData['email'] ?? ''}",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Phone: ${profileData['phone'] ?? ''}",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
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
                          Text(
                            t ? "অর্জিত ব্যাজ" : "Achievement Badges",
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: badges
                                .map((b) => Chip(
                                      label: Text(b),
                                      backgroundColor: Colors.orange.shade100,
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // ================= Latest Batch =================
                    Text(
                      t ? "সর্বশেষ ব্যাচ" : "Latest Batch",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (latestBatch != null) _batchCard(latestBatch),

                    const SizedBox(height: 24),
                    Text(
                      t ? "সকল ব্যাচ" : "All Batches",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (otherBatches.isEmpty)
                      Text(t ? "কোনও ব্যাচ নেই" : "No batches found"),
                    ...otherBatches .map<Widget>((batch) => _batchCard(batch))
                        .toList(),

                    const SizedBox(height: 24),
                    // ================= Intervention & Success Stats =================
                    Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                            t ? "সফল হস্তক্ষেপ হার" : "Intervention Success Rate"),
                        trailing: Text(
                          "80%",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      child: ListTile(
                        title:
                            Text(t ? "ফসল ক্ষতি হার" : "Historical Crop Loss Rate"),
                        trailing: const Text(
                          "5%",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _batchCard(Map<String, dynamic> batch) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Crop: ${batch['crop']}"),
            Text("Weight: ${batch['weight']} kg"),
            if (batch['date'] != null)
              Text(
                  "Date: ${batch['date'].day}-${batch['date'].month}-${batch['date'].year}"),
            Text("Location: ${batch['location']}"),
            Text("Storage: ${batch['storage']}"),
            Text("Completed: ${batch['completed'] ? 'Yes' : 'No'}"),
          ],
        ),
      ),
    );
  }
}
