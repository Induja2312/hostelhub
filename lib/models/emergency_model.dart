import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyModel {
  final String id;
  final String sentBy;
  final String senderName;
  final String roomNumber;
  final String message;
  final String status; // "active" | "resolved"
  final DateTime createdAt;

  EmergencyModel({
    required this.id,
    required this.sentBy,
    required this.senderName,
    required this.roomNumber,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory EmergencyModel.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyModel(
      id: id,
      sentBy: map['sentBy'] ?? '',
      senderName: map['senderName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sentBy': sentBy,
      'senderName': senderName,
      'roomNumber': roomNumber,
      'message': message,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
