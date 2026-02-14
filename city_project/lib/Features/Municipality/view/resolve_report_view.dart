import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../../Home/model/report_model.dart';
import '../service/municipality_service.dart';

/// Rapor Çözme Ekranı
/// Belediye yetkilisinin raporu çözüp, çözüm fotoğrafı yüklediği ekran
class ResolveReportView extends StatefulWidget {
  final ReportModel report;
  
  const ResolveReportView({super.key, required this.report});

  @override
  State<ResolveReportView> createState() => _ResolveReportViewState();
}

class _ResolveReportViewState extends State<ResolveReportView> {
  final MunicipalityService _service = MunicipalityService();
  final TextEditingController _noteController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  File? _selectedImage;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
  
  /// Kameradan fotoğraf çek
  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  /// Galeriden fotoğraf seç
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  /// Fotoğraf seçimi dialogu
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fotoğraf Seç'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Çözümü gönder
  Future<void> _submitResolution() async {
    // Validasyon
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Lütfen çözüm fotoğrafı yükleyin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Onay dialogu
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Raporu Çöz'),
          content: const Text(
            'Bu raporu çözüldü olarak işaretlemek istediğinize emin misiniz?\n\n'
            'Raporlayan kullanıcıya bildirim gönderilecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Evet, Çöz'),
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) return;
    
    setState(() => _isUploading = true);
    
    try {
      print('📤 ResolveReportView: Fotoğraf yükleniyor...');
      
      // 1. Fotoğrafı Firebase Storage'a yükle
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('reports')
          .child('after')
          .child('${widget.report.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      final uploadTask = storageRef.putFile(_selectedImage!);
      
      // Upload progress'i dinle
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      });
      
      await uploadTask;
      final imageUrl = await storageRef.getDownloadURL();
      
      print('✅ ResolveReportView: Fotoğraf yüklendi: $imageUrl');
      
      // 2. Raporu güncelle
      final success = await _service.resolveReport(
        reportId: widget.report.id,
        imageUrlAfter: imageUrl,
        resolvedBy: _auth.currentUser!.uid,
        resolutionNote: _noteController.text.trim().isEmpty 
            ? null 
            : _noteController.text.trim(),
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Rapor başarıyla çözüldü!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Geri dön
        Navigator.pop(context, true); // true: rapor güncellendi
      } else {
        throw Exception('Rapor güncellenemedi');
      }
    } catch (e) {
      print('❌ ResolveReportView: Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporu Çöz'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uyarı kartı
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sorunu çözdükten sonra "Sonra" fotoğrafını yükleyin. '
                        'Vatandaşlar Before/After karşılaştırması yapabilir.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Rapor bilgisi
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getCategoryIcon(widget.report.category),
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.report.category.label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _InfoRow(icon: Icons.description, text: widget.report.description),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.location_on, text: widget.report.district),
                    const SizedBox(height: 8),
                    _InfoRow(icon: Icons.person, text: widget.report.userFullName),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.people,
                      text: '${widget.report.supportCount} kişi destekledi',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Öncesi fotoğrafı
            const Text(
              '📷 Öncesi Fotoğrafı:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.report.imageUrlBefore != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.report.imageUrlBefore!,
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
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error, size: 48, color: Colors.red),
                      ),
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Fotoğraf yok'),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Çözüm fotoğrafı yükleme
            const Text(
              '✅ Çözüm Fotoğrafı:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _isUploading ? null : _showImagePickerDialog,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey, width: 2, style: BorderStyle.solid),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'Fotoğraf Yükle',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kamera veya galeriden seçin',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Çözüm notu
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Çözüm Notu (Opsiyonel)',
                border: OutlineInputBorder(),
                hintText: 'Yapılan işlemi açıklayın... (örn: Çukur asfalt ile kapatıldı)',
                helperText: 'Vatandaşlar bu notu görebilir',
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Upload progress
            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 8),
                  Text(
                    'Yükleniyor: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            
            // Gönder butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _submitResolution,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isUploading ? 'Gönderiliyor...' : 'Raporu Çözüldü Olarak İşaretle',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(ReportCategory category) {
    switch (category) {
      case ReportCategory.road:
        return Icons.foundation;
      case ReportCategory.park:
        return Icons.park;
      case ReportCategory.water:
        return Icons.water_drop;
      case ReportCategory.garbage:
        return Icons.delete;
      case ReportCategory.lighting:
        return Icons.lightbulb;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }
}

/// Bilgi satırı widget'ı
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
