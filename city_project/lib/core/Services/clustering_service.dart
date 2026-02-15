import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Features/Home/model/report_model.dart';
import 'gamification_service.dart';

/// Akıllı gruplama servisi - Yakındaki benzer raporları tespit eder
/// Haversine formülü ile mesafe hesaplayarak aynı bölgedeki raporları birleştirir
class ClusteringService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Haversine formülü ile iki koordinat arasındaki mesafeyi hesaplar
  /// 
  /// [lat1], [lng1]: Birinci nokta koordinatları
  /// [lat2], [lng2]: İkinci nokta koordinatları
  /// 
  /// Returns: Metre cinsinden mesafe
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371000.0; // Dünya yarıçapı (metre)
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(_degreesToRadians(lat1)) * 
              cos(_degreesToRadians(lat2)) *
              sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }
  
  /// Dereceyi radyana çevirir
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
  
  /// Belirtilen koordinat ve kategoride yakın rapor olup olmadığını kontrol eder
  /// 
  /// [latitude], [longitude]: Kontrol edilecek koordinatlar
  /// [category]: Rapor kategorisi (aynı kategorideki raporlar kontrol edilir)
  /// [radiusMeters]: Yarıçap (metre) - varsayılan 20m
  /// 
  /// Returns: Eğer yakında rapor varsa o raporun ID'si, yoksa null
  Future<String?> checkNearbyReport({
    required double latitude,
    required double longitude,
    required String category,
    double radiusMeters = 20.0,
  }) async {
    try {
      print('🔍 Clustering: $category kategorisinde yakın rapor aranıyor...');
      print('   📍 Koordinatlar: $latitude, $longitude');
      print('   📏 Yarıçap: ${radiusMeters}m');
      
      // Tüm açık raporları getir (aynı kategoride)
      final snapshot = await _firestore
          .collection('reports')
          .where('category', isEqualTo: category)
          .where('status', whereIn: ['pending', 'approved'])
          .get();
      
      print('📊 Clustering: ${snapshot.docs.length} açık rapor bulundu');
      
      // Her rapor için mesafe hesapla
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final reportLat = (data['latitude'] as num).toDouble();
        final reportLng = (data['longitude'] as num).toDouble();
        
        final distance = calculateDistance(
          latitude,
          longitude,
          reportLat,
          reportLng,
        );
        
        print('   📏 Rapor ${doc.id} - Mesafe: ${distance.toStringAsFixed(2)}m');
        
        if (distance <= radiusMeters) {
          print('✅ Clustering: Yakın rapor bulundu! ID: ${doc.id}');
          return doc.id;
        }
      }
      
      print('❌ Clustering: Yakın rapor bulunamadı, yeni rapor oluşturulabilir');
      return null;
    } catch (e) {
      print('❌ Clustering hatası: $e');
      return null;
    }
  }
  
  /// Mevcut bir rapora kullanıcı desteği ekler
  /// 
  /// [reportId]: Destek eklenecek raporun ID'si
  /// [userId]: Destek veren kullanıcının ID'si
  /// 
  /// Returns: İşlem başarılı ise true, değilse false
  Future<bool> addSupport(String reportId, String userId) async {
    try {
      print('🤝 Clustering: Rapora destek ekleniyor...');
      print('   📄 Rapor ID: $reportId');
      print('   👤 Kullanıcı ID: $userId');
      
      final docRef = _firestore.collection('reports').doc(reportId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('Rapor bulunamadı');
        }
        
        final data = snapshot.data()!;
        final supportedUserIds = List<String>.from(
          data['supportedUserIds'] ?? []
        );
        
        // Kullanıcı daha önce destek vermiş mi kontrol et
        if (supportedUserIds.contains(userId)) {
          print('⚠️ Clustering: Kullanıcı zaten destek vermiş');
          return;
        }
        
        // Desteği ekle
        supportedUserIds.add(userId);
        
        transaction.update(docRef, {
          'supportCount': FieldValue.increment(1),
          'supportedUserIds': supportedUserIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Clustering: Destek eklendi. Yeni destek sayısı: ${supportedUserIds.length}');
      });
      
      // 🆕 GAMIFICATION: Destek veren kullanıcıya puan ver
      try {
        await GamificationService().onReportSupported(userId, reportId);
        print('🎮 Gamification: Destek veren kullanıcıya +5 puan verildi');
      } catch (e) {
        print('⚠️ Gamification hatası: $e');
      }
      
      return true;
    } catch (e) {
      print('❌ Clustering: Destek eklenirken hata: $e');
      return false;
    }
  }
  
  /// Belirtilen koordinat etrafındaki tüm raporları getirir
  /// Harita üzerinde clustering için kullanılır
  /// 
  /// [centerLat], [centerLng]: Merkez koordinatlar
  /// [radiusKm]: Yarıçap (kilometre)
  /// 
  /// Returns: Belirtilen alan içindeki raporlar
  Future<List<ReportModel>> getReportsInRadius({
    required double centerLat,
    required double centerLng,
    double radiusKm = 5.0,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('reports')
          .where('status', whereIn: ['pending', 'approved', 'resolved'])
          .limit(100)
          .get();
      
      final reports = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return ReportModel.fromJson(data);
            } catch (e) {
              print('⚠️ Rapor parse hatası (${doc.id}): $e');
              return null;
            }
          })
          .whereType<ReportModel>()
          .where((report) {
            final distance = calculateDistance(
              centerLat,
              centerLng,
              report.latitude,
              report.longitude,
            );
            return distance <= (radiusKm * 1000); // km'yi metreye çevir
          })
          .toList();
      
      print('✅ Clustering: ${reports.length} rapor ${radiusKm}km yarıçapında bulundu');
      return reports;
    } catch (e) {
      print('❌ Clustering: Raporlar alınırken hata: $e');
      return [];
    }
  }
  
  /// Kullanıcının daha önce bir rapora destek verip vermediğini kontrol eder
  /// 
  /// [reportId]: Kontrol edilecek rapor ID'si
  /// [userId]: Kullanıcı ID'si
  /// 
  /// Returns: Kullanıcı destek verdiyse true, vermemişse false
  Future<bool> hasUserSupported(String reportId, String userId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      
      if (!doc.exists) return false;
      
      final supportedUserIds = List<String>.from(
        doc.data()?['supportedUserIds'] ?? []
      );
      
      return supportedUserIds.contains(userId);
    } catch (e) {
      print('❌ Clustering: Destek kontrolü hatası: $e');
      return false;
    }
  }
}
