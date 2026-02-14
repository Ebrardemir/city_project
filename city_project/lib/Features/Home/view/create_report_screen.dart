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
  // Services
  final _reportService = ReportService();
  final _imageService = ImageUploadService();
  final _locationService = LocationService();
  final _clusteringService = ClusteringService();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers
  final _descriptionController = TextEditingController();
  final _pageController = PageController();

  // State
  int _currentStep = 0;
  bool _isLoading = false;

  // Form Data
  File? _selectedImage;
  LatLng? _selectedLocation;
  String? _city;
  String? _district;
  String? _neighborhood; 
  String? _street;       
  String? _address;
  ReportCategory _selectedCategory = ReportCategory.road;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    
    // Eğer başlangıç konumu varsa adresi çözümle
    if (_selectedLocation != null) {
      _resolveAddress(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // --- LOGIC: ADDRESS & LOCATION ---

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final loc = LatLng(position.latitude, position.longitude);
        await _resolveAddress(loc);
      }
    } catch (e) {
      debugPrint('Sihirbaz Konum Hatası: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resolveAddress(LatLng location) async {
    try {
      final place = await _locationService.getAddressFromLatLng(
        location.latitude,
        location.longitude,
      );

      setState(() {
        _selectedLocation = location;
        _city = place?.administrativeArea ?? 'Bilinmeyen';
        _district = place?.subAdministrativeArea ?? place?.locality ?? 'Bilinmeyen';
        _neighborhood = place?.subLocality;
        _street = place?.thoroughfare ?? place?.street;
        
        final addressParts = <String>[];
        if (_street != null && _street!.isNotEmpty) addressParts.add(_street!);
        if (_neighborhood != null && _neighborhood!.isNotEmpty) addressParts.add(_neighborhood!);
        if (_district != null) addressParts.add(_district!);
        
        _address = addressParts.isNotEmpty 
            ? addressParts.join(', ') 
            : '${location.latitude}, ${location.longitude}';
      });
    } catch (e) {
      debugPrint('Adres Çözümleme Hatası: $e');
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf hatası: $e')),
      );
    }
  }

  // --- LOGIC: NAVIGATION & SUBMIT ---

  void _nextStep() {
    // Validations
    if (_currentStep == 0 && _selectedImage == null) {
      _showError('Lütfen bir fotoğraf ekleyin');
      return;
    }
    if (_currentStep == 1 && _selectedLocation == null) {
      _showError('Lütfen sorunun konumunu belirleyin');
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      _submitReport();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Lütfen kısa bir açıklama yazın');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Oturum kapalı');

      // 1. Clustering Check
      final nearbyId = await _clusteringService.checkNearbyReport(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        category: _selectedCategory.value,
        radiusMeters: 20.0,
      );

      if (nearbyId != null) {
        // Var olan rapora destek ver
        final success = await _clusteringService.addSupport(nearbyId, currentUser.uid);
        if (success && mounted) {
           Navigator.of(context).pop(true);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu sorun zaten bildirilmiş! Desteğiniz eklendi.'),
              backgroundColor: Colors.orange,
            ),
           );
        }
        return;
      }

      // 2. Kullanıcı Bilgisi
      String fullName = currentUser.displayName ?? 'Kullanıcı';
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          fullName = userDoc.data()?['fullName'] ?? fullName;
        } else {
          // Eğer profil yoksa oluştur
          await _firestore.collection('users').doc(currentUser.uid).set({
             'fullName': fullName,
             'email': currentUser.email,
             'role': 'citizen',
             'score': 0,
             'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (_) {}

      // 3. Resim Yükle
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _imageService.uploadReportImage(
          imageFile: _selectedImage!,
          userId: currentUser.uid,
        );
      }

      // 4. Raporu Kaydet
      final report = await _reportService.createReport(
        userId: currentUser.uid,
        userFullName: fullName,
        city: _city ?? widget.city ?? 'Bilinmeyen',
        district: _district ?? widget.district ?? 'Bilinmeyen',
        neighborhood: _neighborhood,
        street: _street,
        address: _address,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        imageUrlBefore: imageUrl,
      );

      if (report != null) {
        // Puan Kazan
        await GamificationService().onReportCreated(currentUser.uid, report.id);
        
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Raporunuz başarıyla oluşturuldu! +10 Puan'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

    } catch (e) {
      _showError('Hata: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Yeni İhbar', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Helper Text
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _getStepTitle(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Main Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Kaydırmayı kapat
                children: [
                  _buildStep1Evidence(),
                  _buildStep2Location(),
                  _buildStep3Details(),
                ],
              ),
            ),
            
            // Bottom Action Bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Fotoğraf Çek';
      case 1: return 'Konumu Doğrula';
      case 2: return 'Detayları Gir';
      default: return '';
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: _isLoading ? null : _prevStep,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            )
          else
            const SizedBox(width: 80), // Spacer

          // Steps Indicator (Dots)
          Row(
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentStep == index ? Colors.amber : Colors.grey[300],
                ),
              );
            }),
          ),

          // Next/Finish Button
          ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_currentStep == 2 ? 'Gönder' : 'İleri'),
          ),
        ],
      ),
    );
  }

  // --- STEP 1: EVIDENCE (Proof) ---
  Widget _buildStep1Evidence() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedImage == null) ...[
            _buildBigButton(
              icon: Icons.camera_alt_rounded,
              label: 'Kamerayı Aç',
              onTap: () => _pickImage(ImageSource.camera),
              color: Colors.blue[50]!,
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 20),
            _buildBigButton(
              icon: Icons.photo_library_rounded,
              label: 'Galeriden Seç',
              onTap: () => _pickImage(ImageSource.gallery),
              color: Colors.purple[50]!,
              iconColor: Colors.purple,
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImage!,
                height: 400,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => setState(() => _selectedImage = null),
              icon: const Icon(Icons.refresh),
              label: const Text('Fotoğrafı Değiştir'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBigButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: iconColor.withOpacity(0.3), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 64, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: LOCATION ---
  Widget _buildStep2Location() {
    return Stack(
      children: [
        if (_selectedLocation == null && _isLoading)
           const Center(child: CircularProgressIndicator())
        else
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLocation ?? const LatLng(41.0082, 28.9784),
            zoom: 15,
          ),
          onMapCreated: (controller) {
            // Harita stilini burada ayarlayabilirsiniz
          },
          onTap: (latLng) {
            _resolveAddress(latLng);
          },
          markers: _selectedLocation != null ? {
            Marker(
              markerId: const MarkerId('selected'),
              position: _selectedLocation!,
              infoWindow: const InfoWindow(title: 'Sorun Burada'),
            ),
          } : {},
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        
        // Location Fab
        Positioned(
          right: 16,
          top: 16,
          child: FloatingActionButton(
            heroTag: 'loc_btn',
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.black87),
            onPressed: _getCurrentLocation,
          ),
        ),

        // Address Card
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Seçilen Adres:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _address ?? 'Konum seçilmedi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: DETAILS ---
  Widget _buildStep3Details() {
    final categories = ReportCategory.values.where((c) => c != ReportCategory.other).toList();
    // Diğer'i sona ekle
    categories.add(ReportCategory.other);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Sorun Kategorisi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = _selectedCategory == cat;
            return InkWell(
              onTap: () => setState(() => _selectedCategory = cat),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.amber[100] : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.amber : Colors.grey[200]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(cat),
                      size: 32,
                      color: isSelected ? Colors.black : Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 32),
        
        const Text(
          'Açıklama',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Sorunu kısaca açıklayın...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(ReportCategory cat) {
    switch (cat) {
      case ReportCategory.road: return Icons.add_road;
      case ReportCategory.park: return Icons.park;
      case ReportCategory.water: return Icons.water_drop;
      case ReportCategory.garbage: return Icons.delete;
      case ReportCategory.lighting: return Icons.lightbulb;
      default: return Icons.error_outline;
    }
  }
}

