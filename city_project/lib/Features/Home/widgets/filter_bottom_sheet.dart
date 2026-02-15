import 'package:flutter/material.dart';
import '../model/report_model.dart';
import '../viewmodel/home_viewmodel.dart';

class FilterBottomSheet extends StatelessWidget {
  final HomeViewModel viewModel;

  const FilterBottomSheet({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Başlık
          const Text(
            'Filtreler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Kategori Filtreleri
          const Text(
            'Kategoriler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportCategory.values.map((category) {
              final isSelected = viewModel.selectedCategories.contains(category);
              return FilterChip(
                label: Text(category.label),
                selected: isSelected,
                onSelected: (_) => viewModel.toggleCategory(category),
                selectedColor: _getCategoryColor(category).withOpacity(0.3),
                checkmarkColor: _getCategoryColor(category),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Durum Filtreleri
          const Text(
            'Durum',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ReportStatus.pending,
              ReportStatus.approved,
              ReportStatus.resolved,
            ].map((status) {
              final isSelected = viewModel.selectedStatuses.contains(status);
              return FilterChip(
                label: Text(status.label),
                selected: isSelected,
                onSelected: (_) => viewModel.toggleStatus(status),
                selectedColor: _getStatusColor(status).withOpacity(0.3),
                checkmarkColor: _getStatusColor(status),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Aksiyon Butonları
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    viewModel.selectedCategories.clear();
                    viewModel.selectedCategories.addAll(ReportCategory.values);
                    viewModel.selectedStatuses.clear();
                    viewModel.selectedStatuses.addAll([
                      ReportStatus.pending,
                      ReportStatus.approved,
                      ReportStatus.resolved,
                    ]);
                    viewModel.applyFilters();
                  },
                  child: const Text('Sıfırla'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Uygula'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(ReportCategory category) {
    switch (category) {
      case ReportCategory.road:
        return Colors.orange;
      case ReportCategory.park:
        return Colors.green;
      case ReportCategory.water:
        return Colors.blue;
      case ReportCategory.garbage:
        return Colors.brown;
      case ReportCategory.lighting:
        return Colors.amber;
      case ReportCategory.other:
        return Colors.grey;
    }
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.approved:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.fake:
        return Colors.red;
      case ReportStatus.flagged:
        return Colors.yellow;
    }
  }
}
