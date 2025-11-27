import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:harvestguard_bd/screens/home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isBangla;
  final Map<String, String>? latestBatch;

  const ProfileScreen({super.key, required this.isBangla, this.latestBatch});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final user = AuthService().currentUser;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _farmerStream() {
    if (user == null) throw Exception("User not logged in");
    return _firestore.collection('farmers').doc(user!.uid).snapshots();
  }

  Stream<List<Map<String, dynamic>>> _batchesStream() {
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('crop_batches')
        .where('uid', isEqualTo: user!.uid) // only current user's batches
        .snapshots()
        .map((snapshot) {
      final batches = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'crop': data['crop'] ?? '',
          'weight': data['weight'] ?? '',
          'date': data['date'] ?? '',
          'location': data['location'] ?? '',
          'storage': data['storage'] ?? '',
          'timestamp': data['timestamp'] ?? null,
        };
      }).toList();

      // Sort by timestamp descending
      batches.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return batches;
    });
  }

  Future<void> _saveBatchToFirebase(Map<String, String> batch) async {
    if (user == null) return;
    try {
      await _firestore.collection('crop_batches').add({
        'uid': user!.uid,
        'crop': batch['crop'],
        'weight': batch['weight'],
        'date': batch['date'],
        'location': batch['location'],
        'storage': batch['storage'],
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error saving batch: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.latestBatch != null) {
      _saveBatchToFirebase(widget.latestBatch!);
    }
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
        body: Center(child: Text(t ? "ব্যবহারকারী লগইন করেননি" : "User not logged in")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t ? "প্রোফাইল ড্যাশবোর্ড" : "Profile Dashboard"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: t ? "হোমে যান" : "Go to Home",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _farmerStream(),
        builder: (context, farmerSnapshot) {
          if (farmerSnapshot.hasError) {
            return Center(
              child: Text(t ? "ত্রুটি হয়েছে" : "Something went wrong"),
            );
          }
          if (!farmerSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final farmerData = farmerSnapshot.data!.data();

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _batchesStream(),
            builder: (context, batchSnapshot) {
              if (batchSnapshot.hasError) {
                return Center(
                    child: Text(t ? "ত্রুটি হয়েছে" : "Something went wrong"));
              }
              if (!batchSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final batches = batchSnapshot.data!;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ================= Farmer Info =================
                    if (farmerData != null)
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farmerData['name'] ?? "Farmer",
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                farmerData['email'] ?? "",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                farmerData['phone'] ?? "",
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ================= Latest Batch =================
                    Text(
                      t ? "সর্বশেষ ব্যাচ" : "Latest Batch",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (widget.latestBatch != null)
                      _batchCard(widget.latestBatch!),

                    const SizedBox(height: 24),
                    Text(
                      t ? "সকল ব্যাচ" : "All Batches",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...batches.map(_batchCard).toList(),

                    const SizedBox(height: 24),
                    Text(
                      t ? "ইতিহাস এবং সফলতা হার" : "Loss Events & Success Rates",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _statCard(
                      t ? "সফল হস্তক্ষেপ" : "Successful Interventions",
                      "80%",
                      primaryColor,
                    ),
                    const SizedBox(height: 8),
                    _statCard(
                      t ? "ফসল ক্ষতি হার" : "Crop Loss Rate",
                      "5%",
                      Colors.red,
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
            Text("Date: ${batch['date']}"),
            Text("Location: ${batch['location']}"),
            Text("Storage: ${batch['storage']}"),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
