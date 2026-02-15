import 'package:flutter/material.dart';
import '../../Home/model/report_model.dart';

class ReportTimeline extends StatelessWidget {
  final ReportModel report;
  const ReportTimeline({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget item({
      required IconData icon,
      required String title,
      DateTime? time,
      bool active = true,
    }) {
      final color = active ? cs.primary : cs.onSurfaceVariant.withOpacity(0.5);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  time == null ? '—' : _fmt(time),
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        item(icon: Icons.add_circle_outline, title: 'Oluşturuldu', time: report.createdAt, active: true),
        const SizedBox(height: 12),
        item(icon: Icons.verified_outlined, title: 'Onaylandı', time: report.updatedAt, active: report.updatedAt != null),
        const SizedBox(height: 12),
        item(icon: Icons.check_circle_outline, title: 'Çözüldü', time: report.resolvedAt, active: report.resolvedAt != null),
      ],
    );
  }

  String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.$y • $hh:$mm';
  }
}
