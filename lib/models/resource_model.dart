import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String itemName;
  final String description;
  final DateTime neededBy;
  final String status; // "open" | "offered" | "fulfilled"
  final String? offererId;
  final String? offererName;
  final String? meetingLocation;
  final DateTime? meetingTime;
  final DateTime createdAt;

  ResourceModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.itemName,
    required this.description,
    required this.neededBy,
    required this.status,
    this.offererId,
    this.offererName,
    this.meetingLocation,
    this.meetingTime,
    required this.createdAt,
  });

  factory ResourceModel.fromMap(Map<String, dynamic> map, String id) {
    return ResourceModel(
      id: id,
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      itemName: map['itemName'] ?? '',
      description: map['description'] ?? '',
      neededBy: (map['neededBy'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'open',
      offererId: map['offererId'],
      offererName: map['offererName'],
      meetingLocation: map['meetingLocation'],
      meetingTime: (map['meetingTime'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'itemName': itemName,
      'description': description,
      'neededBy': Timestamp.fromDate(neededBy),
      'status': status,
      'offererId': offererId,
      'offererName': offererName,
      'meetingLocation': meetingLocation,
      'meetingTime': meetingTime != null ? Timestamp.fromDate(meetingTime!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
