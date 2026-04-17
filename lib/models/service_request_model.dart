import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNumber;
  final String serviceType; // "cleaning" | "repair" | "plumbing" | "electrical"
  final String description;
  final String status; // "pending" | "assigned" | "completed"
  final String assignedStaff;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  ServiceRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomNumber,
    required this.serviceType,
    required this.description,
    required this.status,
    required this.assignedStaff,
    this.scheduledTime,
    required this.createdAt,
  });

  factory ServiceRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceRequestModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      serviceType: map['serviceType'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      assignedStaff: map['assignedStaff'] ?? '',
      scheduledTime: map['scheduledTime'] != null ? (map['scheduledTime'] as Timestamp).toDate() : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'roomNumber': roomNumber,
      'serviceType': serviceType,
      'description': description,
      'status': status,
      'assignedStaff': assignedStaff,
      'scheduledTime': scheduledTime != null ? Timestamp.fromDate(scheduledTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
