import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/tr_locations.dart';

import '../../Home/model/report_model.dart';
import '../../MyReports/widgets/report_card.dart';
import '../service/nearby_reports_service.dart';
import '../viewmodel/nearby_reports_viewmodel.dart';

class NearbyReportsView extends StatelessWidget {
  const NearbyReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NearbyReportsViewModel(NearbyReportsService())..load(),
      child: const _NearbyBody(),
    );
  }
}

class _NearbyBody extends StatelessWidget {
  const _NearbyBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NearbyReportsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakındaki İhbarlar'),
        actions: [
          IconButton(
            onPressed: () {
              vm.setMode(vm.mode == NearbyViewMode.list ? NearbyViewMode.map : NearbyViewMode.list);
            },
            icon: Icon(vm.mode == NearbyViewMode.list ? Icons.map_outlined : Icons.list_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          // Konum Kapsamı Seçimi (İlçe / İl)
          if (vm.currentCity != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                border: Border(bottom: BorderSide(color: Colors.blue.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                   const Icon(Icons.location_on, size: 20, color: Colors.blue),
                   const SizedBox(width: 8),
                   // ŞEHİR SEÇİMİ
                   Expanded(
                     flex: 3,
                     child: InkWell(
                       onTap: () => _showCityPicker(context, vm),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Text(
                             'Şehir',
                             style: TextStyle(fontSize: 10, color: Colors.grey),
                           ),
                           Row(
                             children: [
                               Flexible(
                                 child: Text(
                                   vm.currentCity ?? 'Seç',
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                               const Icon(Icons.keyboard_arrow_down, color: Colors.blue, size: 16),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                   Container(width: 1, height: 24, color: Colors.grey[300], margin: const EdgeInsets.symmetric(horizontal: 8)),
                   // İLÇE SEÇİMİ
                   Expanded(
                     flex: 4,
                     child: InkWell(
                       onTap: vm.currentCity == null ? null : () => _showDistrictPicker(context, vm),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           const Text(
                             'İlçe',
                             style: TextStyle(fontSize: 10, color: Colors.grey),
                           ),
                           Row(
                             children: [
                               Flexible(
                                 child: Text(
                                   (vm.showCityWide || vm.currentDistrict == null) ? 'Tüm Şehir' : vm.currentDistrict!,
                                   style: TextStyle(
                                     fontWeight: FontWeight.bold, 
                                     fontSize: 14, 
                                     color: vm.currentCity == null ? Colors.grey : Colors.black87
                                   ),
                                   overflow: TextOverflow.ellipsis,
                                 ),
                               ),
                               Icon(Icons.keyboard_arrow_down, 
                                 color: vm.currentCity == null ? Colors.grey : Colors.blue, 
                                 size: 16
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          
          const SizedBox(height: 8),
          _SimpleStatusFilter(
            selected: vm.statusFilter,
            onChanged: vm.setStatusFilter,
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: Builder(
              builder: (context) {
                if (vm.loading) return const Center(child: CircularProgressIndicator());
                if (vm.mode == NearbyViewMode.map) {
                  return const Center(child: Text('Harita görünümü yakında...'));
                }

                if (vm.visible.isEmpty) {
                  return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                         const SizedBox(height: 16),
                         Text(
                           'Bu kriterlere uygun ihbar bulunamadı.',
                           style: TextStyle(color: Colors.grey[600]),
                         ),
                       ],
                     ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: vm.visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = vm.visible[i];
                    return ReportCard(
                      report: item,
                      onTap: () {
                        context.pushNamed('report-detail', extra: item);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context, NearbyReportsViewModel vm) {
    if (vm.availableCities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Henüz kayıtlı bir şehir bulunamadı.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kayıtlı Şehir Seçin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.availableCities.length,
                  itemBuilder: (context, index) {
                    final city = vm.availableCities[index];
                    return ListTile(
                      title: Text(city),
                      trailing: vm.currentCity == city 
                          ? const Icon(Icons.check, color: Colors.blue) 
                          : null,
                      onTap: () {
                        vm.setCityManually(city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDistrictPicker(BuildContext context, NearbyReportsViewModel vm) {
    // ViewModel'daki kayıtlı ilçe listesini kullan
    final districts = vm.availableDistricts;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (districts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: const Text('Bu şehirde kayıtlı rapor bulunan ilçe yok.'),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${vm.currentCity} (Kayıtlı İlçeler)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: districts.length + 1, // +1 for 'Tüm Şehir'
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.location_city, color: Colors.blue),
                        title: const Text('Tüm Şehir', style: TextStyle(fontWeight: FontWeight.bold)),
                        trailing: vm.showCityWide 
                          ? const Icon(Icons.check, color: Colors.blue) 
                          : null,
                        onTap: () {
                          vm.setDistrictManually(null); // Tüm şehir
                          Navigator.pop(context);
                        },
                      );
                    }

                    final district = districts[index - 1];
                    final isSelected = !vm.showCityWide && vm.currentDistrict == district;

                    return ListTile(
                      title: Text(district),
                      trailing: isSelected 
                          ? const Icon(Icons.check, color: Colors.blue) 
                          : null,
                      onTap: () {
                        vm.setDistrictManually(district);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimpleStatusFilter extends StatelessWidget {
  final ReportStatus? selected;
  final void Function(ReportStatus? s) onChanged;

  const _SimpleStatusFilter({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterTab('Tümü', null),
          const SizedBox(width: 12),
          _buildFilterTab('Bekleyenler', ReportStatus.pending),
          const SizedBox(width: 12),
          _buildFilterTab('Çözülenler', ReportStatus.resolved),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, ReportStatus? value) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
          boxShadow: isSelected 
             ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
             : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
