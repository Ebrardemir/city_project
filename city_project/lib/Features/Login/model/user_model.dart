class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role; // Citizen, Municipality veya Admin
  final int score;
  final int cityId;
  final String? cityName;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.score,
    required this.cityId,
    this.cityName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['Id'] ?? 0,
      fullName: json['FullName'] ?? '',
      email: json['Email'] ?? '',
      role: json['Role'] ?? 'Citizen',
      score: json['Score'] ?? 0,
      cityId: json['CityId'] ?? 0,
      cityName: json['CityName'] ?? null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'FullName': fullName,
      'Email': email,
      'Role': role,
      'Score': score,
      'CityId': cityId,
      'CityName': cityName,
    };
  }
}
