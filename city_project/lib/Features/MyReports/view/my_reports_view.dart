import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../model/report_model.dart';
import '../service/my_reports_service.dart';
import '../viewmodel/my_reports_viewmodel.dart';
import '../widgets/report_card.dart';

class MyReportsView extends StatelessWidget {
  const MyReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MyReportsViewModel(MyReportsService())..load(),
      child: const _MyReportsBody(),
    );
  }
}

class _MyReportsBody extends StatelessWidget {
  const _MyReportsBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyReportsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('İhbarlarım')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _FilterChips(selected: vm.selectedStatus, onChanged: vm.setFilter),
          const SizedBox(height: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                if (vm.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.visible.isEmpty) {
                  return const _EmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: vm.visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = vm.visible[i];
                    return ReportCard(
                      report: item,
                      onTap: () =>
                          context.pushNamed('report-detail', extra: item),
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

class _FilterChips extends StatelessWidget {
  final ReportStatus? selected;
  final void Function(ReportStatus? status) onChanged;

  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            context,
            label: 'Tümü',
            isSelected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Beklemede',
            isSelected: selected == ReportStatus.pending,
            onTap: () => onChanged(ReportStatus.pending),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'İşleme alındı',
            isSelected: selected == ReportStatus.approved,
            onTap: () => onChanged(ReportStatus.approved),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Çözüldü',
            isSelected: selected == ReportStatus.resolved,
            onTap: () => onChanged(ReportStatus.resolved),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Fake',
            isSelected: selected == ReportStatus.fake,
            onTap: () => onChanged(ReportStatus.fake),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            const Text(
              'Henüz ihbarın yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Yeni bir ihbar oluşturarak başlayabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
