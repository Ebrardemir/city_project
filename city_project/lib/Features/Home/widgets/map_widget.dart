import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (vm.isLoading || vm.selectedLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: vm.selectedLatLng!,
        zoom: 16,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: vm.markers,
      onMapCreated: (controller) {
        vm.mapController = controller;
      },
      onTap: vm.onMapTapped, // 🔥 Haritaya tıklayınca pin değişir
    );
  }
}