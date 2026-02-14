import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/location_service.dart';
import '../model/report_model.dart';
import '../service/report_service.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class HomeViewModel extends ChangeNotifier {
  final LocationService _locationService;
  final ReportService _reportService;

  HomeViewModel(this._locationService, this._reportService);

  LatLng? selectedLatLng;
  String? city;
  String? district;

  bool isLoading = false;
  String? errorMessage;

  GoogleMapController? mapController;

  // İhbar Listesi
  List<ReportModel> allReports = [];
  List<ReportModel> filteredReports = [];
  
  // Seçili İhbar
  ReportModel? selectedReport;
  
  // Harita kamera kontrolü
  bool _isLoadingReports = false;

  // Harita özelleştirme
  MapType mapType = MapType.terrain;
  bool trafficEnabled = false;
  bool buildingsEnabled = true;

  // Filtreler
  Set<ReportCategory> selectedCategories = Set.from(ReportCategory.values);
  Set<ReportStatus> selectedStatuses = {
    ReportStatus.pending,
    ReportStatus.approved,
    ReportStatus.resolved,
  };

  // Custom Marker Icons
  BitmapDescriptor? pendingIcon;
  BitmapDescriptor? approvedIcon;
  BitmapDescriptor? resolvedIcon;
  BitmapDescriptor? fakeIcon;

  // Varsayılan konum (İstanbul, Türkiye - Taksim)
  static const LatLng _defaultLocation = LatLng(41.0082, 28.9784);

  Future<void> init() async {
    await _loadCustomMarkers();
    await getUserLocation();
    // loadReports konum onaylandıktan sonra çağrılacak
  }

  // Custom marker ikonlarını yükle
  Future<void> _loadCustomMarkers() async {
    pendingIcon = await _createCustomMarker(Colors.orange, Icons.warning);
    approvedIcon = await _createCustomMarker(Colors.blue, Icons.check_circle);
    resolvedIcon = await _createCustomMarker(Colors.green, Icons.done_all);
    fakeIcon = await _createCustomMarker(Colors.red, Icons.block);
  }

  // Custom marker oluştur
  Future<BitmapDescriptor> _createCustomMarker(Color color, IconData icon) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    
    const double size = 120;
    
    // Daire çiz
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2, paint);
    
    // Beyaz border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 4, borderPaint);
    
    // İkon çiz
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size - iconPainter.width) / 2,
        (size - iconPainter.height) / 2,
      ),
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<void> getUserLocation() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    print('🎯 HomeViewModel: getUserLocation başlatıldı');
    
    try {
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        selectedLatLng = LatLng(position.latitude, position.longitude);
        print('📍 HomeViewModel: Konum ayarlandı: $selectedLatLng');

        // Kamera konuma git
        await Future.delayed(const Duration(milliseconds: 500));
        mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(selectedLatLng!, 19),
        );
        print('📷 HomeViewModel: Kamera konuma odaklandı');

        // Adres bilgisi al
        try {
          final place = await _locationService.getAddressFromLatLng(
            position.latitude,
            position.longitude,
          );

          // Türkiye dışı konum kontrolü
          if (place != null && place.country != null) {
            final country = place.country?.toLowerCase() ?? '';
            if (!country.contains('turkey') && !country.contains('türkiye') && !country.contains('turkiye')) {
              print('⚠️ HomeViewModel: Türkiye dışı konum tespit edildi: ${place.country}');
              print('💡 HomeViewModel: iOS Simulator kullanıyorsanız Debug → Location → Custom Location menüsünden Türkiye\'de bir konum seçin');
              
              // Varsayılan Türkiye konumunu kullan
              selectedLatLng = _defaultLocation;
              city = "İstanbul";
              district = "Taksim";
              errorMessage = "Simülatör konumu tespit edildi (${place.country}). Varsayılan İstanbul konumu kullanılıyor.";
              await loadReports();
              isLoading = false;
              notifyListeners();
              return;
            }
          }

          city = place?.administrativeArea ?? place?.locality ?? 'Bilinmeyen Şehir';
          district = place?.subAdministrativeArea ?? place?.subLocality ?? 'Bilinmeyen İlçe';
          print('📮 HomeViewModel: Adres: $district, $city');
        } catch (e) {
          print('⚠️ HomeViewModel: Adres alınamadı: $e');
          city = "Tespit Edildi";
          district = "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        }
        
        // Raporları yükle
        await loadReports();

      } else {
        print('⚠️ HomeViewModel: Konum alınamadı, varsayılan konum kullanılıyor');
        selectedLatLng = _defaultLocation;
        city = "İstanbul";
        district = "Taksim";
        errorMessage = "Konum izni verilmedi veya GPS kapalı. Varsayılan konum kullanılıyor.";
        await loadReports();
      }
    } catch (e) {
      print('❌ HomeViewModel: Hata: $e');
      selectedLatLng = _defaultLocation;
      city = "İstanbul";
      district = "Taksim";
      errorMessage = "Konum alınamadı. Varsayılan konum kullanılıyor.";
      await loadReports();
    }

    isLoading = false;notifyListeners();
  }

  // Manuel konum seçimi
  Future<void> setManualLocation(LatLng location, String address) async {
    selectedLatLng = location;
    errorMessage = null;
    
    // Adres bilgisini güncelle
    try {
      final place = await _locationService.getAddressFromLatLng(
        location.latitude,
        location.longitude,
      );
      
      city = place?.administrativeArea ?? 'Bilinmeyen Şehir';
      district = place?.subAdministrativeArea ?? place?.locality ?? 'Bilinmeyen İlçe';
    } catch (e) {
      city = "Seçili Konum";
      district = address;
    }
    
    // Kamera konuma git
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selectedLatLng!, 18),
    );
    
    // İhbarları yükle
    await loadReports();
    notifyListeners();
  }

  // İhbarları yükle (Firebase'den)
  Future<void> loadReports() async {
    if (selectedLatLng == null) return;

    isLoading = true;
    notifyListeners();

    try {
      print('🔄 HomeViewModel: Firebase\'den raporlar yükleniyor...');
      // Firebase'den yakındaki raporları çek (10km yarıçap)
      allReports = await _reportService.getNearbyReports(
        latitude: selectedLatLng!.latitude,
        longitude: selectedLatLng!.longitude,
        radiusKm: 10.0,
      );
      print('✅ HomeViewModel: ${allReports.length} rapor yüklendi');
      applyFilters();
    } catch (e) {
      print('❌ HomeViewModel: Raporlar yüklenirken hata: $e');
      errorMessage = "İhbarlar yüklenirken hata: $e";
      allReports = [];
      filteredReports = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // Haritanın görünür alanındaki raporları yükle
  Future<void> loadReportsForVisibleRegion() async {
    if (mapController == null || _isLoadingReports) return;

    try {
      _isLoadingReports = true;
      
      // Haritanın görünür alanını al
      final bounds = await mapController!.getVisibleRegion();
      
      print('🗺️ HomeViewModel: Görünür alan raporları yükleniyor...');
      
      // Bounds içindeki raporları getir
      allReports = await _reportService.getReportsInBounds(bounds: bounds);
      
      print('✅ HomeViewModel: ${allReports.length} rapor görünür alanda');
      applyFilters();
      notifyListeners();
    } catch (e) {
      print('❌ HomeViewModel: Görünür alan raporları yüklenirken hata: $e');
    } finally {
      _isLoadingReports = false;
    }
  }

  // Harita kamerası hareket ettiğinde çağrılır
  Future<void> onCameraIdle() async {
    await loadReportsForVisibleRegion();
  }

  // Filtreleri uygula
  void applyFilters() {
    filteredReports = allReports.where((report) {
      final categoryMatch = selectedCategories.contains(report.category);
      final statusMatch = selectedStatuses.contains(report.status);
      return categoryMatch && statusMatch;
    }).toList();
    notifyListeners();
  }

  // Kategori filtresini değiştir
  void toggleCategory(ReportCategory category) {
    if (selectedCategories.contains(category)) {
      selectedCategories.remove(category);
    } else {
      selectedCategories.add(category);
    }
    applyFilters();
  }

  // Status filtresini değiştir
  void toggleStatus(ReportStatus status) {
    if (selectedStatuses.contains(status)) {
      selectedStatuses.remove(status);
    } else {
      selectedStatuses.add(status);
    }
    applyFilters();
  }

  // İhbar seç
  void selectReport(ReportModel report) {
    selectedReport = report;
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(report.position, 17),
    );
    notifyListeners();
  }

  // İhbar seçimini kaldır
  void clearSelectedReport() {
    selectedReport = null;
    notifyListeners();
  }

  // Manuel haritaya tıklama
  void onMapTapped(LatLng latLng) {
    selectedLatLng = latLng;
    clearSelectedReport();
    notifyListeners();
  }

  // Manuel şehir/ilçe girilirse (geocode)
  Future<void> setLocationFromText(String cityName) async {
    final latLng = await _locationService.getLatLngFromAddress(cityName);
    if (latLng != null) {
      selectedLatLng = latLng;
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 14));
      notifyListeners();
    }
  }

  // Marker'ları oluştur
  Set<Marker> get markers {
    return filteredReports.map((report) {
      BitmapDescriptor icon;
      switch (report.status) {
        case ReportStatus.pending:
          icon = pendingIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        case ReportStatus.approved:
          icon = approvedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
          break;
        case ReportStatus.resolved:
          icon = resolvedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case ReportStatus.fake:
          icon = fakeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
      }

      return Marker(
        markerId: MarkerId(report.id),
        position: report.position,
        icon: icon,
        onTap: () => selectReport(report),
        infoWindow: InfoWindow(
          title: report.category.label,
          snippet: '${report.supportCount} kişi destekledi',
        ),
      );
    }).toSet();
  }

  // Harita tipini değiştir
  void setMapType(MapType type) {
    mapType = type;
    notifyListeners();
  }

  // Trafik görünümünü aç/kapat
  void toggleTraffic() {
    trafficEnabled = !trafficEnabled;
    notifyListeners();
  }

  // Binaları aç/kapat
  void toggleBuildings() {
    buildingsEnabled = !buildingsEnabled;
    notifyListeners();
  }
}
