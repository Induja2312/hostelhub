import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String studentId;
  final String studentName;
  final String category; // "electricity" | "water" | "wifi" | "furniture" | "other"
  final String description;
  final String status; // "pending" | "in_progress" | "resolved"
  final String assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  ComplaintModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.category,
    required this.description,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      assignedTo: map['assignedTo'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'category': category,
      'description': description,
      'status': status,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
