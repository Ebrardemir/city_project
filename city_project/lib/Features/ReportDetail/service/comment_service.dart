import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/comment_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<CommentModel>> getComments(String reportId) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['reportId'] = reportId;
        return CommentModel.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ CommentService: Yorumlar alınırken hata: $e');
      return [];
    }
  }

  Future<bool> addComment(String reportId, String message) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Kullanıcı adını al
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final fullName = userDoc.data()?['fullName'] ?? 'Anonim';

      await _firestore
          .collection('reports')
          .doc(reportId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userFullName': fullName,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('❌ CommentService: Yorum eklenirken hata: $e');
      return false;
    }
  }
}
