import 'user_model.dart';

class LoginResponseModel {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  LoginResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      // JSON içindeki 'User' anahtarını UserModel.fromJson ile parse ediyoruz
      user: UserModel.fromJson(json['User'] ?? {}),
      accessToken: json['AccessToken'] ?? '',
      refreshToken: json['RefreshToken'] ?? '',
    );
  }
}
