import 'package:hive/hive.dart';
import '../models/batch_model.dart';

class LocalStorageService {
  final String boxName = 'crop_batches';

  Future<void> saveBatch(CropBatch batch) async {
    var box = await Hive.openBox(boxName);
    await box.put(batch.id, batch.toMap());
  }

  Future<List<CropBatch>> getBatches() async {
    var box = await Hive.openBox(boxName);
    return box.values
        .map((e) => CropBatch.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> deleteBatch(String id) async {
    var box = await Hive.openBox(boxName);
    await box.delete(id);
  }
}
