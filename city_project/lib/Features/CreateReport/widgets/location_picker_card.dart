import 'package:flutter/material.dart';

class LocationPickerCard extends StatelessWidget {
  final bool loading;
  final double? lat;
  final double? lng;
  final VoidCallback onGetCurrent;

  const LocationPickerCard({
    super.key,
    required this.loading,
    required this.lat,
    required this.lng,
    required this.onGetCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Konum',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Text(
                    (lat != null && lng != null)
                        ? '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}'
                        : 'Konum seçilmedi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: loading ? null : onGetCurrent,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(loading ? 'Alınıyor' : 'Mevcut Konum'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Haritadan seçme kısmını sonra ekleyeceğiz.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
