import 'package:city_project/Features/Home/view/create_report_screen.dart';
import 'package:city_project/Features/Home/viewmodel/home_viewmodel.dart';
import 'package:city_project/Features/Home/widgets/location_confirm_sheet.dart';
import 'package:city_project/Features/Home/widgets/map_widget.dart';
import 'package:city_project/Features/Home/widgets/city_district_picker.dart';
 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<HomeViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    // Konum onay dialogunu göster (sadece bir kez)
    if (vm.showConfirmSheet && !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => LocationConfirmSheet(
            city: vm.city,
            district: vm.district,
            onResult: (bool result) {
              Navigator.of(context).pop();
              
              if (result) {
                // Konum onaylandı
                vm.confirmLocation(true);
              } else {
                // İl/İlçe seçim dialogunu göster
                vm.confirmLocation(false);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => CityDistrictPicker(
                    onLocationSelected: (location, city, district) {
                      vm.setManualLocation(location, '$city, $district');
                    },
                  ),
                );
              }
              
              setState(() {
                _dialogShown = false;
              });
            },
          ),
        );
      });
    }

    return Scaffold(
      body: const MapWidget(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => CreateReportScreen(
                initialLocation: vm.selectedLatLng,
                city: vm.city,
                district: vm.district,
              ),
            ),
          );

          // Eğer başarılı oluşturulduysa raporları yeniden yükle
          if (result == true && mounted) {
            vm.loadReports();
          }
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('İhbar Ekle'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
