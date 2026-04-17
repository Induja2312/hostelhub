import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final DateTime sentAt;

  ComplaintMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.sentAt,
  });

  factory ComplaintMessage.fromMap(Map<String, dynamic> map, String id) {
    return ComplaintMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? 'student',
      text: map['text'] ?? '',
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
      };
}
