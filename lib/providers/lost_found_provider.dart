import 'package:flutter/material.dart';
import '../models/lost_found_model.dart';
import '../services/firestore_service.dart';

class LostFoundProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _collection = 'lost_found';

  LostFoundProvider(this._firestoreService);

  Stream<List<LostFoundModel>> getItemsStream() {
    return _firestoreService.db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LostFoundModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addItem(LostFoundModel item) async {
    await _firestoreService.addDocument(_collection, item.toMap());
  }

  // Warden: someone handed in the item
  Future<void> markWithWarden(String docId, String wardenNote) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': 'with_warden',
      'wardenNote': wardenNote,
    });
  }

  // Warden: student collected the item
  Future<void> markCollected(String docId) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': 'collected',
    });
  }

  Future<void> deleteItem(String docId) async {
    await _firestoreService.db.collection(_collection).doc(docId).delete();
  }
}
