import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PhotoPickerCard extends StatelessWidget {
  final String? imagePath;
  final void Function(String path) onPicked;

  const PhotoPickerCard({
    super.key,
    required this.imagePath,
    required this.onPicked,
  });

  Future<void> _pick(BuildContext context, ImageSource source) async {
    if (source == ImageSource.gallery) {
      final status = await Permission.photos.request(); // iOS + bazı Android
      // Android için de güvenli:
      final mediaStatus = await Permission.mediaLibrary.request();

      if (!status.isGranted && !mediaStatus.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Galeri izni verilmedi')),
          );
        }
        return;
      }
    }

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file != null) onPicked(file.path);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Galeri/Kamera açılamadı: $e')));
    }
  }

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
              'Fotoğraf',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imagePath == null
                    ? Container(
                        color: cs.surfaceContainerHighest.withOpacity(0.6),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add_a_photo_outlined, size: 34),
                            SizedBox(height: 8),
                            Text('Fotoğraf ekle'),
                          ],
                        ),
                      )
                    : Image.file(
                        File(imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(context, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pick(context, ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
