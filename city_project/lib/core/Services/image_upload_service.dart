import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Resim yükle ve URL döndür
  Future<String?> uploadReportImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final fileName = 'reports/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      
      print('⏳ ImageUploadService: Yükleniyor: $fileName');
      
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('✅ ImageUploadService: Yüklendi: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ ImageUploadService: Yükleme hatası: $e');
      return null;
    }
  }

  // Resmi sil
  Future<bool> deleteReportImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ ImageUploadService: Resim silindi');
      return true;
    } catch (e) {
      print('❌ ImageUploadService: Silme hatası: $e');
      return false;
    }
  }
}
