import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMessageBoard(String boardId, String boardName) async {
    await _firestore.collection('messageBoards').doc(boardId).set({
      'name': boardName,
    });
  }

  Future<void> addMessage(String boardId, String username, String message) async {
    await _firestore
        .collection('messageBoards')
        .doc(boardId)
        .collection('messages')
        .add({
      'username': username,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getMessageBoards() async {
    final snapshot = await _firestore.collection('messageBoards').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Stream<List<Map<String, dynamic>>> getMessages(String boardId) {
    return _firestore
        .collection('messageBoards')
        .doc(boardId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}
