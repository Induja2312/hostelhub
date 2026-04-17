import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  FirebaseFirestore get db => _db;

  Future<void> addDocument(String collection, Map<String, dynamic> data) async {
    await _db.collection(collection).add(data);
  }

  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    await _db.collection(collection).doc(docId).update(data);
  }

  Future<void> deleteDocument(String collection, String docId) async {
    await _db.collection(collection).doc(docId).delete();
  }

  Stream<QuerySnapshot> getCollectionStream(String collection) {
    return _db.collection(collection).snapshots();
  }

  Stream<QuerySnapshot> getCollectionStreamOrdered(String collection, String orderBy, {bool descending = false}) {
    return _db.collection(collection).orderBy(orderBy, descending: descending).snapshots();
  }
  
  Stream<QuerySnapshot> getCollectionStreamFiltered(String collection, String field, dynamic isEqualTo) {
    return _db.collection(collection).where(field, isEqualTo: isEqualTo).snapshots();
  }
}
