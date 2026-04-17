import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/medical_visit_model.dart';

class MedicalProvider extends ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('medical_visits');

  Stream<List<MedicalVisitModel>> getAllVisitsStream() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (s) => s.docs.map((d) => MedicalVisitModel.fromMap(d.data(), d.id)).toList(),
        );
  }

  Stream<List<MedicalVisitModel>> getStudentVisitsStream(String studentId) {
    return _col.where('studentId', isEqualTo: studentId).snapshots().map((s) {
      final list = s.docs.map((d) => MedicalVisitModel.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> acceptVisit(String id, String instruction, DateTime appointmentTime) async {
    await _col.doc(id).update({
      'status': 'accepted',
      'doctorInstruction': instruction,
      'appointmentTime': Timestamp.fromDate(appointmentTime),
    });
  }

  Future<void> completeVisit(String id, String instruction) async {
    await _col.doc(id).update({
      'status': 'completed',
      'doctorInstruction': instruction,
    });
  }

  Future<void> updateInstruction(String id, String instruction, DateTime? appointmentTime) async {
    final data = <String, dynamic>{'doctorInstruction': instruction};
    if (appointmentTime != null) data['appointmentTime'] = Timestamp.fromDate(appointmentTime);
    await _col.doc(id).update(data);
  }
}
