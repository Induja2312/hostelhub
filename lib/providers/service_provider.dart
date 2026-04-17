import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_request_model.dart';
import '../services/firestore_service.dart';

class ServiceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _collection = 'service_requests';

  ServiceProvider(this._firestoreService);

  Stream<List<ServiceRequestModel>> getStudentServices(String studentId) {
    return _firestoreService.db
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => ServiceRequestModel.fromMap(doc.data(), doc.id))
              .toList();
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  Future<void> assignService(String docId, String staff, DateTime scheduledTime) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': 'assigned',
      'assignedStaff': staff,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
    });
  }

  Stream<List<ServiceRequestModel>> getAllServices() {
    return _firestoreService.getCollectionStreamOrdered(_collection, 'createdAt', descending: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceRequestModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addServiceRequest(ServiceRequestModel service) async {
    await _firestoreService.addDocument(_collection, service.toMap());
  }

  Future<void> updateServiceStatus(String docId, String status) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': status,
    });
  }
}
