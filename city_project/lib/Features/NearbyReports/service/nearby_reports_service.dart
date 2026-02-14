import '../../Home/model/report_model.dart';

class NearbyReportsService {
  Future<List<ReportModel>> fetchNearby() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Buradaki URL’ler internet yoksa düşer; ReportCard zaten asset fallback yapıyor olmalı
    const img = 'https://picsum.photos/seed/';

    return [
      ReportModel(
        id: '101',
        userId: 'user_456',
        userFullName: 'Ahmet Yılmaz',
        city: 'İstanbul',
        district: 'Beşiktaş',
        category: ReportCategory.road,
        description: 'Sokak başında çukur var.',
        latitude: 41.0082,
        longitude: 28.9784,
        imageUrlBefore: '${img}near1/400/400',
        status: ReportStatus.pending,
        supportCount: 5,
        supportedUserIds: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      ReportModel(
        id: '102',
        userId: 'user_789',
        userFullName: 'Mehmet Demir',
        city: 'İstanbul',
        district: 'Beşiktaş',
        category: ReportCategory.garbage,
        description: 'Konteyner taşmış, çevresi kirli.',
        latitude: 41.01,
        longitude: 28.97,
        imageUrlBefore: '${img}near2/400/400',
        imageUrlAfter: '${img}near2_after/400/400',
        status: ReportStatus.resolved,
        supportCount: 18,
        supportedUserIds: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 10)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }
}
