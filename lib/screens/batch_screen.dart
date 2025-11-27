import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math';
import 'package:harvestguard_bd/models/batch_model.dart' as model;
import 'package:harvestguard_bd/widgets/batch_card.dart' as card_widget;

List<model.BatchModel> mockBatches = [
  model.BatchModel(
    id: '1',
    cropName: 'ধান (Rice - IRRI)',
    quantity: 1500,
    moisture: 14.5,
    temperature: 28.0,
    riskLevel: 'উচ্চ ঝুঁকি',
    advisory: 'তাত্ক্ষণিক বায়ু চলাচল নিশ্চিত করুন।',
    iconUrl: 'https://picsum.photos/id/1084/200/200',
  ),
  model.BatchModel(
    id: '2',
    cropName: 'মটর (Pulse - Moong)',
    quantity: 500,
    moisture: 12.0,
    temperature: 25.0,
    riskLevel: 'স্বল্প ঝুঁকি',
    advisory: 'নিয়মিত তাপমাত্রা পর্যবেক্ষণ করুন।',
    iconUrl: 'https://picsum.photos/id/1033/200/200',
  ),
];

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  Map<String, String> _calculateAdvisory({
    required double moisture,
    required double temperature,
  }) {
    String riskLevel;
    String advisory;

    if (moisture > 14.0 || temperature > 30.0) {
      riskLevel = 'উচ্চ ঝুঁকি';
      advisory = 'অবিলম্বে শস্য পরীক্ষা করুন এবং আর্দ্রতা কমানোর ব্যবস্থা নিন।';
    } else if (moisture > 13.0 || temperature > 27.0) {
      riskLevel = 'মাঝারি ঝুঁকি';
      advisory = 'ঘন ঘন পর্যবেক্ষণ প্রয়োজন, কৃত্রিম বায়ু চলাচল নিশ্চিত করুন।';
    } else {
      riskLevel = 'স্বল্প ঝুঁকি';
      advisory = 'স্টোরেজ পরিস্থিতি সন্তোষজনক।';
    }

    return {'riskLevel': riskLevel, 'advisory': advisory};
  }

  void _addNewBatch({
    required String cropName,
    required double quantity,
    required double moisture,
    required double temperature,
  }) {
    final advisory = _calculateAdvisory(
      moisture: moisture,
      temperature: temperature,
    );

    final iconUrl =
        cropName.toLowerCase().contains('ধান')
            ? 'https://picsum.photos/id/1084/200/200'
            : 'https://picsum.photos/id/1033/200/200';

    final newBatch = model.BatchModel(
      id: Random().nextInt(1000).toString(),
      cropName: cropName,
      quantity: quantity,
      moisture: moisture,
      temperature: temperature,
      riskLevel: advisory['riskLevel']!,
      advisory: advisory['advisory']!,
      iconUrl: iconUrl,
    );

    setState(() {
      mockBatches.add(newBatch);
    });
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, [
    TextInputType keyboardType = TextInputType.text,
  ]) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      ),
    );
  }

  void _showAddBatchForm(BuildContext context) {
    final cropNameController = TextEditingController(text: 'গম');
    final quantityController = TextEditingController(text: '800');
    final moistureController = TextEditingController(text: '15.2');
    final temperatureController = TextEditingController(text: '31.5');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20.w,
              right: 20.w,
              top: 30.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'নতুন শস্য ব্যাচের তথ্য',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildTextField(
                  'শস্যের নাম (যেমন: ধান, গম)',
                  cropNameController,
                ),
                _buildTextField(
                  'পরিমাণ (কেজি/টন)',
                  quantityController,
                  TextInputType.number,
                ),
                _buildTextField(
                  'আর্দ্রতা (%)',
                  moistureController,
                  TextInputType.number,
                ),
                _buildTextField(
                  'বর্তমান তাপমাত্রা (সেলসিয়াস)',
                  temperatureController,
                  TextInputType.number,
                ),
                SizedBox(height: 30.h),
                ElevatedButton(
                  onPressed: () {
                    final qText = quantityController.text.trim();
                    final mText = moistureController.text.trim();
                    final tText = temperatureController.text.trim();

                    try {
                      _addNewBatch(
                        cropName:
                            cropNameController.text.trim().isEmpty
                                ? 'অজানা শস্য'
                                : cropNameController.text.trim(),
                        quantity: double.parse(qText),
                        moisture: double.parse(mText),
                        temperature: double.parse(tText),
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'নতুন ব্যাচ সফলভাবে যুক্ত হয়েছে। A4 ETCL গণনা সম্পন্ন!',
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'ত্রুটি: দয়া করে সংখ্যাগুলি সঠিকভাবে লিখুন।',
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'ব্যাচ সংরক্ষণ করুন',
                    style: TextStyle(fontSize: 18.sp, color: Colors.white),
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
    ).whenComplete(() {
      cropNameController.dispose();
      quantityController.dispose();
      moistureController.dispose();
      temperatureController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'শস্যের ব্যাচ ইনভেন্টরি (A3)',
          style: TextStyle(fontSize: 18.sp),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBatchForm(context),
          ),
        ],
      ),
      body:
          mockBatches.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 80.sp,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'কোনো ব্যাচ যোগ করা হয়নি।',
                      style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                    ),
                    Text(
                      'নতুন ব্যাচ যোগ করতে নিচে ক্লিক করুন।',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: mockBatches.length,
                itemBuilder: (context, index) {
                  final batch = mockBatches[index];

                  return card_widget.BatchCard(
                    batch: card_widget.BatchModel(
                      id: batch.id,
                      cropName: batch.cropName,
                      quantity: batch.quantity,
                      moisture: batch.moisture,
                      temperature: batch.temperature,
                      riskLevel: batch.riskLevel,
                      advisory: batch.advisory,
                      iconUrl: batch.iconUrl,
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBatchForm(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'নতুন ব্যাচ যোগ করুন',
          style: TextStyle(fontSize: 16.sp, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
