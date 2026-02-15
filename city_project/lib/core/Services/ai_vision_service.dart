import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

enum FakeDetectionReason {
  selfie('Selfie'),
  darkness('Karanlık'),
  blur('Bulanık'),
  indoor('İç Mekan'),
  screenCapture('Ekran Görüntüsü'),
  drawing('Çizim/Grafik'),
  none('Sahte Değil');

  final String label;
  const FakeDetectionReason(this.label);
}

class FakeDetectionResult {
  final bool isFake;
  final FakeDetectionReason reason;
  final double confidence; // 0.0 - 1.0 arası
  final List<String> detectedLabels;
  final String rawResponse;

  FakeDetectionResult({
    required this.isFake,
    required this.reason,
    required this.confidence,
    required this.detectedLabels,
    required this.rawResponse,
  });
}

/// Google Cloud Vision API ile yapay zeka destekli fake ihbar tespiti
class AIVisionService {
  final String _apiKey;
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';

  // İç mekan labels
  static const List<String> _indoorLabels = [
    'Indoor',
    'Room',
    'Ceiling',
    'Wall',
    'Floor',
    'Furniture',
    'Interior',
  ];

  AIVisionService({required String apiKey}) : _apiKey = apiKey;

  /// İmaj dosyasını Base64'e çevir
  Future<String> _encodeImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  /// Google Cloud Vision API'ye istek gönder
  Future<FakeDetectionResult> analyzeImage(File imageFile) async {
    try {
      print('🔍 AIVisionService: İmaj analiz ediliyor...');

      final base64Image = await _encodeImageToBase64(imageFile);

      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20},
              {'type': 'FACE_DETECTION', 'maxResults': 5},
              {'type': 'SAFE_SEARCH_DETECTION'},
            ],
          }
        ]
      };

      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print(
            '❌ AIVisionService: API hatası - ${response.statusCode}: ${response.body}');
        return FakeDetectionResult(
          isFake: false,
          reason: FakeDetectionReason.none,
          confidence: 0.0,
          detectedLabels: [],
          rawResponse: response.body,
        );
      }

      final jsonResponse = jsonDecode(response.body);
      print('✅ AIVisionService: API Yanıtı: ${jsonEncode(jsonResponse)}');

      return _analyzeFakeReport(jsonResponse);
    } catch (e) {
      print('❌ AIVisionService: Analiz hatası: $e');
      return FakeDetectionResult(
        isFake: false,
        reason: FakeDetectionReason.none,
        confidence: 0.0,
        detectedLabels: [],
        rawResponse: 'Error: $e',
      );
    }
  }

  /// API yanıtını analiz et ve fake olup olmadığını belirle
  FakeDetectionResult _analyzeFakeReport(dynamic apiResponse) {
    try {
      final responses = apiResponse['responses'] as List? ?? [];
      if (responses.isEmpty) {
        return FakeDetectionResult(
          isFake: false,
          reason: FakeDetectionReason.none,
          confidence: 0.0,
          detectedLabels: [],
          rawResponse: 'No responses',
        );
      }

      final response = responses[0] as Map<String, dynamic>;

      // Detected labels'ı al
      final labelAnnotations =
          (response['labelAnnotations'] as List? ?? []).cast<Map<String, dynamic>>();
      final detectedLabels =
          labelAnnotations.map((l) => l['description'].toString()).toList();

      print('🏷️ AIVisionService: Tespit edilen etiketler: $detectedLabels');

      // Yüz tespiti (selfie kontrolü)
      final faceAnnotations =
          (response['faceAnnotations'] as List? ?? []).cast<Map<String, dynamic>>();
      if (faceAnnotations.isNotEmpty) {
        print('👤 AIVisionService: Yüz tespit edildi - Selfie olabilir');
        return FakeDetectionResult(
          isFake: true,
          reason: FakeDetectionReason.selfie,
          confidence: 0.95,
          detectedLabels: detectedLabels,
          rawResponse: jsonEncode(response),
        );
      }

      // Safe Search analizi
      final safeSearchAnnotation = response['safeSearchAnnotation'] as Map? ?? {};
      if (safeSearchAnnotation.isNotEmpty) {
        final nsfw = safeSearchAnnotation['adult'] ?? 'UNKNOWN';
        print('🔒 AIVisionService: Safe Search: $nsfw');

        if (nsfw == 'VERY_LIKELY' || nsfw == 'LIKELY') {
          return FakeDetectionResult(
            isFake: true,
            reason: FakeDetectionReason.selfie,
            confidence: 0.9,
            detectedLabels: detectedLabels,
            rawResponse: jsonEncode(response),
          );
        }
      }

      // Şüpheli labels'ları analiz et
      for (final label in detectedLabels) {
        // Selfie kontrolü
        if (label.toLowerCase().contains('selfie') ||
            label.toLowerCase().contains('person')) {
          print(
              '📱 AIVisionService: Selfie etiketi bulundu: $label - Confidence: 0.9');
          return FakeDetectionResult(
            isFake: true,
            reason: FakeDetectionReason.selfie,
            confidence: 0.9,
            detectedLabels: detectedLabels,
            rawResponse: jsonEncode(response),
          );
        }

        // Bulanık görüntü kontrolü
        if (label.toLowerCase().contains('blur')) {
          print('🌫️ AIVisionService: Bulanık etiket bulundu: $label');
          return FakeDetectionResult(
            isFake: true,
            reason: FakeDetectionReason.blur,
            confidence: 0.85,
            detectedLabels: detectedLabels,
            rawResponse: jsonEncode(response),
          );
        }

        // Karanlık kontrolü
        if (label.toLowerCase().contains('darkness') ||
            label.toLowerCase().contains('dark') ||
            label.toLowerCase().contains('night')) {
          print('🌙 AIVisionService: Karanlık etiket bulundu: $label');
          return FakeDetectionResult(
            isFake: true,
            reason: FakeDetectionReason.darkness,
            confidence: 0.8,
            detectedLabels: detectedLabels,
            rawResponse: jsonEncode(response),
          );
        }

        // Ekran görüntüsü kontrolü
        if (label.toLowerCase().contains('screenshot') ||
            label.toLowerCase().contains('screen') ||
            label.toLowerCase().contains('monitor')) {
          print('📸 AIVisionService: Ekran görüntüsü etiket bulundu: $label');
          return FakeDetectionResult(
            isFake: true,
            reason: FakeDetectionReason.screenCapture,
            confidence: 0.9,
            detectedLabels: detectedLabels,
            rawResponse: jsonEncode(response),
          );
        }

        // Çizim/Grafik kontrolü
        if (label.toLowerCase().contains('drawing') ||
            label.toLowerCase().contains('sketch') ||
            label.toLowerCase().contains('art')) {
          print('🎨 AIVisionService: Çizim/Grafik etiket bulundu: $label');
          return FakeDetectionResult(
            isFake: true,
            reason: FakeDetectionReason.drawing,
            confidence: 0.85,
            detectedLabels: detectedLabels,
            rawResponse: jsonEncode(response),
          );
        }
      }

      // İç mekan kontrolü (kategori tarafından yapılmalı, ama uyarı verelim)
      final indoorCount = detectedLabels
          .where((label) =>
              _indoorLabels.any((indoor) =>
                  label.toLowerCase().contains(indoor.toLowerCase())))
          .length;

      if (indoorCount > 2) {
        print(
            '🏠 AIVisionService: Potansiyel iç mekan raporu - $indoorCount iç mekan etiketi bulundu');
        // İç mekan kategorileri için flagged olabilir ama auto-fake değil
      }

      // Herhangi bir uyumsuzluk bulunamadı - Sahte değil
      print('✅ AIVisionService: İmaj legitimate görülüyor');
      return FakeDetectionResult(
        isFake: false,
        reason: FakeDetectionReason.none,
        confidence: 0.95,
        detectedLabels: detectedLabels,
        rawResponse: jsonEncode(response),
      );
    } catch (e) {
      print('⚠️ AIVisionService: Yanıt analiz hatası: $e');
      return FakeDetectionResult(
        isFake: false,
        reason: FakeDetectionReason.none,
        confidence: 0.0,
        detectedLabels: [],
        rawResponse: 'Parse error: $e',
      );
    }
  }
}
