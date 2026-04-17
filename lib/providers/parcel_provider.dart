import 'package:flutter/material.dart';
import '../models/parcel_model.dart';
import '../services/firestore_service.dart';

class ParcelProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _collection = 'parcels';

  ParcelProvider(this._firestoreService);

  Stream<List<ParcelModel>> getStudentParcels(String studentId) {
    return _firestoreService.db
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ParcelModel.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort((a, b) => b.arrivedAt.compareTo(a.arrivedAt));
          return docs;
        });
  }

  Stream<List<ParcelModel>> getAllParcels() {
    return _firestoreService.getCollectionStreamOrdered(_collection, 'arrivedAt', descending: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => ParcelModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addParcel(ParcelModel parcel) async {
    await _firestoreService.addDocument(_collection, parcel.toMap());
  }

  Future<void> markAsCollected(String docId) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': 'collected',
      'collectedAt': DateTime.now(),
    });
  }
}
