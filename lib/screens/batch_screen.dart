import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Make sure you have a ProfileScreen to navigate to
import 'package:harvestguard_bd/screens/profile_screen.dart';

class CropBatchRegistrationScreen extends StatefulWidget {
  final bool isBangla;
  const CropBatchRegistrationScreen({super.key, this.isBangla = true});

  @override
  State<CropBatchRegistrationScreen> createState() =>
      _CropBatchRegistrationScreenState();
}

class _CropBatchRegistrationScreenState
    extends State<CropBatchRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form fields
  String _cropType = "Paddy";
  String _storageType = "Jute Bag Stack";
  String _division = "Dhaka";
  String _district = "Dhaka";
  DateTime? _harvestDate = DateTime.now();

  final _weightController = TextEditingController();

  final Map<String, List<String>> _locations = {
    "Dhaka": ["Dhaka", "Gazipur", "Narsingdi"],
    "Chattogram": ["Chattogram", "Cox's Bazar"],
    "Rajshahi": ["Rajshahi", "Natore"],
    "Khulna": ["Khulna", "Bagerhat"],
    "Barishal": ["Barishal", "Patuakhali"],
    "Sylhet": ["Sylhet", "Moulvibazar"],
  };

  Future<void> _submitBatch() async {
    if (!_formKey.currentState!.validate() || _harvestDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isBangla
              ? "সব তথ্য পূরণ করুন।"
              : "Please fill all fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isBangla
              ? "আপনি লগইন করা নেই।"
              : "User not logged in."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final batchData = {
      "uid": user.uid,
      "cropNameBn": _cropType == "Paddy" ? "ধান/চাল" : _cropType,
      "quantityKg": double.tryParse(_weightController.text) ?? 0,
      "harvestDate": Timestamp.fromDate(_harvestDate!),
      "location": "$_division - $_district",
      "storageType": _storageType,
      "moisturePercent": 19.5,
      "isCompleted": true,
      "timestamp": FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('create_batches').add(batchData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isBangla
              ? "ব্যাচ সফলভাবে সংরক্ষিত হয়েছে।"
              : "Batch saved successfully."),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileScreen(isBangla: widget.isBangla)),
      );
    } catch (e) {
      debugPrint("Error saving batch: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isBangla
              ? "ব্যাচ সংরক্ষণে সমস্যা হয়েছে।"
              : "Failed to save batch."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isBangla;
    final primaryColor = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Text(t ? "ফসল ব্যাচ নিবন্ধন" : "Crop Batch Registration"),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Crop type
              DropdownButtonFormField(
                value: _cropType,
                items: ["Paddy"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(t ? "ধান" : e)))
                    .toList(),
                onChanged: (v) => setState(() => _cropType = v!),
                decoration: InputDecoration(
                  labelText: t ? "ফসলের ধরন" : "Crop Type",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t ? "ওজন (কেজি)" : "Estimated Weight (kg)",
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? (t ? "প্রয়োজন" : "Required") : null,
              ),
              const SizedBox(height: 16),

              // Harvest Date
              ListTile(
                tileColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                title: Text(_harvestDate == null
                    ? (t ? "ফসল কাটার তারিখ নির্বাচন করুন" : "Select Harvest Date")
                    : "${_harvestDate!.year}-${_harvestDate!.month}-${_harvestDate!.day}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2022),
                    lastDate: DateTime.now(),
                    initialDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _harvestDate = picked);
                },
              ),
              const SizedBox(height: 16),

              // Division
              DropdownButtonFormField(
                value: _division,
                items: _locations.keys
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _division = v!;
                    _district = _locations[v]!.first;
                  });
                },
                decoration: InputDecoration(
                  labelText: t ? "বিভাগ" : "Division",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // District
              DropdownButtonFormField(
                value: _district,
                items: _locations[_division]!
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _district = v!),
                decoration: InputDecoration(
                  labelText: t ? "জেলা" : "District",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Storage type
              DropdownButtonFormField(
                value: _storageType,
                items: ["Jute Bag Stack", "Silo", "Open Area"]
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(t
                            ? (e == "Jute Bag Stack"
                                ? "পাটের বস্তা স্ট্যাক"
                                : e == "Silo"
                                    ? "সাইলো"
                                    : "খোলা এলাকা")
                            : e)))
                    .toList(),
                onChanged: (v) => setState(() => _storageType = v!),
                decoration: InputDecoration(
                  labelText: t ? "সংরক্ষণের ধরন" : "Storage Type",
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitBatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white, // ensures text is visible
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(t ? "ব্যাচ সংরক্ষণ করুন" : "Save Batch"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
