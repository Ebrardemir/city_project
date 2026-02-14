import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id; // Firebase UID
  final String fullName;
  final String email;
  final String role; // "citizen" | "municipality" | "admin"
  final int score;
  final String? city; // İl (İstanbul, Ankara)
  final String? district; // İlçe (Kadıköy, Çankaya)
  final List<String> districts; // Belediye için sorumlu ilçeler
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.score = 0,
    this.city,
    this.district,
    this.districts = const [],
    required this.createdAt,
  });

  // Firestore'dan okuma
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('User document is empty');
    }
    
    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'citizen',
      score: data['score'] ?? 0,
      city: data['city'],
      district: data['district'],
      districts: List<String>.from(data['districts'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // JSON'dan okuma (eski uyumluluk için)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      role: json['role'] ?? json['Role'] ?? 'citizen',
      score: json['score'] ?? json['Score'] ?? 0,
      city: json['city'] ?? json['CityName'],
      district: json['district'],
      districts: json['districts'] != null 
          ? List<String>.from(json['districts'])
          : [],
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
    );
  }

  // Firestore'a yazma
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'score': score,
      'city': city,
      'district': district,
      'districts': districts,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // JSON'a dönüştürme (eski uyumluluk için)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'score': score,
      'city': city,
      'district': district,
      'districts': districts,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Belediye yetkilisi mi?
  bool get isMunicipality => role == 'municipality';
  
  // Admin mi?
  bool get isAdmin => role == 'admin';
  
  // Normal vatandaş mı?
  bool get isCitizen => role == 'citizen';
}
