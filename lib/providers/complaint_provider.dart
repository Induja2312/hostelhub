import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint_model.dart';
import '../models/complaint_message_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _collection = 'complaints';

  ComplaintProvider(this._firestoreService);

  Stream<List<ComplaintModel>> getStudentComplaints(String studentId) {
    return _firestoreService.db
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Stream<List<ComplaintModel>> getAllComplaints() {
    return _firestoreService.db
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => ComplaintModel.fromMap(doc.data(), doc.id))
          .toList();
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    });
  }

  Future<void> addComplaint(ComplaintModel complaint) async {
    await _firestoreService.addDocument(_collection, complaint.toMap());
  }

  Future<void> updateComplaintStatus(String docId, String status, String studentId) async {
    await _firestoreService.updateDocument(_collection, docId, {
      'status': status,
      'updatedAt': Timestamp.now(),
    });

    // Show local notification for the student (works when app is open)
    final label = status == 'in_progress' ? 'In Progress' : 'Resolved';
    await NotificationService().showNotification(
      id: docId.hashCode,
      title: 'Complaint Update',
      body: 'Your complaint is now $label',
    );

    // Also write a notification doc so student sees it even if app was closed
    await _firestoreService.db.collection('notifications').add({
      'userId': studentId,
      'title': 'Complaint Update',
      'body': 'Your complaint status changed to $label',
      'createdAt': Timestamp.now(),
      'read': false,
    });
  }

  // Chat messages subcollection
  Stream<List<ComplaintMessage>> getMessages(String complaintId) {
    return _firestoreService.db
        .collection(_collection)
        .doc(complaintId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ComplaintMessage.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendMessage(String complaintId, ComplaintMessage message) async {
    await _firestoreService.db
        .collection(_collection)
        .doc(complaintId)
        .collection('messages')
        .add(message.toMap());
  }
}
