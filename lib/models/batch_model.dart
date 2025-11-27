class CropBatch {
  final String id;
  final String cropType;
  final double weight;
  final DateTime harvestDate;
  final String division;
  final String district;
  final String storageType;
  final bool synced; // for offline sync

  CropBatch({
    required this.id,
    required this.cropType,
    required this.weight,
    required this.harvestDate,
    required this.division,
    required this.district,
    required this.storageType,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropType': cropType,
      'weight': weight,
      'harvestDate': harvestDate.toIso8601String(),
      'division': division,
      'district': district,
      'storageType': storageType,
      'synced': synced,
    };
  }

  factory CropBatch.fromMap(Map<String, dynamic> map) {
    return CropBatch(
      id: map['id'] ?? '',
      cropType: map['cropType'] ?? '',
      weight: map['weight']?.toDouble() ?? 0.0,
      harvestDate: DateTime.parse(map['harvestDate']),
      division: map['division'] ?? '',
      district: map['district'] ?? '',
      storageType: map['storageType'] ?? '',
      synced: map['synced'] ?? false,
    );
  }
}
