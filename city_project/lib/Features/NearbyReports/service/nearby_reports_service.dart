import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Home/model/report_model.dart';

class NearbyReportsService {
  final _firestore = FirebaseFirestore.instance;

  /// Belirtilen konuma göre raporları getirir
  /// [city] zorunludur.
  /// [district] verilirse sadece o ilçeyi, verilmezse tüm şehri getirir.
  Future<List<ReportModel>> fetchReportsByLocation({
    required String city,
    String? district,
  }) async {
    try {
      print('🔍 Fetching reports for City: $city, District: ${district ?? "ALL"}');
      
      Query query = _firestore.collection('reports')
          .where('city', isEqualTo: city);

      if (district != null) {
        query = query.where('district', isEqualTo: district);
      }

      // Firestore composite index hatası almamak için şimdilik client-side sort
      // .orderBy('createdAt', descending: true); 

      final snapshot = await query.get();
      
      final reports = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; 
        return ReportModel.fromJson(data);
      }).toList();

      // Tarihe göre yeniden eskiye sırala
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Found ${reports.length} reports.');
      return reports;
    } catch (e) {
      print('❌ ReportService Error: $e');
      return [];
    }
  }

  /// Veritabanında (Firestore reports) bulunan benzersiz şehirleri getirir
  Future<List<String>> getAvailableCities() async {
    try {
      // Not: Firestore'da "distinct" sorgusu yoktur.
      // Bu yüzden tüm raporları (veya makul bir kısmını) çekip burada filtreliyoruz.
      // Gerçek projelerde bu iş için ayrı bir "locations" koleksiyonu tutulmalıdır.
      final snapshot = await _firestore.collection('reports').get();
      
      final cities = snapshot.docs
          .map((doc) => doc.data()['city'] as String?)
          .where((city) => city != null && city.isNotEmpty)
          .toSet()
          .toList();

      cities.sort(); // Alfabetik sıra
      return List<String>.from(cities);
    } catch (e) {
      print('❌ getAvailableCities hata: $e');
      return [];
    }
  }
  
  /// Seçili şehirde kaydı olan ilçeleri getirir
  Future<List<String>> getAvailableDistricts(String city) async {
    try {
      final snapshot = await _firestore.collection('reports')
          .where('city', isEqualTo: city)
          .get();
          
      final districts = snapshot.docs
          .map((doc) => doc.data()['district'] as String?)
          .where((d) => d != null && d.isNotEmpty)
          .toSet()
          .toList();

      districts.sort();
      return List<String>.from(districts);
    } catch (e) {
      print('❌ getAvailableDistricts hata: $e');
      return [];
    }
  }
}
