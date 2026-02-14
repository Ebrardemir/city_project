import '../../MyReports/model/report_model.dart';

class NearbyReportsService {
  Future<List<ReportModel>> fetchNearby() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Buradaki URL’ler internet yoksa düşer; ReportCard zaten asset fallback yapıyor olmalı
    const img = 'https://picsum.photos/seed/';

    return [
      ReportModel(
        id: 101,
        userId: 2,
        categoryId: 1,
        categoryName: 'Yol / Çukur',
        description: 'Sokak başında çukur var.',
        imageBeforeUrl: '${img}near1/400/400',
        imageAfterUrl: '',
        status: ReportStatus.pending,
        supportCount: 5,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        approvedAt: null,
        resolvedAt: null,
        lat: 41.0082,
        lng: 28.9784,
      ),
      ReportModel(
        id: 102,
        userId: 7,
        categoryId: 3,
        categoryName: 'Çöp / Temizlik',
        description: 'Konteyner taşmış, çevresi kirli.',
        imageBeforeUrl: '${img}near2/400/400',
        imageAfterUrl: '${img}near2_after/400/400',
        status: ReportStatus.resolved,
        supportCount: 18,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        approvedAt: DateTime.now().subtract(const Duration(days: 2, hours: 10)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        lat: 41.01,
        lng: 28.97,
      ),
    ];
  }
}
