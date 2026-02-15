import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Home/model/report_model.dart';

class MyReportsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<ReportModel>> fetchMyReports() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      print('📥 MyReportsService: Kullanıcı raporları çekiliyor (${user.uid})...');

      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final reports = snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return ReportModel.fromJson(data);
        } catch (e) {
          print('❌ MyReportsService: Parse hatası (${doc.id}): $e');
          return null;
        }
      }).whereType<ReportModel>().toList();

      print('✅ MyReportsService: ${reports.length} rapor başarıyla yüklendi.');
      return reports;
    } catch (e) {
      print('❌ MyReportsService: Hata: $e');
      // İndex hatası olabilir, ona özel mesaj
      if (e.toString().contains('failed-precondition')) {
        print('⚠️ İndex hatası: Lütfen Firestore konsoldan gerekli indexi oluşturun.');
        // Fallback: Client-side sorting
        return await _fetchWithoutIndex();
      }
      return [];
    }
  }

  // İndex yoksa sıralamasız çekip client-side sırala
  Future<List<ReportModel>> _fetchWithoutIndex() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('userId', isEqualTo: user.uid)
          .get();

      final reports = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ReportModel.fromJson(data);
      }).toList();

      // Client-side sıralama
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return reports;
    } catch (e) {
      print('❌ MyReportsService Fallback Hata: $e');
      return [];
    }
  }
}
