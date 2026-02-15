import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/services/ai_vision_service.dart';
import '../model/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AIVisionService? _aiVisionService;

  ReportService({AIVisionService? aiVisionService}) 
      : _aiVisionService = aiVisionService;

  // Haritanın görünür alanındaki ihbarları getir
  Future<List<ReportModel>> getReportsInBounds({
    required LatLngBounds bounds,
  }) async {
    try {
      print('🗺️ ReportService: Harita bounds raporları yükleniyor...');
      
      // Bounds içindeki min/max koordinatları al
      final southwest = bounds.southwest;
      final northeast = bounds.northeast;
      
      // Firestore'dan tüm raporları çek (orderBy kaldırıldı - index gerekmez)
      final snapshot = await _firestore
          .collection('reports')
          .where('status', whereIn: ['pending', 'approved', 'resolved'])
          .limit(200)
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
            // Bounds içinde mi kontrol et
            return report.latitude >= southwest.latitude &&
                   report.latitude <= northeast.latitude &&
                   report.longitude >= southwest.longitude &&
                   report.longitude <= northeast.longitude;
          })
          .toList();

      print('✅ ReportService: ${reports.length} rapor harita bounds içinde bulundu');
      return reports;
    } catch (e) {
      print('❌ ReportService: Harita bounds raporları yüklenirken hata: $e');
      return [];
    }
  }

  // Firestore'dan yakındaki ihbarları getir
  Future<List<ReportModel>> getNearbyReports({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      // orderBy kaldırıldı - Firestore index gerekmez
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
            // Basit mesafe hesaplama (yaklaşık)
            final latDiff = (report.latitude - latitude).abs();
            final lngDiff = (report.longitude - longitude).abs();
            final distance = (latDiff * 111) + (lngDiff * 111); // km cinsinden yaklaşık
            return distance <= radiusKm;
          })
          .toList();

      print('✅ ReportService: ${reports.length} yakın ihbar bulundu');
      return reports;
    } catch (e) {
      print('❌ ReportService: Yakındaki ihbarlar yüklenirken hata: $e');
      return [];
    }
  }

  // Yeni ihbar oluştur
  Future<ReportModel?> createReport({
    required String userId,
    required String userFullName,
    required String city,
    required String district,
    String? neighborhood,
    String? street,
    String? address,
    required ReportCategory category,
    required String description,
    required double latitude,
    required double longitude,
    String? imageUrlBefore,
  }) async {
    try {
      final docRef = _firestore.collection('reports').doc();
      
      // Başlangıç durumu
      var reportStatus = ReportStatus.pending;
      bool? isFakeDetected;
      FakeReportReason? fakeReason;
      double? fakeConfidence;
      List<String>? aiDetectedLabels;
      DateTime? fakeDetectionTime;

      // Eğer AI Vision Service varsa ve resim URL'i varsa, analiz et
      if (_aiVisionService != null && imageUrlBefore != null) {
        print('🔍 ReportService: AI Fake Detection başlatılıyor...');
        try {
          // Resmi indir
          final imageUri = Uri.parse(imageUrlBefore);
          final response = await http.get(imageUri).timeout(
            const Duration(seconds: 10),
          );

          if (response.statusCode == 200) {
            final tempDir = Directory.systemTemp;
            final tempFile = File('${tempDir.path}/temp_report_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await tempFile.writeAsBytes(response.bodyBytes);

            // AI ile analiz et
            final analysisResult = await _aiVisionService.analyzeImage(tempFile);
            
            isFakeDetected = analysisResult.isFake;
            fakeReason = FakeReportReason.values.firstWhere(
              (e) => e.name == analysisResult.reason.name,
              orElse: () => FakeReportReason.unknown,
            );
            fakeConfidence = analysisResult.confidence;
            aiDetectedLabels = analysisResult.detectedLabels;
            fakeDetectionTime = DateTime.now();

            // Fake tespit edilirse durumu güncelle
            if (analysisResult.isFake) {
              reportStatus = ReportStatus.fake;
              print('🚩 ReportService: Fake ihbar tespit edildi - Neden: ${analysisResult.reason.label}');
            } else {
              print('✅ ReportService: İmaj legitimate olarak onaylandı');
            }

            // Temp file'ı sil
            try {
              await tempFile.delete();
            } catch (e) {
              print('⚠️ ReportService: Temp file silinirken hata: $e');
            }
          } else {
            print('⚠️ ReportService: Resim indirilemedi - Status: ${response.statusCode}');
          }
        } catch (e) {
          print('⚠️ ReportService: AI Analiz hatası (rapor yine de oluşturulacak): $e');
        }
      }
      
      final report = ReportModel(
        id: docRef.id,
        userId: userId,
        userFullName: userFullName,
        city: city,
        district: district,
        neighborhood: neighborhood,
        street: street,
        address: address,
        category: category,
        description: description,
        latitude: latitude,
        longitude: longitude,
        imageUrlBefore: imageUrlBefore,
        status: reportStatus,
        supportCount: 1,
        supportedUserIds: [userId],
        createdAt: DateTime.now(),
        // AI Detection fields
        isFakeDetected: isFakeDetected,
        fakeReason: fakeReason,
        fakeConfidence: fakeConfidence,
        aiDetectedLabels: aiDetectedLabels,
        fakeDetectionTime: fakeDetectionTime,
      );

      await docRef.set(report.toJson());
      print('✅ ReportService: İhbar oluşturuldu: ${docRef.id}');
      return report;
    } catch (e) {
      print('❌ ReportService: İhbar oluşturulurken hata: $e');
      return null;
    }
  }

  // İhbara destek ver
  Future<bool> supportReport(String reportId, String userId) async {
    try {
      final docRef = _firestore.collection('reports').doc(reportId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception('İhbar bulunamadı');
        }

        final data = snapshot.data()!;
        final supportedUserIds = List<String>.from(data['supportedUserIds'] ?? []);
        
        if (supportedUserIds.contains(userId)) {
          throw Exception('Zaten desteklediniz');
        }

        supportedUserIds.add(userId);
        
        transaction.update(docRef, {
          'supportCount': FieldValue.increment(1),
          'supportedUserIds': supportedUserIds,
          'updatedAt': DateTime.now(),
        });
      });

      print('✅ ReportService: İhbar desteklendi: $reportId');
      return true;
    } catch (e) {
      print('❌ ReportService: Destek eklenirken hata: $e');
      return false;
    }
  }

  // İhbar detayını getir
  Future<ReportModel?> getReportDetail(String reportId) async {
    try {
      final doc = await _firestore.collection('reports').doc(reportId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return ReportModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ ReportService: İhbar detayı yüklenirken hata: $e');
      return null;
    }
  }

  // İhbar durumunu güncelle (Admin için)
  Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    String? imageUrlAfter,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': newStatus.value,
        'updatedAt': DateTime.now(),
      };

      if (newStatus == ReportStatus.resolved) {
        updates['resolvedAt'] = DateTime.now();
        if (imageUrlAfter != null) {
          updates['imageUrlAfter'] = imageUrlAfter;
        }
      }

      await _firestore.collection('reports').doc(reportId).update(updates);
      print('✅ ReportService: İhbar durumu güncellendi: $reportId');
      return true;
    } catch (e) {
      print('❌ ReportService: Durum güncellenirken hata: $e');
      return false;
    }
  }

  // Admin için Fake/Flagged İhbarları getir
  Future<List<ReportModel>> getFakeFlaggedReports() async {
    try {
      print('🔍 ReportService: Fake/Flagged ihbarlar yükleniyor...');

      final snapshot = await _firestore
          .collection('reports')
          .where('status', whereIn: ['fake', 'flagged'])
          .orderBy('fakeDetectionTime', descending: true)
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
          .toList();

      print('✅ ReportService: ${reports.length} fake/flagged ihbar bulundu');
      return reports;
    } catch (e) {
      print('❌ ReportService: Fake/Flagged ihbarlar yüklenirken hata: $e');
      return [];
    }
  }

  // Fake olarak işaretlenen ihbara admin aksiyonu uygula
  Future<bool> adminReviewFakeReport({
    required String reportId,
    required bool isFakeConfirmed,
    String? adminNotes,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': isFakeConfirmed ? ReportStatus.fake.value : ReportStatus.pending.value,
        'updatedAt': DateTime.now(),
      };

      if (adminNotes != null) {
        updates['adminReviewNotes'] = adminNotes;
      }

      await _firestore.collection('reports').doc(reportId).update(updates);
      
      final action = isFakeConfirmed ? 'fake olarak doğrulandı' : 'pending olarak geri alındı';
      print('✅ ReportService: İhbar admin tarafından $action: $reportId');
      return true;
    } catch (e) {
      print('❌ ReportService: Admin review hatası: $e');
      return false;
    }
  }

  // MOCK DATA - Test için
  Future<List<ReportModel>> getMockReports(LatLng center) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    
    return [
      ReportModel(
        id: 'mock1',
        userId: 'user1',
        userFullName: 'Ahmet Yılmaz',
        city: 'İstanbul',
        district: 'Kadıköy',
        address: 'Moda Caddesi',
        category: ReportCategory.road,
        description: 'Büyük çukur var, tehlikeli',
        latitude: center.latitude + 0.002,
        longitude: center.longitude + 0.001,
        imageUrlBefore: 'https://picsum.photos/400/300',
        status: ReportStatus.pending,
        supportCount: 5,
        supportedUserIds: ['user1', 'user2', 'user3'],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      ReportModel(
        id: 'mock2',
        userId: 'user2',
        userFullName: 'Ayşe Kaya',
        city: 'İstanbul',
        district: 'Kadıköy',
        address: 'Bahariye Caddesi',
        category: ReportCategory.garbage,
        description: 'Çöpler toplanmamış',
        latitude: center.latitude - 0.001,
        longitude: center.longitude + 0.002,
        imageUrlBefore: 'https://picsum.photos/401/301',
        status: ReportStatus.approved,
        supportCount: 3,
        supportedUserIds: ['user2', 'user4'],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ReportModel(
        id: 'mock3',
        userId: 'user3',
        userFullName: 'Mehmet Demir',
        city: 'İstanbul',
        district: 'Kadıköy',
        address: 'Reşitpaşa Mahallesi',
        category: ReportCategory.lighting,
        description: 'Sokak lambası yanmıyor',
        latitude: center.latitude + 0.003,
        longitude: center.longitude - 0.002,
        imageUrlBefore: 'https://picsum.photos/402/302',
        imageUrlAfter: 'https://picsum.photos/402/303',
        status: ReportStatus.resolved,
        supportCount: 2,
        supportedUserIds: ['user3', 'user5'],
        createdAt: now.subtract(const Duration(days: 3)),
        resolvedAt: now.subtract(const Duration(hours: 5)),
      ),
      ReportModel(
        id: 'mock4',
        userId: 'user4',
        userFullName: 'Zeynep Şahin',
        city: 'İstanbul',
        district: 'Kadıköy',
        address: 'Fenerbahçe Parkı',
        category: ReportCategory.park,
        description: 'Park bakımsız',
        latitude: center.latitude - 0.002,
        longitude: center.longitude - 0.001,
        imageUrlBefore: 'https://picsum.photos/403/303',
        status: ReportStatus.pending,
        supportCount: 7,
        supportedUserIds: ['user4', 'user1', 'user2', 'user5'],
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      ReportModel(
        id: 'mock5',
        userId: 'user5',
        userFullName: 'Can Öztürk',
        city: 'İstanbul',
        district: 'Kadıköy',
        address: 'Göztepe Mahallesi',
        category: ReportCategory.water,
        description: 'Su sızıntısı var',
        latitude: center.latitude + 0.001,
        longitude: center.longitude + 0.003,
        imageUrlBefore: 'https://picsum.photos/404/304',
        status: ReportStatus.approved,
        supportCount: 4,
        supportedUserIds: ['user5', 'user3', 'user4'],
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }
}
