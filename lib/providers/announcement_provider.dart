import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../services/firestore_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  final String _collection = 'announcements';

  AnnouncementProvider(this._firestoreService);

  Stream<List<AnnouncementModel>> getAnnouncementsStream() {
    return _firestoreService.getCollectionStreamOrdered(_collection, 'createdAt', descending: true)
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnouncementModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> addAnnouncement(AnnouncementModel announcement) async {
    await _firestoreService.addDocument(_collection, announcement.toMap());
  }

  Future<void> deleteAnnouncement(String docId) async {
    await _firestoreService.deleteDocument(_collection, docId);
  }
}
