import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Home/model/report_model.dart';
import '../../../core/Services/gamification_service.dart';

/// Belediye yönetimi için servis sınıfı
/// Belediye yetkililerinin raporları yönetmesi için gerekli fonksiyonları içerir
class MunicipalityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Belediye için raporları getirir (ilçe bazlı filtreleme ile)
  /// 
  /// [districts]: Sorumlu olunan ilçeler listesi
  /// [statusFilter]: Durum filtresi (opsiyonel)
  /// [categoryFilter]: Kategori filtresi (opsiyonel)
  /// [lastDocument]: Sayfalama için son doküman (opsiyonel)
  /// [limit]: Sayfa başına rapor sayısı (varsayılan 10)
  /// 
  /// Returns: Rapor listesi ve son doküman (PaginationResult)
  Future<({List<ReportModel> reports, DocumentSnapshot? lastDoc})> getReportsForMunicipalityPaginated({
    required List<String> districts,
    String? city, // Opsiyonel şehir filtresi (Büyükşehir için)
    ReportStatus? statusFilter,
    ReportCategory? categoryFilter,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      print('🏛️ MunicipalityService: Raporlar yükleniyor (Sayfalı)...');
      
      Query query = _firestore.collection('reports');
      
      // FİLTRELEME MANTIĞI:
      // 1. Eğer districts boş ise ve city varsa -> Şehir bazlı (Büyükşehir/İl kullanıcısı)
      // 2. Eğer districts dolu ise -> İlçe bazlı (İlçe Belediyesi)
      
      if (districts.isNotEmpty) {
        // İlçe belediyesi veya belirli ilçelere bakan yetkili
        query = query.where('district', whereIn: districts);
      } else if (city != null && city.isNotEmpty) {
        // İl belediyesi (Tüm şehri görür, districts listesi boştur)
        query = query.where('city', isEqualTo: city);
      }
      
      // Durum filtresi
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }
      
      // Kategori filtresi
      if (categoryFilter != null) {
        query = query.where('category', isEqualTo: categoryFilter.value);
      }
      
      // Sıralama - en yeni raporlar önce
      // NOT: Firestore'da composite index hatalarını önlemek için client-side sıralama yapabiliriz
      // Ancak çok fazla veri varsa bu performans sorunu yaratır.
      // Şimdilik index hatası alınırsa sıralamayı kaldırıp client tarafında yapacağız.
      try {
         query = query.orderBy('createdAt', descending: true);
      } catch (e) {
         print('⚠️ orderBy hatası (Index eksik olabilir): $e');
      }
      
      // Sayfalama başlangıç noktası
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      // Limit
      query = query.limit(limit);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        return (reports: <ReportModel>[], lastDoc: null);
      }

      var reports = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ReportModel.fromJson(data);
        } catch (e) {
          print('⚠️ Rapor parse hatası (${doc.id}): $e');
          return null;
        }
      }).whereType<ReportModel>().toList();
      
      // Client-side sıralama (Yedek)
      // Eğer Firestore sıralaması çalışmadıysa veya index yoksa burada sıralayalım
      // Not: Pagination ile çalışırken bu tam doğru olmayabilir ama hiç veri gelmemesinden iyidir.
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return (reports: reports, lastDoc: snapshot.docs.last);

    } catch (e) {
      if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
         print('⚠️ Index hatası algılandı, sıralamasız tekrar deneniyor...');
         return getReportsForMunicipalityPaginatedWithoutSort(
            districts: districts,
            city: city,
            statusFilter: statusFilter,
            categoryFilter: categoryFilter,
            lastDocument: lastDocument,
            limit: limit
         );
      }
      print('❌ getReportsForMunicipalityPaginated hatası: $e');
      return (reports: <ReportModel>[], lastDoc: null);
    }
  }

  /// Index hatası durumunda sıralamasız (client side sort) çalışan yedek metot
  Future<({List<ReportModel> reports, DocumentSnapshot? lastDoc})> getReportsForMunicipalityPaginatedWithoutSort({
    required List<String> districts,
    String? city,
    ReportStatus? statusFilter,
    ReportCategory? categoryFilter,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = _firestore.collection('reports');
      
      if (districts.isNotEmpty) {
        query = query.where('district', whereIn: districts);
      } else if (city != null && city.isNotEmpty) {
        query = query.where('city', isEqualTo: city);
      }
      
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }
      
      if (categoryFilter != null) {
        query = query.where('category', isEqualTo: categoryFilter.value);
      }
      
      // Sıralama YOK (Index gerektirmez)
      
      // Not: StartAfter sıralama olmadan düzgün çalışmaz, 
      // bu yüzden pagination bu fallback modunda kısıtlı çalışır.
      // Yine de hiç veri görememekten iyidir.
      if (lastDocument != null) {
         // Sıralama olmadığı için startAfterDocument tam beklenen sonucu vermeyebilir 
         // ama Firestore doc referansına göre yine de bir sonraki seti getirebilir.
         // query = query.startAfterDocument(lastDocument); 
         // Düzeltme: startAfterDocument sıralama olmadan kullanılamaz (veya document ID sıralaması gerekir).
         // Şimdilik pagination'ı es geçip sadece limit koyuyoruz veya limiti artırıyoruz.
         query = query.limit(limit * 2); 
      } else {
         query = query.limit(limit);
      }

      final snapshot = await query.get();
      
      var reports = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ReportModel.fromJson(data);
        } catch (e) {
          return null;
        }
      }).whereType<ReportModel>().toList();
      
      // Client tarafında sırala
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return (reports: reports, lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null);
    } catch (e) {
      print('❌ Fallback hatası: $e');
      return (reports: <ReportModel>[], lastDoc: null);
    }
  }

  /// [districts]: Sorumlu olunan ilçeler listesi
  /// [statusFilter]: Durum filtresi (opsiyonel)
  /// [categoryFilter]: Kategori filtresi (opsiyonel)
  /// 
  /// Returns: Filtrelenmiş rapor listesi
  Future<List<ReportModel>> getReportsForMunicipality({
    required List<String> districts,
    ReportStatus? statusFilter,
    ReportCategory? categoryFilter,
  }) async {
    try {
      print('🏛️ MunicipalityService: Raporlar yükleniyor...');
      print('   📍 İlçeler: $districts');
      print('   🔍 Durum filtresi: ${statusFilter?.value ?? "Hepsi"}');
      print('   🔍 Kategori filtresi: ${categoryFilter?.value ?? "Hepsi"}');
      
      Query query = _firestore.collection('reports');
      
      // İlçe filtresi (en az 1 ilçe olmalı)
      if (districts.isNotEmpty) {
        query = query.where('district', whereIn: districts);
      }
      
      // Durum filtresi
      if (statusFilter != null) {
        query = query.where('status', isEqualTo: statusFilter.value);
      }
      
      // Kategori filtresi
      if (categoryFilter != null) {
        query = query.where('category', isEqualTo: categoryFilter.value);
      }
      
      // Sıralama - en yeni raporlar önce
      query = query.orderBy('createdAt', descending: true).limit(100);
      
      final snapshot = await query.get();
      
      final reports = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return ReportModel.fromJson(data);
        } catch (e) {
          print('⚠️ Rapor parse hatası (${doc.id}): $e');
          return null;
        }
      }).whereType<ReportModel>().toList();
      
      print('✅ MunicipalityService: ${reports.length} rapor bulundu');
      return reports;
    } catch (e) {
      print('❌ MunicipalityService: Raporlar alınırken hata: $e');
      return [];
    }
  }
  
  /// Raporu çözüldü olarak işaretler ve çözüm fotoğrafını ekler
  /// 
  /// [reportId]: Çözülecek raporun ID'si
  /// [imageUrlAfter]: Çözüm sonrası fotoğraf URL'i
  /// [resolutionNote]: Çözüm notu (opsiyonel)
  /// [resolvedBy]: Çözümü yapan belediye yetkilisinin ID'si
  /// 
  /// Returns: İşlem başarılı ise true
  Future<bool> resolveReport({
    required String reportId,
    required String imageUrlAfter,
    required String resolvedBy,
    String? resolutionNote,
  }) async {
    try {
      print('✅ MunicipalityService: Rapor çözülüyor...');
      print('   📄 Rapor ID: $reportId');
      print('   🖼️ Çözüm fotoğrafı: ${imageUrlAfter.substring(0, 50)}...');
      
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'resolved',
        'imageUrlAfter': imageUrlAfter,
        'resolutionNote': resolutionNote,
        'resolvedBy': resolvedBy,
        'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ MunicipalityService: Rapor başarıyla çözüldü');
      
      // 🆕 GAMIFICATION: Raporlayan kullanıcıya puan ver
      try {
        final reportDoc = await _firestore.collection('reports').doc(reportId).get();
        final reporterId = reportDoc.data()?['userId'];
        
        if (reporterId != null) {
          await GamificationService().onReportResolved(reporterId, reportId);
          print('🎮 Gamification: Raporlayan kullanıcıya +25 puan verildi');
        }
        
        // Destekleyenlere de puan ver
        final supportedUserIds = List<String>.from(reportDoc.data()?['supportedUserIds'] ?? []);
        for (final userId in supportedUserIds) {
          await GamificationService().addPoints(
            userId: userId,
            points: 5,
            action: 'Desteklediğiniz rapor çözüldü',
            reportId: reportId,
          );
        }
        print('🎮 Gamification: ${supportedUserIds.length} destekleyene +5 puan verildi');

        // BElEDİYE PUANI: Çözen belediye yetkilisine puan ver
        await GamificationService().addPoints(
          userId: resolvedBy,
          points: 50, // Çözüm başına 50 puan
          action: 'Bir sorunu çözdünüz',
          reportId: reportId,
        );
        print('🎮 Gamification: Belediye yetkilisine +50 puan verildi');

      } catch (e) {
        print('⚠️ Gamification hatası: $e');
      }
      
      // TODO: Raporlayan kullanıcıya bildirim gönder
      // TODO: Destekleyenlere bildirim gönder
      
      return true;
    } catch (e) {
      print('❌ MunicipalityService: Rapor çözülürken hata: $e');
      return false;
    }
  }
  
  /// Raporu onaylı duruma getirir (pending -> approved)
  /// 
  /// [reportId]: Onaylanacak raporun ID'si
  /// [approvedBy]: Onaylayan yetkilinin ID'si
  /// 
  /// Returns: İşlem başarılı ise true
  Future<bool> approveReport(String reportId, String approvedBy) async {
    try {
      print('✔️ MunicipalityService: Rapor onaylanıyor...');
      
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ MunicipalityService: Rapor onaylandı');
      
      // 🆕 GAMIFICATION: Raporlayan kullanıcıya puan ver
      try {
        final reportDoc = await _firestore.collection('reports').doc(reportId).get();
        final reporterId = reportDoc.data()?['userId'];
        
        if (reporterId != null) {
          await GamificationService().onReportApproved(reporterId, reportId);
          print('🎮 Gamification: Raporlayan kullanıcıya +5 puan verildi');
        }
      } catch (e) {
        print('⚠️ Gamification hatası: $e');
      }
      
      // TODO: Raporlayan kullanıcıya bildirim gönder
      
      return true;
    } catch (e) {
      print('❌ MunicipalityService: Rapor onaylanırken hata: $e');
      return false;
    }
  }
  
  /// Raporu sahte olarak işaretler
  /// 
  /// [reportId]: Sahte olarak işaretlenecek rapor ID'si
  /// [markedBy]: İşlemi yapan yetkilinin ID'si
  /// [reason]: Sebep (opsiyonel)
  /// 
  /// Returns: İşlem başarılı ise true
  Future<bool> markAsFake(String reportId, String markedBy, {String? reason}) async {
    try {
      print('🚫 MunicipalityService: Rapor sahte olarak işaretleniyor...');
      
      await _firestore.collection('reports').doc(reportId).update({
        'status': 'fake',
        'markedAsFakeBy': markedBy,
        'fakeReason': reason,
        'markedAsFakeAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ MunicipalityService: Rapor sahte olarak işaretlendi');
      
      // 🆕 GAMIFICATION: Raporlayan kullanıcıya ceza puanı ver
      try {
        final reportDoc = await _firestore.collection('reports').doc(reportId).get();
        final reporterId = reportDoc.data()?['userId'];
        
        if (reporterId != null) {
          await GamificationService().onFakeReportDetected(reporterId, reportId);
          print('🎮 Gamification: Raporlayan kullanıcıya -20 puan verildi (ceza)');
        }
      } catch (e) {
        print('⚠️ Gamification hatası: $e');
      }
      
      return true;
    } catch (e) {
      print('❌ MunicipalityService: Rapor işaretlenirken hata: $e');
      return false;
    }
  }

  /// Veritabanındaki benzersiz şehirleri getirir (Debug için)
  Future<List<String>> getAvailableCities() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final cities = snapshot.docs
          .map((doc) => doc.data()['city'] as String?)
          .where((city) => city != null && city.isNotEmpty)
          .toSet()
          .toList();
      cities.sort();
      return List<String>.from(cities);
    } catch (e) {
      print('❌ getAvailableCities hata: $e');
      return [];
    }
  }
  
  /// Seçili şehirdeki benzersiz ilçeleri getirir (Debug için)
  Future<List<String>> getAvailableDistricts(String city) async {
    try {
      final snapshot = await _firestore.collection('reports')
          .where('city', isEqualTo: city)
          .get();
      final districts = snapshot.docs
          .map((doc) => doc.data()['district'] as String?)
          .where((d) => d != null && d.isNotEmpty)
          .toSet()
          .toList();
      districts.sort();
      return List<String>.from(districts);
    } catch (e) {
      print('❌ getAvailableDistricts hata: $e');
      return [];
    }
  }
  
  /// Belediye dashboard için istatistikleri getirir
  /// 
  /// [districts]: Sorumlu olunan ilçeler
  /// 
  /// Returns: İstatistik verileri (toplam, bekleyen, çözülen vb.)
  Future<Map<String, int>> getStatistics(List<String> districts) async {
    try {
      print('📊 MunicipalityService: İstatistikler hesaplanıyor...');
      
      Query query = _firestore.collection('reports');
      
      if (districts.isNotEmpty) {
        query = query.where('district', whereIn: districts);
      }
      
      final snapshot = await query.get();
      
      int total = snapshot.docs.length;
      int pending = 0;
      int approved = 0;
      int resolved = 0;
      int fake = 0;
      
      for (var doc in snapshot.docs) {
        final status = doc.data()?['status'];
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'approved':
            approved++;
            break;
          case 'resolved':
            resolved++;
            break;
          case 'fake':
            fake++;
            break;
        }
      }
      
      final stats = {
        'total': total,
        'pending': pending,
        'approved': approved,
        'resolved': resolved,
        'fake': fake,
      };
      
      print('✅ MunicipalityService: İstatistikler hazır');
      print('   📊 Toplam: $total | Bekleyen: $pending | Çözülen: $resolved');
      
      return stats;
    } catch (e) {
      print('❌ MunicipalityService: İstatistik hatası: $e');
      return {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'resolved': 0,
        'fake': 0,
      };
    }
  }
  
  /// Kategori bazlı istatistikler
  /// 
  /// [districts]: Sorumlu olunan ilçeler
  /// 
  /// Returns: Her kategori için rapor sayısı
  Future<Map<String, int>> getCategoryStatistics(List<String> districts) async {
    try {
      Query query = _firestore.collection('reports');
      
      if (districts.isNotEmpty) {
        query = query.where('district', whereIn: districts);
      }
      
      final snapshot = await query.get();
      
      final categoryStats = <String, int>{};
      
      for (var category in ReportCategory.values) {
        categoryStats[category.value] = 0;
      }
      
      for (var doc in snapshot.docs) {
        final category = doc.data()['category']?.toString();
        if (category != null && categoryStats.containsKey(category)) {
          categoryStats[category] = categoryStats[category]! + 1;
        }
      }
      
      print('✅ MunicipalityService: Kategori istatistikleri hazır');
      return categoryStats;
    } catch (e) {
      print('❌ MunicipalityService: Kategori istatistik hatası: $e');
      return {};
    }
  }
}

extension on Object? {
  operator [](String other) {}
}
