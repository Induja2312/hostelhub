import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalVisitModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNumber;
  final String symptoms;
  final String notes;
  final String urgency;
  final String status;
  final DateTime? preferredDate;
  final DateTime? appointmentTime;
  final String doctorInstruction;
  final DateTime createdAt;

  MedicalVisitModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomNumber,
    required this.symptoms,
    required this.notes,
    required this.urgency,
    required this.status,
    this.preferredDate,
    this.appointmentTime,
    required this.doctorInstruction,
    required this.createdAt,
  });

  factory MedicalVisitModel.fromMap(Map<String, dynamic> map, String id) {
    return MedicalVisitModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      symptoms: map['symptoms'] ?? '',
      notes: map['notes'] ?? '',
      urgency: map['urgency'] ?? 'normal',
      status: map['status'] ?? 'pending',
      preferredDate: (map['preferredDate'] as Timestamp?)?.toDate(),
      appointmentTime: (map['appointmentTime'] as Timestamp?)?.toDate(),
      doctorInstruction: map['doctorInstruction'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentId': studentId,
        'studentName': studentName,
        'roomNumber': roomNumber,
        'symptoms': symptoms,
        'notes': notes,
        'urgency': urgency,
        'status': status,
        'preferredDate': preferredDate != null ? Timestamp.fromDate(preferredDate!) : null,
        'appointmentTime': appointmentTime != null ? Timestamp.fromDate(appointmentTime!) : null,
        'doctorInstruction': doctorInstruction,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
