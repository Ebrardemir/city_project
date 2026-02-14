import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
          const SizedBox(height: 8),
          _StatusChips(
            selected: vm.statusFilter,
            onChanged: vm.setStatusFilter,
          ),
          const SizedBox(height: 8),
          _CategoryChips(
            selectedCategoryId: vm.categoryFilter,
            onChanged: vm.setCategoryFilter,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                if (vm.loading) return const Center(child: CircularProgressIndicator());
                if (vm.mode == NearbyViewMode.map) {
                  return const Center(child: Text('Harita görünümü (UI sonra)'));
                }

                if (vm.visible.isEmpty) {
                  return const Center(child: Text('Yakında ihbar yok.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: vm.visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
}

class _StatusChips extends StatelessWidget {
  final ReportStatus? selected;
  final void Function(ReportStatus? s) onChanged;

  const _StatusChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, ReportStatus? value) {
      return ChoiceChip(
        label: Text(label),
        selected: selected == value,
        onSelected: (_) => onChanged(value),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          chip('Tümü', null),
          const SizedBox(width: 8),
          chip('Beklemede', ReportStatus.pending),
          const SizedBox(width: 8),
          chip('İşleme alındı', ReportStatus.approved),
          const SizedBox(width: 8),
          chip('Çözüldü', ReportStatus.resolved),
          const SizedBox(width: 8),
          chip('Fake', ReportStatus.fake),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final ReportCategory? selectedCategoryId;
  final void Function(ReportCategory? cat) onChanged;

  const _CategoryChips({required this.selectedCategoryId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Use ReportCategory enum values
    final categories = [
      (null, 'Tümü'),
      (ReportCategory.road, ReportCategory.road.label),
      (ReportCategory.park, ReportCategory.park.label),
      (ReportCategory.garbage, ReportCategory.garbage.label),
      (ReportCategory.water, ReportCategory.water.label),
      (ReportCategory.lighting, ReportCategory.lighting.label),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (final c in categories) ...[
            ChoiceChip(
              label: Text(c.$2),
              selected: selectedCategoryId == c.$1,
              onSelected: (_) => onChanged(c.$1),
            ),
            const SizedBox(width: 8),
          ]
        ],
      ),
    );
  }
}
