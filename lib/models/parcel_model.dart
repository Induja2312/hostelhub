import 'package:cloud_firestore/cloud_firestore.dart';

class ParcelModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNumber;
  final String senderName;
  final String courierName;
  final String trackingNumber;
  final String status;
  final String imageUrl;
  final DateTime arrivedAt;
  final DateTime? collectedAt;

  ParcelModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomNumber,
    required this.senderName,
    required this.courierName,
    required this.trackingNumber,
    required this.status,
    this.imageUrl = '',
    required this.arrivedAt,
    this.collectedAt,
  });

  factory ParcelModel.fromMap(Map<String, dynamic> map, String id) {
    return ParcelModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      senderName: map['senderName'] ?? '',
      courierName: map['courierName'] ?? '',
      trackingNumber: map['trackingNumber'] ?? '',
      status: map['status'] ?? 'arrived',
      imageUrl: map['imageUrl'] ?? '',
      arrivedAt: (map['arrivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      collectedAt: map['collectedAt'] != null ? (map['collectedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'roomNumber': roomNumber,
      'senderName': senderName,
      'courierName': courierName,
      'trackingNumber': trackingNumber,
      'status': status,
      'imageUrl': imageUrl,
      'arrivedAt': Timestamp.fromDate(arrivedAt),
      'collectedAt': collectedAt != null ? Timestamp.fromDate(collectedAt!) : null,
    };
  }
}
