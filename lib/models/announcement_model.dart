import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String postedBy;
  final String postedByName;
  final String title;
  final String body;
  final String priority; // "normal" | "urgent"
  final String imageUrl;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.postedBy,
    required this.postedByName,
    required this.title,
    required this.body,
    required this.priority,
    this.imageUrl = '',
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      priority: map['priority'] ?? 'normal',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postedBy': postedBy,
      'postedByName': postedByName,
      'title': title,
      'body': body,
      'priority': priority,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
