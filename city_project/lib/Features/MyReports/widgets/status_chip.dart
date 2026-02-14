import 'package:flutter/material.dart';
import '../../Home/model/report_model.dart';

class StatusChip extends StatelessWidget {
  final ReportStatus status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      ReportStatus.pending => ('Beklemede', Colors.orange),
      ReportStatus.approved => ('İşleme alındı', Colors.blue),
      ReportStatus.resolved => ('Çözüldü', Colors.green),
      ReportStatus.fake => ('Fake', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
