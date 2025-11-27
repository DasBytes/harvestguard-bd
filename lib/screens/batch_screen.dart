import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:harvestguard_bd/screens/profile_screen.dart';

class CropBatchRegistrationScreen extends StatefulWidget {
  final bool isBangla;

  const CropBatchRegistrationScreen({super.key, required this.isBangla});

  @override
  State<CropBatchRegistrationScreen> createState() =>
      _CropBatchRegistrationScreenState();
}

class _CropBatchRegistrationScreenState
    extends State<CropBatchRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _cropType = "Paddy";
  String _storageType = "Jute Bag Stack";
  String _division = "Dhaka";
  String _district = "Dhaka";
  DateTime? _harvestDate;

  final _weightController = TextEditingController();

  final Map<String, List<String>> _locations = {
    "Dhaka": ["Dhaka", "Gazipur"],
    "Chattogram": ["Chattogram", "Cox's Bazar"],
    "Rajshahi": ["Rajshahi", "Natore"],
  };

  Future<void> _submitBatch() async {
    if (!_formKey.currentState!.validate() || _harvestDate == null) return;

    final batch = {
      "crop": _cropType,
      "weight": _weightController.text,
      "date": _harvestDate.toString().split(" ")[0],
      "location": "$_division - $_district",
      "storage": _storageType,
      "timestamp": FieldValue.serverTimestamp(),
    };

    try {
      // Save batch to Firestore
      await _firestore.collection('crop_batches').add(batch);

      // Navigate to ProfileScreen with the latest batch
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            isBangla: widget.isBangla,
            latestBatch: batch.map((key, value) => MapEntry(key, value.toString())),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error saving batch: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isBangla
              ? "ব্যাচ সংরক্ষণে সমস্যা হয়েছে"
              : "Failed to save batch"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isBangla;
    final primaryColor = const Color(0xFF2E7D32);

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
              // Crop Type
              DropdownButtonFormField(
                value: _cropType,
                items: ["Paddy"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _cropType = v!),
                decoration: InputDecoration(
                  labelText: t ? "ফসলের ধরন" : "Crop Type",
                ),
              ),
              const SizedBox(height: 16),

              // Weight
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t ? "ওজন (কেজি)" : "Estimated Weight (kg)",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Harvest Date
              ListTile(
                title: Text(_harvestDate == null
                    ? (t ? "ফসল কাটার তারিখ নির্বাচন করুন" : "Select Harvest Date")
                    : _harvestDate.toString().split(" ")[0]),
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
                ),
              ),
              const SizedBox(height: 16),

              // Storage Type
              DropdownButtonFormField(
                value: _storageType,
                items: ["Jute Bag Stack", "Silo", "Open Area"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _storageType = v!),
                decoration: InputDecoration(
                  labelText: t ? "সংরক্ষণের ধরন" : "Storage Type",
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitBatch,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: Text(t ? "ব্যাচ সংরক্ষণ করুন" : "Save Batch"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
