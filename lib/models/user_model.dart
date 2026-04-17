import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // "student" | "warden" | "admin"
  final String roomNumber;
  final String hostelBlock;
  final String phone;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.roomNumber,
    required this.hostelBlock,
    required this.phone,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      roomNumber: map['roomNumber'] ?? '',
      hostelBlock: map['hostelBlock'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'roomNumber': roomNumber,
      'hostelBlock': hostelBlock,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
