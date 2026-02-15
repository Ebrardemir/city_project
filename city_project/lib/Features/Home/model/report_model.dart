import 'package:google_maps_flutter/google_maps_flutter.dart';

enum ReportCategory {
  road('Yol', 'road'),
  park('Park', 'park'),
  water('Su', 'water'),
  garbage('Çöp', 'garbage'),
  lighting('Aydınlatma', 'lighting'),
  other('Diğer', 'other');

  final String label;
  final String value;
  const ReportCategory(this.label, this.value);
}

enum ReportStatus {
  pending('Bekliyor', 'pending'),
  approved('Onaylandı', 'approved'),
  resolved('Çözüldü', 'resolved'),
  fake('Sahte', 'fake'),
  flagged('İşaretlendi', 'flagged');

  final String label;
  final String value;
  const ReportStatus(this.label, this.value);
}

enum FakeReportReason {
  selfie('Selfie', 'selfie'),
  darkness('Karanlık', 'darkness'),
  blur('Bulanık', 'blur'),
  indoor('İç Mekan', 'indoor'),
  screenCapture('Ekran Görüntüsü', 'screenCapture'),
  drawing('Çizim/Grafik', 'drawing'),
  unknown('Bilinmeyen', 'unknown');

  final String label;
  final String value;
  const FakeReportReason(this.label, this.value);
}

class ReportModel {
  final String id;
  final String userId;
  final String userFullName;
  final String city;
  final String district;
  final String? neighborhood; // Mahalle
  final String? street;       // Cadde/Sokak
  final String? address;
  final ReportCategory category;
  final String description;
  final double latitude;
  final double longitude;
  final String? imageUrlBefore;
  final String? imageUrlAfter;
  final ReportStatus status;
  final int supportCount;
  final List<String> supportedUserIds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  
  // AI-destekli fake detection fields
  final bool? isFakeDetected;
  final FakeReportReason? fakeReason;
  final double? fakeConfidence; // 0.0 - 1.0
  final List<String>? aiDetectedLabels;
  final DateTime? fakeDetectionTime;

  ReportModel({
    required this.id,
    required this.userId,
    required this.userFullName,
    required this.city,
    required this.district,
    this.neighborhood,
    this.street,
    this.address,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrlBefore,
    this.imageUrlAfter,
    required this.status,
    this.supportCount = 1,
    this.supportedUserIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.isFakeDetected,
    this.fakeReason,
    this.fakeConfidence,
    this.aiDetectedLabels,
    this.fakeDetectionTime,
  });

  LatLng get position => LatLng(latitude, longitude);

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userFullName: json['userFullName'] ?? 'Anonim',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      neighborhood: json['neighborhood'],
      street: json['street'],
      address: json['address'],
      category: ReportCategory.values.firstWhere(
        (e) => e.value == json['category'],
        orElse: () => ReportCategory.other,
      ),
      description: json['description'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      imageUrlBefore: json['imageUrlBefore'],
      imageUrlAfter: json['imageUrlAfter'],
      status: ReportStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      supportCount: json['supportCount'] ?? 1,
      supportedUserIds: json['supportedUserIds'] != null 
          ? List<String>.from(json['supportedUserIds'])
          : [],
      createdAt: json['createdAt'] != null 
          ? (json['createdAt'] is String 
              ? DateTime.parse(json['createdAt'])
              : (json['createdAt'] as dynamic).toDate())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? (json['updatedAt'] is String 
              ? DateTime.parse(json['updatedAt'])
              : (json['updatedAt'] as dynamic).toDate())
          : null,
      resolvedAt: json['resolvedAt'] != null 
          ? (json['resolvedAt'] is String 
              ? DateTime.parse(json['resolvedAt'])
              : (json['resolvedAt'] as dynamic).toDate())
          : null,
      // AI Detection fields
      isFakeDetected: json['isFakeDetected'],
      fakeReason: json['fakeReason'] != null
          ? FakeReportReason.values.firstWhere(
              (e) => e.value == json['fakeReason'],
              orElse: () => FakeReportReason.unknown,
            )
          : null,
      fakeConfidence: json['fakeConfidence']?.toDouble(),
      aiDetectedLabels: json['aiDetectedLabels'] != null
          ? List<String>.from(json['aiDetectedLabels'])
          : null,
      fakeDetectionTime: json['fakeDetectionTime'] != null
          ? (json['fakeDetectionTime'] is String
              ? DateTime.parse(json['fakeDetectionTime'])
              : (json['fakeDetectionTime'] as dynamic).toDate())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userFullName': userFullName,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'street': street,
      'address': address,
      'category': category.value,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrlBefore': imageUrlBefore,
      'imageUrlAfter': imageUrlAfter,
      'status': status.value,
      'supportCount': supportCount,
      'supportedUserIds': supportedUserIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'resolvedAt': resolvedAt,
      // AI Detection fields
      'isFakeDetected': isFakeDetected,
      'fakeReason': fakeReason?.value,
      'fakeConfidence': fakeConfidence,
      'aiDetectedLabels': aiDetectedLabels,
      'fakeDetectionTime': fakeDetectionTime,
    };
  }
}
