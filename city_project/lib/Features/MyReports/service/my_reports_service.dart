import '../../Home/model/report_model.dart';

class MyReportsService {
  Future<List<ReportModel>> fetchMyReports() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock image: network yerine placeholder kullan (backend gelince URL olacak)
    const img = 'https://picsum.photos/seed/';

    return [
      ReportModel(
        id: '1',
        userId: 'user_123',
        userFullName: 'Test Kullanıcı',
        city: 'İstanbul',
        district: 'Kadıköy',
        category: ReportCategory.road,
        description: 'Ana cadde üzerinde büyük çukur var, araçlar zorlanıyor.',
        latitude: 40.9897,
        longitude: 29.0272,
        imageUrlBefore: '${img}pothole/300/300',
        status: ReportStatus.pending,
        supportCount: 3,
        supportedUserIds: [],
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReportModel(
        id: '2',
        userId: 'user_123',
        userFullName: 'Test Kullanıcı',
        city: 'İstanbul',
        district: 'Kadıköy',
        category: ReportCategory.lighting,
        description: 'Park girişindeki lamba yanmıyor, akşam çok karanlık oluyor.',
        latitude: 40.9897,
        longitude: 29.0272,
        imageUrlBefore: '${img}lamp/300/300',
        status: ReportStatus.approved,
        supportCount: 7,
        supportedUserIds: [],
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      ),
      ReportModel(
        id: '3',
        userId: 'user_123',
        userFullName: 'Test Kullanıcı',
        city: 'İstanbul',
        district: 'Kadıköy',
        category: ReportCategory.garbage,
        description: 'Konteyner taşmış, çevresi çok kirli.',
        latitude: 40.9897,
        longitude: 29.0272,
        imageUrlBefore: '${img}trash/300/300',
        imageUrlAfter: '${img}trash_after/300/300',
        status: ReportStatus.resolved,
        supportCount: 12,
        supportedUserIds: [],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        resolvedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      ReportModel(
        id: '4',
        userId: 'user_123',
        userFullName: 'Test Kullanıcı',
        city: 'İstanbul',
        district: 'Kadıköy',
        category: ReportCategory.water,
        description: 'Kaldırım kenarında sürekli su akıyor.',
        latitude: 40.9897,
        longitude: 29.0272,
        imageUrlBefore: '${img}water/300/300',
        status: ReportStatus.fake,
        supportCount: 1,
        supportedUserIds: [],
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      ),
    ];
  }
}
