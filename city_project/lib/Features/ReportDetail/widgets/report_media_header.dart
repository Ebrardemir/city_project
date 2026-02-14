import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';
import '../../MyReports/model/report_model.dart';

class ReportMediaHeader extends StatelessWidget {
  final ReportModel report;
  const ReportMediaHeader({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final hasAfter = (report.imageAfterUrl ?? '').isNotEmpty;
    final isResolved = report.status == ReportStatus.resolved;

    if (isResolved && hasAfter) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: BeforeAfter(
            before: _img(report.imageBeforeUrl),
            after: _img(report.imageAfterUrl!),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _img(report.imageBeforeUrl),
      ),
    );
  }

  Widget _img(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }
}
