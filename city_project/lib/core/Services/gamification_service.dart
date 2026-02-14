import 'package:cloud_firestore/cloud_firestore.dart';

/// Oyunlaştırma (Gamification) Servisi
/// Kullanıcılara puan kazandırma, liderlik tablosu vb. işlemler
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Puan Kuralları
  static const int pointsCreateReport = 10;
  static const int pointsReportResolved = 25;
  static const int pointsSupportReport = 5;
  static const int pointsFakeReportPenalty = -20;
  static const int pointsReportApproved = 5;
  
  /// Kullanıcıya puan ekler
  /// 
  /// [userId]: Puan eklenecek kullanıcının ID'si
  /// [points]: Eklenecek puan (negatif olabilir)
  /// [action]: Puan kazanma nedeni (log için)
  /// [reportId]: İlişkili rapor ID'si (opsiyonel)
  /// 
  /// Returns: İşlem başarılı ise true
  Future<bool> addPoints({
    required String userId,
    required int points,
    required String action,
    String? reportId,
  }) async {
    try {
      print('🎮 Gamification: Puan ekleniyor...');
      print('   👤 Kullanıcı: $userId');
      print('   ⭐ Puan: ${points > 0 ? "+$points" : points}');
      print('   📝 Aksiyon: $action');
      
      // 1. Kullanıcı puanını güncelle
      final userRef = _firestore.collection('users').doc(userId);
      await userRef.update({
        'score': FieldValue.increment(points),
      });
      
      // 2. Gamification log'a kayıt ekle
      await _firestore.collection('gamificationLog').add({
        'userId': userId,
        'action': action,
        'points': points,
        'reportId': reportId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Gamification: Puan başarıyla eklendi');
      
      // TODO: Kullanıcıya bildirim gönder
      // TODO: Badge kontrolü yap (100, 500, 1000, 5000 puan)
      
      return true;
    } catch (e) {
      print('❌ Gamification: Puan ekleme hatası: $e');
      return false;
    }
  }
  
  /// Rapor oluşturulduğunda puan ekle
  Future<bool> onReportCreated(String userId, String reportId) async {
    return await addPoints(
      userId: userId,
      points: pointsCreateReport,
      action: 'create_report',
      reportId: reportId,
    );
  }
  
  /// Rapor çözüldüğünde raporlayan kullanıcıya puan ekle
  Future<bool> onReportResolved(String reporterId, String reportId) async {
    return await addPoints(
      userId: reporterId,
      points: pointsReportResolved,
      action: 'report_resolved',
      reportId: reportId,
    );
  }
  
  /// Rapor onaylandığında puan ekle
  Future<bool> onReportApproved(String reporterId, String reportId) async {
    return await addPoints(
      userId: reporterId,
      points: pointsReportApproved,
      action: 'report_approved',
      reportId: reportId,
    );
  }
  
  /// Rapora destek verildiğinde puan ekle
  Future<bool> onReportSupported(String supporterId, String reportId) async {
    return await addPoints(
      userId: supporterId,
      points: pointsSupportReport,
      action: 'support_report',
      reportId: reportId,
    );
  }
  
  /// Sahte rapor için ceza puanı
  Future<bool> onFakeReportDetected(String userId, String reportId) async {
    return await addPoints(
      userId: userId,
      points: pointsFakeReportPenalty,
      action: 'fake_report',
      reportId: reportId,
    );
  }
  
  /// Liderlik tablosunu getirir (en yüksek puanlı kullanıcılar)
  /// 
  /// [limit]: Kaç kullanıcı getirileceği (varsayılan: 50)
  /// 
  /// Returns: Kullanıcı listesi (id, fullName, score, rank)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 50}) async {
    try {
      print('🏆 Gamification: Liderlik tablosu yükleniyor...');
      
      final snapshot = await _firestore
          .collection('users')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();
      
      final leaderboard = <Map<String, dynamic>>[];
      int rank = 1;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        leaderboard.add({
          'id': doc.id,
          'fullName': data['fullName'] ?? 'Anonim',
          'score': data['score'] ?? 0,
          'rank': rank,
          'city': data['city'],
          'role': data['role'] ?? 'citizen',
        });
        rank++;
      }
      
      print('✅ Gamification: ${leaderboard.length} kullanıcı yüklendi');
      return leaderboard;
    } catch (e) {
      print('❌ Gamification: Liderlik tablosu hatası: $e');
      return [];
    }
  }
  
  /// Kullanıcının sıralamasını getirir
  /// 
  /// [userId]: Kullanıcı ID'si
  /// 
  /// Returns: Kullanıcının sıralaması (rank), bulunamazsa null
  Future<int?> getUserRank(String userId) async {
    try {
      // Kullanıcının puanını al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userScore = userDoc.data()?['score'] ?? 0;
      
      // Kullanıcıdan daha yüksek puanlı kaç kişi var?
      final higherScoresCount = await _firestore
          .collection('users')
          .where('score', isGreaterThan: userScore)
          .count()
          .get();
      
      final rank = (higherScoresCount.count ?? 0) + 1;
      
      print('✅ Gamification: Kullanıcı sıralaması: $rank');
      return rank;
    } catch (e) {
      print('❌ Gamification: Sıralama hesaplama hatası: $e');
      return null;
    }
  }
  
  /// Kullanıcının rozetini belirler (puana göre)
  /// 
  /// [score]: Kullanıcının puanı
  /// 
  /// Returns: Rozet bilgisi (name, icon, color)
  Map<String, dynamic> getBadge(int score) {
    if (score >= 5000) {
      return {
        'name': 'Elmas',
        'icon': '💎',
        'level': 4,
        'color': 0xFF00BCD4, // Cyan
      };
    } else if (score >= 1000) {
      return {
        'name': 'Altın',
        'icon': '🥇',
        'level': 3,
        'color': 0xFFFFD700, // Gold
      };
    } else if (score >= 500) {
      return {
        'name': 'Gümüş',
        'icon': '🥈',
        'level': 2,
        'color': 0xFFC0C0C0, // Silver
      };
    } else if (score >= 100) {
      return {
        'name': 'Bronz',
        'icon': '🥉',
        'level': 1,
        'color': 0xFFCD7F32, // Bronze
      };
    } else {
      return {
        'name': 'Yeni Başlayan',
        'icon': '🌱',
        'level': 0,
        'color': 0xFF4CAF50, // Green
      };
    }
  }
  
  /// Sonraki rozete kalan puan
  /// 
  /// [score]: Kullanıcının puanı
  /// 
  /// Returns: Sonraki rozete kalan puan
  int getPointsToNextBadge(int score) {
    if (score < 100) {
      return 100 - score;
    } else if (score < 500) {
      return 500 - score;
    } else if (score < 1000) {
      return 1000 - score;
    } else if (score < 5000) {
      return 5000 - score;
    } else {
      return 0; // Maksimum seviye
    }
  }
  
  /// Kullanıcının gamification istatistiklerini getirir
  /// 
  /// [userId]: Kullanıcı ID'si
  /// 
  /// Returns: İstatistikler (toplam puan kazanılan, kaybedilen vb.)
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('gamificationLog')
          .where('userId', isEqualTo: userId)
          .get();
      
      int totalPointsEarned = 0;
      int totalPointsLost = 0;
      int reportCount = 0;
      int supportCount = 0;
      
      for (var doc in snapshot.docs) {
        final points = doc.data()['points'] ?? 0;
        final action = doc.data()['action'] ?? '';
        
        if (points > 0) {
          totalPointsEarned += points as int;
        } else {
          totalPointsLost += (points as int).abs();
        }
        
        if (action == 'create_report') reportCount++;
        if (action == 'support_report') supportCount++;
      }
      
      // Kullanıcının mevcut puanını al
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final currentScore = userDoc.data()?['score'] ?? 0;
      
      return {
        'currentScore': currentScore,
        'totalPointsEarned': totalPointsEarned,
        'totalPointsLost': totalPointsLost,
        'reportCount': reportCount,
        'supportCount': supportCount,
        'badge': getBadge(currentScore),
        'pointsToNextBadge': getPointsToNextBadge(currentScore),
      };
    } catch (e) {
      print('❌ Gamification: Kullanıcı istatistikleri hatası: $e');
      return {};
    }
  }
}
