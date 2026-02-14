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
import '../../../core/Services/clustering_service.dart';
import '../../../core/Services/gamification_service.dart';

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
  final _reportService = ReportService();
  final _imageService = ImageUploadService();
  final _locationService = LocationService();
  final _clusteringService = ClusteringService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  ReportCategory _selectedCategory = ReportCategory.road;
  File? _selectedImage;
  LatLng? _selectedLocation;
  String? _city;
  String? _district;
  String? _address;
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
          _district = place?.subAdministrativeArea ?? place?.locality ?? 'Bilinmeyen';
          
          // Detaylı adres oluştur
          final addressParts = <String>[];
          if (place?.street != null && place!.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place?.subLocality != null && place!.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place?.name != null && place!.name!.isNotEmpty && !addressParts.contains(place.name)) {
            addressParts.add(place.name!);
          }
          
          _address = addressParts.isNotEmpty 
              ? addressParts.join(', ') 
              : '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
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

  Future<void> _selectLocationFromMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLocation ?? widget.initialLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      
      try {
        final place = await _locationService.getAddressFromLatLng(
          result.latitude,
          result.longitude,
        );

        setState(() {
          _selectedLocation = result;
          _city = place?.administrativeArea ?? 'Bilinmeyen';
          _district = place?.subAdministrativeArea ?? place?.locality ?? 'Bilinmeyen';
          
          // Detaylı adres oluştur
          final addressParts = <String>[];
          if (place?.street != null && place!.street!.isNotEmpty) {
            addressParts.add(place.street!);
          }
          if (place?.subLocality != null && place!.subLocality!.isNotEmpty) {
            addressParts.add(place.subLocality!);
          }
          if (place?.name != null && place!.name!.isNotEmpty && !addressParts.contains(place.name)) {
            addressParts.add(place.name!);
          }
          
          _address = addressParts.isNotEmpty 
              ? addressParts.join(', ') 
              : '${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
        });
      } catch (e) {
        setState(() {
          _selectedLocation = result;
          _city = 'Seçili Konum';
          _district = '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
          _address = 'Konum: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}';
        });
      } finally {
        setState(() => _isLoading = false);
      }
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
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // ✨ CLUSTERING KONTROLÜ: Yakında benzer rapor var mı?
      print('🔍 Clustering: Yakın rapor kontrolü başlatılıyor...');
      final nearbyReportId = await _clusteringService.checkNearbyReport(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        category: _selectedCategory.value,
        radiusMeters: 20.0, // 20 metre yarıçap
      );

      // Eğer yakında rapor varsa, yeni rapor oluşturma - destek ekle
      if (nearbyReportId != null) {
        print('✅ Clustering: Yakın rapor bulundu, destek ekleniyor...');
        
        final success = await _clusteringService.addSupport(
          nearbyReportId,
          currentUser.uid,
        );
        
        if (success && mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎯 Bu sorun zaten bildirilmiş!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Desteğiniz eklendi ve bildirim sayısı artırıldı.'),
                  const SizedBox(height: 4),
                  Text(
                    'Rapor ID: $nearbyReportId',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return; // Yeni rapor oluşturma, fonksiyondan çık
      }

      print('✅ Clustering: Yakın rapor bulunamadı, yeni rapor oluşturuluyor...');

      // Firestore'dan kullanıcı bilgi lerini çek (varsa)
      String fullName = 'Anonim';
      try {
        print('🔍 Firestore\'dan kullanıcı bilgisi çekiliyor: ${currentUser.uid}');
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          fullName = userData['fullName'] ?? userData['name'] ?? 'Anonim';
          print('✅ Firestore kullanıcı bulundu: $fullName');
        } else {
          print('⚠️ Firestore\'da kullanıcı bulunamadı, Auth kullanılıyor');
          fullName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Kullanıcı';
          
          print('💾 Firestore\'a kullanıcı kaydediliyor...');
          await _firestore.collection('users').doc(currentUser.uid).set({
            'fullName': fullName,
            'email': currentUser.email,
            'role': 'citizen',
            'score': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('✅ Kullanıcı Firestore\'a kaydedildi');
        }
      } catch (e) {
        print('❌ Firestore hatası: $e');
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
        address: _address,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        imageUrlBefore: imageUrl,
      );

      if (report != null) {
        // 🆕 GAMIFICATION: Rapor oluşturma puanı ver
        try {
          await GamificationService().onReportCreated(
            currentUser.uid,
            report.id,
          );
          print('🎮 Gamification: +10 puan eklendi (rapor oluşturma)');
        } catch (e) {
          print('⚠️ Gamification hatası: $e');
        }
        
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ İhbar başarıyla oluşturuldu! +10 puan kazandınız!'),
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
                    const SizedBox(height: 8),
                    if (_address != null && _address!.isNotEmpty) ...[
                      Text(
                        _address!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _getCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Konumum'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _selectLocationFromMap,
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Haritadan Seç'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
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

// Haritadan Konum Seçme Ekranı
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? const LatLng(41.0082, 28.9784);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konum Seç'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context, _selectedLocation),
            icon: const Icon(Icons.check),
            tooltip: 'Onayla',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),
            mapType: MapType.terrain,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (latLng) {
              setState(() {
                _selectedLocation = latLng;
              });
            },
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedLocation,
                draggable: true,
                onDragEnd: (latLng) {
                  setState(() {
                    _selectedLocation = latLng;
                  });
                },
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
          ),
          
          // Bilgi Kartı
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Haritaya dokunun veya pini sürükleyin',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _selectedLocation),
                        icon: const Icon(Icons.check_circle),
                        label: const Text(
                          'Konumu Onayla',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
