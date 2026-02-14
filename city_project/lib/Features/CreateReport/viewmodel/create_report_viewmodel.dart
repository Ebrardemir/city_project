import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../model/create_report_draft.dart';

class CreateReportViewModel extends ChangeNotifier {
  final LocationService _locationService;
  CreateReportViewModel(this._locationService);

  final draft = CreateReportDraft();

  bool loadingLocation = false;
  bool submitting = false;

  String? errorText;

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
