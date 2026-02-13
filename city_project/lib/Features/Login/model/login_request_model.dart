class LoginRequestModel {
  final String email; // TCKN yerine Email kullanıyoruz
  final String password;

  LoginRequestModel({required this.email, required this.password});

  // API'nin beklediği JSON formatına çevirme
  Map<String, dynamic> toJson() {
    return {'Email': email, 'Password': password};
  }
}
