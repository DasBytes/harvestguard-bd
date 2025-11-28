import 'firestore_service.dart';
import '../services/offline_service.dart';
import '../models/batch_model.dart';

class SyncService {
  final FirestoreService _firestoreService = FirestoreService();
  final LocalStorageService _localStorageService = LocalStorageService();

  Future<void> syncBatches(String userId) async {
    final offlineBatches = await _localStorageService.getBatches();

    for (var batch in offlineBatches) {
      if (!batch.synced) {
        await _firestoreService.saveBatch(batch, userId);
        await _localStorageService.deleteBatch(batch.id);
      }
    }
  }
}
