import 'package:city_project/Features/Home/viewmodel/home_viewmodel.dart';
import 'package:city_project/Features/Home/widgets/location_confirm_sheet.dart';
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
      body: Stack(
        children: [
          const MapWidget(),

          // Konum onay bottom sheet
          if (vm.showConfirmSheet)
            Align(
              alignment: Alignment.bottomCenter,
              child: LocationConfirmSheet(
                city: vm.city,
                district: vm.district,
                onResult: (bool result) {
                  if (!result) {
                    // Manuel şehir/ilçe seç ekranına git
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
