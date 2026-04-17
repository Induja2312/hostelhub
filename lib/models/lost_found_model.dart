import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundModel {
  final String id;
  final String reportedBy;
  final String reporterName;
  final String contactInfo;
  final String category;
  final String itemName;
  final String description;
  final String location;
  final String status; // "open" | "with_warden" | "collected"
  final String imageUrl;
  final DateTime? dateLost;
  final String? wardenNote; // note from warden when marking found
  final DateTime createdAt;

  LostFoundModel({
    required this.id,
    required this.reportedBy,
    required this.reporterName,
    required this.contactInfo,
    required this.category,
    required this.itemName,
    required this.description,
    required this.location,
    required this.status,
    required this.imageUrl,
    this.dateLost,
    this.wardenNote,
    required this.createdAt,
  });

  factory LostFoundModel.fromMap(Map<String, dynamic> map, String id) {
    return LostFoundModel(
      id: id,
      reportedBy: map['reportedBy'] ?? '',
      reporterName: map['reporterName'] ?? '',
      contactInfo: map['contactInfo'] ?? '',
      category: map['category'] ?? 'Other',
      itemName: map['itemName'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'open',
      imageUrl: map['imageUrl'] ?? '',
      dateLost: (map['dateLost'] as Timestamp?)?.toDate(),
      wardenNote: map['wardenNote'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'contactInfo': contactInfo,
      'category': category,
      'itemName': itemName,
      'description': description,
      'location': location,
      'status': status,
      'imageUrl': imageUrl,
      'dateLost': dateLost != null ? Timestamp.fromDate(dateLost!) : null,
      'wardenNote': wardenNote,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
