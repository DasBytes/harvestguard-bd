import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/batch_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveBatch(CropBatch batch, String userId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('batches')
        .doc(batch.id)
        .set(batch.toMap());
  }

  Stream<List<CropBatch>> getBatches(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('batches')
        .orderBy('harvestDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CropBatch.fromMap(doc.data())).toList());
  }
}
