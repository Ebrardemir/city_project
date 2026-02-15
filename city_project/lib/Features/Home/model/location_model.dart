import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final String city;
  final String district;
  final LatLng position;

  LocationModel({
    required this.city,
    required this.district,
    required this.position,
  });

  factory LocationModel.fromPlacemark(dynamic placemark, LatLng position) {
    return LocationModel(
      city: placemark?.administrativeArea ?? '',
      district: placemark?.subAdministrativeArea ?? '',
      position: position,
    );
  }
}

