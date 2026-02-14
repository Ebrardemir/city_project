import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/location_service.dart';
import '../model/location_model.dart';

class HomeViewModel extends ChangeNotifier {
  final LocationService _locationService;

  HomeViewModel(this._locationService);

  LatLng? selectedLatLng;
  String? city;
  String? district;

  bool isLoading = false;
  bool showConfirmSheet = false;

  GoogleMapController? mapController;

  Future<void> init() async {
    await getUserLocation();
  }

  Future<void> getUserLocation() async {
    isLoading = true;
    notifyListeners();

    final position = await _locationService.getCurrentPosition();

    if (position != null) {
      selectedLatLng = LatLng(position.latitude, position.longitude);

      final place = await _locationService.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      city = place?.administrativeArea;
      district = place?.subAdministrativeArea;
      showConfirmSheet = true;
    }

    isLoading = false;
    notifyListeners();
  }

  // Manuel haritaya tıklama
  void onMapTapped(LatLng latLng) {
    selectedLatLng = latLng;
    notifyListeners();
  }

  // Manuel şehir/ilçe girilirse (geocode)
  Future<void> setLocationFromText(String cityName) async {
    final latLng = await _locationService.getLatLngFromAddress(cityName);
    if (latLng != null) {
      selectedLatLng = latLng;
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 14),
      );
      notifyListeners();
    }
  }

  Set<Marker> get markers {
    if (selectedLatLng == null) return {};
    return {
      Marker(
        markerId: const MarkerId("selected_location"),
        position: selectedLatLng!,
      ),
    };
  }
}