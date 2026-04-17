import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource_model.dart';
import '../services/firestore_service.dart';

class ResourceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _collection = 'resources';

  ResourceProvider(this._firestoreService);

  Stream<List<ResourceModel>> getResourcesStream() {
    return _firestoreService.db
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ResourceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addRequest(ResourceModel resource) async {
    await _firestoreService.addDocument(_collection, resource.toMap());
  }

  Future<void> offerItem(String docId, String offererId, String offererName,
      String meetingLocation, DateTime meetingTime) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': 'offered',
      'offererId': offererId,
      'offererName': offererName,
      'meetingLocation': meetingLocation,
      'meetingTime': Timestamp.fromDate(meetingTime),
    });
  }

  Future<void> markFulfilled(String docId) async {
    await _firestoreService.updateDocument(_collection, docId, {'status': 'fulfilled'});
  }

  Future<void> cancelRequest(String docId) async {
    await _firestoreService.updateDocument(_collection, docId, {'status': 'cancelled'});
  }
}
