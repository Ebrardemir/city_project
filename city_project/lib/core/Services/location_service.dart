import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    // 1. Önce izinleri kontrol et ve iste
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ LocationService: Konum izni reddedildi');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ LocationService: Konum izni kalıcı olarak reddedildi');
      // Kullanıcıyı ayarlara yönlendirmek iyi bir fikir olabilir
      // await Geolocator.openAppSettings();
      return null;
    }

    // 2. İzin alındıysa, servis açık mı diye bak
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ LocationService: Konum servisi (GPS) kapalı');
      // Kullanıcıdan servisi açmasını iste
      await Geolocator.openLocationSettings();
      // Ayarlar açıldıktan sonra kullanıcı geri döndüğünde tekrar kontrol etmek gerekebilir
      // Ancak blocking olmaması için burada null dönüyoruz, kullanıcı tekrar dener
      return null;
    }

    print('⏳ LocationService: Konum alınıyor...');
    try {
      // 3. Konum Ayarlarını Yapılandır
      // Android ve iOS için özel ayarlar, daha hızlı sonuç için
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // 'best' yerine 'high' genellikle daha hızlıdır ve yeterlidir
        distanceFilter: 10,
      );

      // Konum almayı dene (Timeout süresini 15 saniyeye çıkardık)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 15));
      
      print('✅ LocationService: Konum alındı: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ LocationService: Konum alma hatası: $e');
      
      // Hata durumunda (Timeout vb.) son bilinen konumu dene
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
