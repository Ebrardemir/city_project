import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    // Konum servisi aktif mi?
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ LocationService: Konum servisi kapalı');
      return null;
    }

    // İzin kontrolü
    LocationPermission permission = await Geolocator.checkPermission();
    print('📍 LocationService: Mevcut izin durumu: $permission');

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print('📍 LocationService: İzin istendi, yeni durum: $permission');
      if (permission == LocationPermission.denied) {
        print('❌ LocationService: Konum izni reddedildi');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ LocationService: Konum izni kalıcı olarak reddedildi');
      return null;
    }

    print('⏳ LocationService: Konum alınıyor...');
    try {
      // En yüksek doğruluk ve 10 saniye timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('✅ LocationService: Konum alındı: ${position.latitude}, ${position.longitude}');
      print('📊 LocationService: Doğruluk: ${position.accuracy}m');
      return position;
    } catch (e) {
      print('❌ LocationService: Konum alma hatası: $e');
      
      // Timeout olursa son bilinen konumu dene
      try {
        print('⏳ LocationService: Son bilinen konum alınıyor...');
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print('✅ LocationService: Son bilinen konum kullanılıyor');
          return lastPosition;
        }
      } catch (e2) {
        print('❌ LocationService: Son konum da alınamadı: $e2');
      }
      
      return null;
    }
  }

  Future<Placemark?> getAddressFromLatLng(double lat, double lng) async {
    print('🗺️ LocationService: Adres alınıyor - Koordinatlar: $lat, $lng');
    try {
      final list = await placemarkFromCoordinates(lat, lng);
      if (list.isNotEmpty) {
        final place = list.first;
        print('✅ LocationService: Adres bulundu:');
        print('   📍 Ülke: ${place.country}');
        print('   📍 Şehir (administrativeArea): ${place.administrativeArea}');
        print('   📍 İlçe (subAdministrativeArea): ${place.subAdministrativeArea}');
        print('   📍 Semt (locality): ${place.locality}');
        print('   📍 Alt Semt (subLocality): ${place.subLocality}');
        print('   📍 Sokak: ${place.street}');
        return place;
      }
      print('⚠️ LocationService: Adres listesi boş');
      return null;
    } catch (e) {
      print('❌ LocationService: Adres alma hatası: $e');
      return null;
    }
  }

  // 🔥 MANUEL ŞEHİR/İLÇE -> LAT LNG
  Future<LatLng?> getLatLngFromAddress(String address) async {
    final locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      return LatLng(locations.first.latitude, locations.first.longitude);
    }
    return null;
  }
}
