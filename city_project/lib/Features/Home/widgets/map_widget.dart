import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodel/home_viewmodel.dart';
import 'report_detail_sheet.dart';
import 'filter_bottom_sheet.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    if (vm.isLoading && vm.selectedLatLng == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Konum alınıyor...'),
          ],
        ),
      );
    }

    if (vm.selectedLatLng == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Konum alınamadı'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => vm.getUserLocation(),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: vm.selectedLatLng!,
            zoom: 14,
          ),
          mapType: vm.mapType,
          trafficEnabled: vm.trafficEnabled,
          buildingsEnabled: vm.buildingsEnabled,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          markers: vm.markers,
          onMapCreated: (controller) {
            vm.mapController = controller;
            // İlk yükleme - harita hazır olunca raporları getir
            Future.delayed(const Duration(milliseconds: 500), () {
              vm.loadReportsForVisibleRegion();
            });
          },
          onCameraIdle: () {
            // Harita hareketi durduğunda raporları güncelle
            vm.onCameraIdle();
          },
          onTap: (latLng) {
            vm.clearSelectedReport();
            vm.onMapTapped(latLng);
          },
        ),

        // Sağ Üst Kontroller
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Filtre Butonu
              _MapControlButton(
                icon: Icons.filter_list,
                onPressed: () => _showFilterSheet(context, vm),
                tooltip: 'Filtrele',
                badge: vm.filteredReports.length,
              ),
              const SizedBox(height: 8),

              // Harita Tipi
              _MapControlButton(
                icon: Icons.layers,
                onPressed: () => _showMapTypeSelector(context, vm),
                tooltip: 'Harita Tipi',
              ),
              const SizedBox(height: 8),

              // Trafik
              _MapControlButton(
                icon: Icons.traffic,
                isActive: vm.trafficEnabled,
                onPressed: vm.toggleTraffic,
                tooltip: 'Trafik',
              ),
              const SizedBox(height: 8),

              // Konumuma Git
              _MapControlButton(
                icon: Icons.my_location,
                onPressed: () {
                  if (vm.selectedLatLng != null) {
                    vm.mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(vm.selectedLatLng!, 14),
                    );
                  }
                },
                tooltip: 'Konumum',
              ),
            ],
          ),
        ),

        // İhbar Sayacı
        Positioned(
          top: 16,
          left: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    '${vm.filteredReports.length} İhbar',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Hata Mesajı
        if (vm.errorMessage != null)
          Positioned(
            top: 70,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // İhbar Detay Bottom Sheet
        if (vm.selectedReport != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ReportDetailSheet(
              report: vm.selectedReport!,
              onSupport: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Desteğiniz eklendi!'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(viewModel: vm),
    );
  }

  void _showMapTypeSelector(BuildContext context, HomeViewModel vm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Harita Tipi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _MapTypeOption(
              title: 'Normal',
              icon: Icons.map,
              isSelected: vm.mapType == MapType.normal,
              onTap: () {
                vm.setMapType(MapType.normal);
                Navigator.pop(context);
              },
            ),
            _MapTypeOption(
              title: 'Uydu',
              icon: Icons.satellite_alt,
              isSelected: vm.mapType == MapType.satellite,
              onTap: () {
                vm.setMapType(MapType.satellite);
                Navigator.pop(context);
              },
            ),
            _MapTypeOption(
              title: 'Arazi',
              icon: Icons.terrain,
              isSelected: vm.mapType == MapType.terrain,
              onTap: () {
                vm.setMapType(MapType.terrain);
                Navigator.pop(context);
              },
            ),
            _MapTypeOption(
              title: 'Hibrit',
              icon: Icons.layers,
              isSelected: vm.mapType == MapType.hybrid,
              onTap: () {
                vm.setMapType(MapType.hybrid);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Harita Kontrol Butonu Widget
class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isActive;
  final int? badge;

  const _MapControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isActive = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isActive ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),
        if (badge != null && badge! > 0)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge! > 99 ? '99+' : badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Harita Tipi Seçenek Widget
class _MapTypeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapTypeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.blue : Colors.grey,
      ),
      title: Text(title),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: onTap,
    );
  }
}
