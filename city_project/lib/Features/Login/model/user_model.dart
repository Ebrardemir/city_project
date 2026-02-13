class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String role; // Citizen, Municipality veya Admin
  final int score;
  final int cityId;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.score,
    required this.cityId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['Id'] ?? 0,
      fullName: json['FullName'] ?? '',
      email: json['Email'] ?? '',
      passwordHash: json['PasswordHash'] ?? '',
      role: json['Role'] ?? 'Citizen',
      score: json['Score'] ?? 0,
      cityId: json['CityId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'FullName': fullName,
      'Email': email,
      'PasswordHash': passwordHash,
      'Role': role,
      'Score': score,
      'CityId': cityId,
    };
  }
}
