import '../model/report_model.dart';

class MyReportsService {
  Future<List<ReportModel>> fetchMyReports() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Mock image: network yerine placeholder kullan (backend gelince URL olacak)
    const img = 'https://picsum.photos/seed/';

    return [
      ReportModel(
        id: 1,
        categoryName: 'Yol / Çukur',
        description: 'Ana cadde üzerinde büyük çukur var, araçlar zorlanıyor.',
        imageBeforeUrl: '${img}pothole/300/300',
        status: ReportStatus.pending,
        supportCount: 3,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)), userId: 1, categoryId: 1, lat: 1, lng: 1,
      ),
      ReportModel(
        id: 2,
        categoryName: 'Sokak Lambası',
        description: 'Park girişindeki lamba yanmıyor, akşam çok karanlık oluyor.',
        imageBeforeUrl: '${img}lamp/300/300',
        status: ReportStatus.approved,
        supportCount: 7,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)), userId: 1, categoryId: 1, lat: 1, lng: 1,
      ),
      ReportModel(
        id: 3,
        categoryName: 'Çöp / Temizlik',
        description: 'Konteyner taşmış, çevresi çok kirli.',
        imageBeforeUrl: '${img}trash/300/300',
        status: ReportStatus.resolved,
        supportCount: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        imageAfterUrl: '${img}trash_after/300/300', userId: 1, categoryId: 1, lat: 1, lng: 1,
      ),
      ReportModel(
        id: 4,
        categoryName: 'Su Sızıntısı',
        description: 'Kaldırım kenarında sürekli su akıyor.',
        imageBeforeUrl: '${img}water/300/300',
        status: ReportStatus.fake,
        supportCount: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)), userId: 1, categoryId: 1, lat: 1, lng: 1,
      ),
    ];
  }
}
