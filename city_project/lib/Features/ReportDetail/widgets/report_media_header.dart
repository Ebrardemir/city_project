import 'package:before_after/before_after.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Home/model/report_model.dart';

/// Rapor detay başlığında görseli gösterir
/// Eğer rapor çözülmüşse Before/After slider gösterir
class ReportMediaHeader extends StatelessWidget {
  final ReportModel report;
  
  const ReportMediaHeader({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final imageBefore = report.imageUrlBefore ?? '';
    final imageAfter = report.imageUrlAfter;
    final isResolved = report.status == ReportStatus.resolved;

    
    final hasAfter = (imageAfter ?? '').isNotEmpty;

    // Çözülmüş ve "sonra" fotoğrafı varsa Before/After slider göster
    if (isResolved && hasAfter) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 300,
          child: BeforeAfter(
            before: CachedNetworkImage(imageUrl: imageBefore, fit: BoxFit.cover),
            after: CachedNetworkImage(imageUrl: imageAfter!, fit: BoxFit.cover),
            thumbColor: Colors.white,
          ),
        ),
      );
    }

    // Sadece "önce" fotoğrafını göster
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _img(imageBefore),
      ),
    );
  }

  Widget _img(String url) {
    if (url.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48),
            SizedBox(height: 8),
            Text('Fotoğraf yok'),
          ],
        ),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 48),
      ),
    );
  }
}

