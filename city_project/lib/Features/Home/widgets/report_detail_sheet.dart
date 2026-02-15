import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/report_model.dart';

class ReportDetailSheet extends StatelessWidget {
  final ReportModel report;
  final VoidCallback? onSupport;

  const ReportDetailSheet({
    super.key,
    required this.report,
    this.onSupport,
  });

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

          // Başlık ve Status
          Row(
            children: [
              _CategoryIcon(category: report.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.category.label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StatusChip(status: report.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Açıklama
          Text(
            report.description,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
          const SizedBox(height: 16),

          // Fotoğraf
          if (report.imageUrlBefore != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: report.imageUrlBefore!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // İstatistikler
          Row(
            children: [
              _InfoItem(
                icon: Icons.person,
                label: report.userFullName,
              ),
              const SizedBox(width: 16),
              _InfoItem(
                icon: Icons.people,
                label: '${report.supportCount} destek',
              ),
              const SizedBox(width: 16),
              _InfoItem(
                icon: Icons.access_time,
                label: _formatDate(report.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Aksiyon Butonları
          if (report.status != ReportStatus.resolved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onSupport,
                icon: const Icon(Icons.thumb_up),
                label: const Text('Bu İhbarı Destekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Bu ihbar çözülmüştür',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Çözüldü ise sonrası fotoğrafı
          if (report.status == ReportStatus.resolved &&
              report.imageUrlAfter != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  report.resolvedAt != null 
                      ? 'Çözüldü • ${_formatDate(report.resolvedAt!)}'
                      : 'Çözüldü',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: report.imageUrlAfter!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Görsel yüklenemedi'),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays} gün önce';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} saat önce';
    } else {
      return '${diff.inMinutes} dk önce';
    }
  }
}

// Kategori İkonu
class _CategoryIcon extends StatelessWidget {
  final ReportCategory category;

  const _CategoryIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (category) {
      case ReportCategory.road:
        icon = Icons.construction;
        color = Colors.orange;
        break;
      case ReportCategory.park:
        icon = Icons.park;
        color = Colors.green;
        break;
      case ReportCategory.water:
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case ReportCategory.garbage:
        icon = Icons.delete;
        color = Colors.brown;
        break;
      case ReportCategory.lighting:
        icon = Icons.lightbulb;
        color = Colors.amber;
        break;
      case ReportCategory.other:
        icon = Icons.more_horiz;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

// Status Chip
class _StatusChip extends StatelessWidget {
  final ReportStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        break;
      case ReportStatus.approved:
        color = Colors.blue;
        break;
      case ReportStatus.resolved:
        color = Colors.green;
        break;
      case ReportStatus.fake:
        color = Colors.red;
        break;
      case ReportStatus.flagged:
        color = Colors.yellow;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Info Item
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
