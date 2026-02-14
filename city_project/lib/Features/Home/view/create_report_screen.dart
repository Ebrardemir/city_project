import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/report_model.dart';
import '../service/report_service.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/di/locator.dart';

class CreateReportScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? city;
  final String? district;

  const CreateReportScreen({
    super.key,
    this.initialLocation,
    this.city,
    this.district,
  });

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _reportService = locator<ReportService>();
  final _imageService = ImageUploadService();
  final _locationService = locator<LocationService>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  ReportCategory _selectedCategory = ReportCategory.road;
  File? _selectedImage;
  LatLng? _selectedLocation;
  String? _city;
  String? _district;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _city = widget.city;
    _district = widget.district;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fotoğraf seçilirken hata: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    try {
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        final place = await _locationService.getAddressFromLatLng(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _city = place?.administrativeArea ?? 'Bilinmeyen';
          _district = place?.subAdministrativeArea ?? 'Bilinmeyen';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Konum alınamadı: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen konum seçin')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen fotoğraf ekleyin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kullanıcı bilgilerini al
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Firestore'dan kullanıcı bilgilerini çek (varsa)
      String fullName = 'Anonim';
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          fullName = userData['fullName'] ?? userData['name'] ?? 'Anonim';
        } else {
          // Firestore'da yoksa Firebase Auth'dan displayName kullan
          fullName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Kullanıcı';
        }
      } catch (e) {
        print('⚠️ Firestore kullanıcı bilgisi alınamadı, Auth kullanılıyor: $e');
        fullName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Kullanıcı';
      }

      // Fotoğrafı yükle
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadReportImage(
          imageFile: _selectedImage!,
          userId: currentUser.uid,
        );

        if (imageUrl == null) {
          throw Exception('Fotoğraf yüklenemedi');
        }
      }

      // İhbar oluştur
      final report = await _reportService.createReport(
        userId: currentUser.uid,
        userFullName: fullName,
        city: _city ?? 'Bilinmeyen',
        district: _district ?? 'Bilinmeyen',
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        imageUrlBefore: imageUrl,
      );

      if (report != null) {
        if (mounted) {
          Navigator.of(context).pop(true); // Başarılı ile geri dön
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İhbar başarıyla oluşturuldu!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('İhbar oluşturulamadı');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni İhbar Oluştur'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Kategori Seçimi
            const Text(
              'Kategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReportCategory.values.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Açıklama
            const Text(
              'Açıklama',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Sorunu detaylı olarak açıklayın...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Lütfen açıklama girin';
                }
                if (value.trim().length < 10) {
                  return 'Açıklama en az 10 karakter olmalı';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Fotoğraf
            const Text(
              'Fotoğraf',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
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
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Kamera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),

            // Konum
            const Text(
              'Konum',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedLocation != null
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedLocation != null
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedLocation != null
                            ? Icons.check_circle
                            : Icons.location_off,
                        color: _selectedLocation != null
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedLocation != null
                              ? '$_district, $_city'
                              : 'Konum seçilmedi',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedLocation != null
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Şu Anki Konumu Kullan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Gönder Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'İhbar Oluştur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
