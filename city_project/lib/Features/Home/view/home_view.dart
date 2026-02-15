import 'package:city_project/Features/Home/view/create_report_screen.dart';
import 'package:city_project/Features/Home/viewmodel/home_viewmodel.dart';
import 'package:city_project/Features/Home/widgets/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
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
