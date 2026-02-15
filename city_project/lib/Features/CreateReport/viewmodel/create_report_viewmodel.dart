import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/ai_vision_service.dart';
import '../model/create_report_draft.dart';

class CreateReportViewModel extends ChangeNotifier {
  final LocationService _locationService;
  final AIVisionService? _aiVisionService;
  
  CreateReportViewModel(
    this._locationService, {
    AIVisionService? aiVisionService,
  }) : _aiVisionService = aiVisionService;

  final draft = CreateReportDraft();

  bool loadingLocation = false;
  bool submitting = false;
  bool analyzingImage = false;

  String? errorText;
  
  // AI Detection Results
  FakeDetectionResult? lastAnalysisResult;
  bool? imageAnalysisWarning;

  // Mock kategori listesi (backend gelince API)
  final categories = const [
    (1, 'Yol / Çukur'),
    (2, 'Park / Yeşil Alan'),
    (3, 'Su / Sızıntı'),
    (4, 'Çöp / Temizlik'),
    (5, 'Aydınlatma'),
  ];

  void setCategory(int id, String name) {
    draft.categoryId = id;
    draft.categoryName = name;
    notifyListeners();
  }

  void setDescription(String value) {
    draft.description = value;
    notifyListeners();
  }

  void setImagePath(String path) {
    draft.localImagePath = path;
    // Yeni resim seçildiğinde önceki analiz sonuçlarını temizle
    lastAnalysisResult = null;
    imageAnalysisWarning = null;
    notifyListeners();
  }

  Future<void> getCurrentLocation() async {
    loadingLocation = true;
    errorText = null;
    notifyListeners();

    try {
      final Position? pos = await _locationService.getCurrentPosition();
      if (pos == null) {
        errorText = 'Konum alınamadı. Konum iznini kontrol et.';
      } else {
        draft.lat = pos.latitude;
        draft.lng = pos.longitude;
      }
    } catch (_) {
      errorText = 'Konum alınırken hata oluştu.';
    }

    loadingLocation = false;
    notifyListeners();
  }

  /// AI Vision ile resim analiz et
  /// Fake İhbar tespiti yapar
  Future<void> analyzeImage() async {
    if (draft.localImagePath == null || _aiVisionService == null) {
      return;
    }

    analyzingImage = true;
    imageAnalysisWarning = null;
    lastAnalysisResult = null;
    notifyListeners();

    try {
      final imageFile = File(draft.localImagePath!);
      final result = await _aiVisionService.analyzeImage(imageFile);
      
      lastAnalysisResult = result;
      imageAnalysisWarning = result.isFake;

      if (result.isFake) {
        errorText = '⚠️ Fake İhbar Uyarısı: ${result.reason.label}\n'
            'Kontrol: ${(result.confidence * 100).toStringAsFixed(0)}% kesinlikle uyumsuz gözüküyor.\n'
            'Emin misin? (Devam edebilirsin, Admin inceleyecek)';
      } else {
        errorText = null;
      }

      print(
          '✅ CreateReportViewModel: Resim analizi tamamlandı - Fake: ${result.isFake}, Neden: ${result.reason.label}');
    } catch (e) {
      print('❌ CreateReportViewModel: Resim analizi hatası: $e');
      errorText = 'Resim analiz edilirken hata oluştu. Devam edebilirsin.';
    } finally {
      analyzingImage = false;
      notifyListeners();
    }
  }

  String? firstValidationError() {
    if (draft.localImagePath == null) return 'Fotoğraf ekle';
    if (draft.categoryId == null) return 'Kategori seç';
    if (draft.description.trim().length < 10) {
      return 'Açıklama en az 10 karakter olmalı';
    }
    if (draft.lat == null || draft.lng == null) return 'Konum al';
    return null;
  }

  /// Backend yokken mock submit
  Future<bool> submit() async {
    errorText = null;

    if (!draft.isValid) {
      errorText =
          'Lütfen fotoğraf ekle, kategori seç, açıklamayı en az 10 karakter yaz ve konum al.';
      notifyListeners();
      return false;
    }

    submitting = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    submitting = false;
    notifyListeners();

    return true;
  }
}
