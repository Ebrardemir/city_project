import 'package:flutter/material.dart';
import '../../Home/model/report_model.dart';

/// Admin Panel - Fake/Flagged İhbarları İnceleme Sayfası
class FakeReportReviewWidget extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const FakeReportReviewWidget({
    super.key,
    required this.report,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: report.status == ReportStatus.fake
                        ? Colors.red.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.status.label,
                    style: TextStyle(
                      color: report.status == ReportStatus.fake
                          ? Colors.red[700]
                          : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${report.category.label} - ${report.district}',
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // AI Detection Sonuçları
          if (report.isFakeDetected != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: report.isFakeDetected!
                      ? Colors.red.withOpacity(0.05)
                      : Colors.green.withOpacity(0.05),
                  border: Border.all(
                    color: report.isFakeDetected!
                        ? Colors.red.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          report.isFakeDetected!
                              ? Icons.warning_rounded
                              : Icons.check_circle_rounded,
                          color: report.isFakeDetected!
                              ? Colors.red
                              : Colors.green,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          report.isFakeDetected!
                              ? '🚨 Sahte İhbar Olasılığı'
                              : '✅ Legitimate İhbar',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tespit Sebebi: ${report.fakeReason?.label ?? "Bilinmiyor"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Güven Seviyesi: ${(report.fakeConfidence ?? 0).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (report.aiDetectedLabels != null &&
                        report.aiDetectedLabels!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            const Text(
                              'AI Etiketleri:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            ...report.aiDetectedLabels!.take(5).map(
                              (label) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                            if (report.aiDetectedLabels!.length > 5)
                              Text(
                                '+${report.aiDetectedLabels!.length - 5} daha',
                                style: const TextStyle(fontSize: 10),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Rapor Detayları
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Bildirim Sahibi:', report.userFullName),
                _buildDetailRow('Kategoris:', report.category.label),
                _buildDetailRow('Lokasyon:', '${report.city}, ${report.district}'),
                if (report.neighborhood != null)
                  _buildDetailRow('Mahalle:', report.neighborhood!),
                if (report.street != null)
                  _buildDetailRow('Cadde/Sokak:', report.street!),
                _buildDetailRow(
                  'Bildirilen Zaman:',
                  _formatDateTime(report.createdAt),
                ),
                _buildDetailRow(
                  'Destek Sayısı:',
                  '${report.supportCount} kişi',
                ),
              ],
            ),
          ),

          // Açıklama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Açıklama:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Resim
          if (report.imageUrlBefore != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bildirim Fotoğrafı:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      report.imageUrlBefore!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Aksiyon Butonları
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reddet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
