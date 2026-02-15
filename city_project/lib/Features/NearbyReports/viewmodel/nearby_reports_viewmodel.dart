import 'package:flutter/foundation.dart';
import '../../Home/model/report_model.dart';
import '../service/nearby_reports_service.dart';
import '../../../core/services/location_service.dart';

enum NearbyViewMode { list, map }

class NearbyReportsViewModel extends ChangeNotifier {
  final NearbyReportsService _service;
  final LocationService _locationService = LocationService();

  NearbyReportsViewModel(this._service);

  bool loading = false;
  List<ReportModel> _all = [];
  List<ReportModel> visible = [];

  NearbyViewMode mode = NearbyViewMode.list;

  ReportStatus? statusFilter; // null => tümü
  ReportCategory? categoryFilter; // null => tümü

  // Konum ve Filtre Durumu
  String? currentCity;
  String? currentDistrict;
  bool showCityWide = false; // false = Sadece İlçe, true = Tüm İl

  // Filtreler için veritabanından gelen listeler
  List<String> availableCities = [];
  List<String> availableDistricts = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      // 1. Önce veritabanındaki kayıtlı şehirleri çek
      availableCities = await _service.getAvailableCities();

      // 2. Kullanıcının konumunu bul
      final pos = await _locationService.getCurrentPosition();
      if (pos != null) {
        final placemark = await _locationService.getAddressFromLatLng(pos.latitude, pos.longitude);
        if (placemark != null) {
          currentCity = placemark.administrativeArea;
          currentDistrict = placemark.subAdministrativeArea ?? placemark.locality; 
          
          // Eğer bulunan şehir listemizde varsa, ilçelerini de çek
          if (currentCity != null) {
             availableDistricts = await _service.getAvailableDistricts(currentCity!);
          }
        }
      }
    } catch (e) {
      debugPrint('NearbyVM: Konum alınamadı $e');
    }

    // Eğer konum yoksa varsayılan veya boş
    if (currentCity == null) {
      if (availableCities.isNotEmpty) {
        // Konum yoksa ilk şehri seçelim (veya İstanbul)
        currentCity = availableCities.contains('İstanbul') ? 'İstanbul' : availableCities.first;
        availableDistricts = await _service.getAvailableDistricts(currentCity!);
        currentDistrict = null; // Tüm şehir
        showCityWide = true;
      } else {
        loading = false;
        notifyListeners();
        return;
      }
    }

    await _fetchData();
  }

  /// Kullanıcı manuel olarak şehir seçerse
  Future<void> setCityManually(String city) async {
    if (currentCity == city) return;
    
    currentCity = city;
    currentDistrict = null; // Yeni şehirde ilçe bilinmiyor, sıfırla
    showCityWide = true;    // Mecburen il geneli moduna geç
    
    // Şehir değişince o şehrin ilçelerini yükle
    loading = true;
    notifyListeners();
    
    availableDistricts = await _service.getAvailableDistricts(city);
    
    await _fetchData();
  }

  /// Kullanıcı manuel olarak ilçe seçerse
  void setDistrictManually(String? district) {
    if (district == null) {
      // "Tüm Şehir" seçildi
      showCityWide = true;
    } else {
      currentDistrict = district;
      showCityWide = false;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (currentCity == null) return;
    
    // Yükleniyor...
    // Not: Sadece loading=true yapıp notify edersek ekran titreyebilir, 
    // ama kullanıcı verinin yenilendiğini görmeli.
    
    final districtQuery = showCityWide ? null : currentDistrict;
    
    _all = await _service.fetchReportsByLocation(
      city: currentCity!,
      district: districtQuery,
    );
    
    _apply();
    
    loading = false;
    notifyListeners();
  }

  void toggleScope(bool cityWide) {
    if (showCityWide == cityWide) return;
    showCityWide = cityWide;
    _fetchData();
  }

  void setMode(NearbyViewMode m) {
    mode = m;
    notifyListeners();
  }

  void setStatusFilter(ReportStatus? s) {
    statusFilter = s;
    _apply();
    notifyListeners();
  }

  void setCategoryFilter(ReportCategory? cat) {
    categoryFilter = cat;
    _apply();
    notifyListeners();
  }

  void _apply() {
    var list = _all;

    if (statusFilter != null) {
      list = list.where((e) => e.status == statusFilter).toList();
    }
    if (categoryFilter != null) {
      list = list.where((e) => e.category == categoryFilter).toList();
    }

    visible = list;
  }
}
