import 'dart:math';

class BatchModel {
  final String id;
  final String cropName;
  final double quantity;
  final double moisture;
  final double temperature;
  final String riskLevel;
  final String advisory;
  final String iconUrl;

  BatchModel({
    required this.id,
    required this.cropName,
    required this.quantity,
    required this.moisture,
    required this.temperature,
    required this.riskLevel,
    required this.advisory,
    required this.iconUrl,
  });
}

final List<BatchModel> mockBatches = [
  BatchModel(
    id: '1',
    cropName: 'ধান (Rice - IRRI)',
    quantity: 1500,
    moisture: 14.5,
    temperature: 28.0,
    riskLevel: 'উচ্চ ঝুঁকি',
    advisory: 'তাত্ক্ষণিক বায়ু চলাচল নিশ্চিত করুন।',
    iconUrl: 'https://picsum.photos/id/1084/200/200',
  ),

  BatchModel(
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

Map<String, String> calculateAdvisory({
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
