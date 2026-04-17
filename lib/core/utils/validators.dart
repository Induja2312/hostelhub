import 'package:cloud_firestore/cloud_firestore.dart';

const _boysBlocks = ['A', 'B', 'C', 'D', 'G1', 'G2', 'Annex'];
const _girlsBlocks = ['L', 'M', 'N', 'K', 'Q', 'E'];

// sharing capacity per block
const _girlsSharing = {'L': 4, 'M': 2, 'N': 6, 'K': 2, 'Q': 3, 'E': 2};

List<String> blocksForGender(String gender) =>
    gender == 'boys' ? _boysBlocks : _girlsBlocks;

int? sharingForBlock(String block) => _girlsSharing[block];

/// Returns room numbers for a given block and gender.
/// Format: floor(1-4) + 2-digit room(00-20) e.g. "101", "220"
List<String> roomsForBlock(String block) {
  final rooms = <String>[];
  for (int floor = 1; floor <= 4; floor++) {
    for (int room = 0; room <= 20; room++) {
      rooms.add('$floor${room.toString().padLeft(2, '0')}');
    }
  }
  return rooms;
}

class Validators {
  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? email(String? value, {String role = 'student'}) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final trimmed = value.trim().toLowerCase();
    if (!trimmed.endsWith('@psgtech.ac.in')) {
      return 'Only @psgtech.ac.in email addresses are allowed';
    }
    if (role == 'student') {
      final match = RegExp(r'^25mx(\d+)@psgtech\.ac\.in$').firstMatch(trimmed);
      if (match == null) return 'Student email must be in format 25mxNNN@psgtech.ac.in';
      final num = int.parse(match.group(1)!);
      if (num < 100 || num > 363) return 'Student roll number must be between 100 and 363';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  static String? room(String? value) {
    if (value == null || value.trim().isEmpty) return 'Room number is required';
    return null;
  }

  static String? block(String? value) {
    if (value == null || value.trim().isEmpty) return 'Block is required';
    return null;
  }

  /// Check uniqueness of email and phone in Firestore
  static Future<String?> checkEmailUnique(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return 'This email is already registered';
    return null;
  }

  static Future<String?> checkPhoneUnique(String phone) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('phone', isEqualTo: phone.trim())
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return 'This phone number is already registered';
    return null;
  }

  /// Check if room has reached sharing capacity
  static Future<String?> checkRoomCapacity(
      String block, String room, String gender) async {
    final capacity = sharingForBlock(block);
    if (capacity == null) return null; // boys blocks have no fixed sharing
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('hostelBlock', isEqualTo: block)
        .where('roomNumber', isEqualTo: room)
        .get();
    if (snap.docs.length >= capacity) {
      return 'Room $block-$room is full ($capacity/$capacity sharing)';
    }
    return null;
  }
}
