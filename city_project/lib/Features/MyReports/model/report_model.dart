enum ReportStatus { pending, approved, resolved, fake }

class ReportModel {
  final int id;
  final int userId;

  final int categoryId;
  final String categoryName;

  final String description;

  final String imageBeforeUrl;
  final String? imageAfterUrl;

  final ReportStatus status;
  final int supportCount;

  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? resolvedAt;

  final double lat;
  final double lng;

  ReportModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.imageBeforeUrl,
    this.imageAfterUrl,
    required this.status,
    required this.supportCount,
    required this.createdAt,
    this.approvedAt,
    this.resolvedAt,
    required this.lat,
    required this.lng,
  });
}
