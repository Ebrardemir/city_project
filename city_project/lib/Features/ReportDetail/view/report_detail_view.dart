import 'package:flutter/material.dart';
import 'package:city_project/Features/MyReports/model/report_model.dart';
import 'package:city_project/Features/MyReports/widgets/status_chip.dart';
import '../widgets/report_media_header.dart';
import '../widgets/report_timeline.dart';

class ReportDetailView extends StatelessWidget {
  final ReportModel report;
  const ReportDetailView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAfter = (report.imageAfterUrl ?? '').isNotEmpty;
    final isResolved = report.status == ReportStatus.resolved;

    return Scaffold(
      appBar: AppBar(title: const Text('İhbar Detayı')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          // ✅ Görsel alan + üstüne durum etiketi
          Stack(
            children: [
              ReportMediaHeader(report: report),
              Positioned(
                left: 12,
                top: 12,
                child: StatusChip(status: report.status),
              ),
              if (!isResolved)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Çözüm bekleniyor',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Başlık + kategori
          Text(
            report.categoryName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),

          // Açıklama kartı
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                report.description,
                style: TextStyle(color: cs.onSurfaceVariant, height: 1.35),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Eğer çözülmüşse küçük bilgi
          if (isResolved && hasAfter)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.compare, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Önce/Sonra karşılaştırması için sürgüyü kaydır.',
                        style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!isResolved)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bu ihbar henüz çözülmedi. Belediye çözüm fotoğrafı yüklediğinde burada “Sonra” görseli de görünecek.',
                        style: TextStyle(color: cs.onSurfaceVariant, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Süreç (created/approved/resolved)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Süreç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  ReportTimeline(report: report),
                  const SizedBox(height: 12),
                  Divider(color: cs.outlineVariant),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Destek: ${report.supportCount}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Konum: ${report.lat.toStringAsFixed(5)}, ${report.lng.toStringAsFixed(5)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
