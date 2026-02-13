import 'package:city_project/Features/Login/model/login_request_model.dart';
import 'package:city_project/Features/Login/model/login_response_model.dart';
import 'package:city_project/Features/Login/model/user_model.dart'; // Eklendi
import 'package:city_project/core/Network/network_exceptions.dart';
import 'package:dio/dio.dart';
import '../../../core/Network/api_endpoints.dart';
import '../../../core/logger/logger.dart';

class LoginService {
  final Dio _dio;
  LoginService(this._dio);

  Future<LoginResponseModel> login(LoginRequestModel requestModel) async {
    try {
      /* // API HAZIR OLDUĞUNDA BURAYI AÇACAKSIN:
      final response = await _dio.post(
        ApiEndpoints.account.login, // Endpoint ismini güncelledik
        data: requestModel.toJson(),
        options: Options(
          extra: const {'requiresAuth': false},
        ),
      );
      return LoginResponseModel.fromJson(response.data);
      */

      // --- MOCK (SAHTE) VERİ BAŞLANGICI ---
      // API henüz hazır olmadığı için UI tarafını test etmen adına sahte bir cevap dönüyoruz:
      await Future.delayed(
        const Duration(seconds: 2),
      ); // 2 saniye bekleme efekti

      return LoginResponseModel(
        accessToken: "dummy_access_token_12345",
        refreshToken: "dummy_refresh_token_67890",
        user: UserModel(
          id: 1,
          fullName: "Test Kullanıcı",
          email: requestModel.email, // Girdiğin email ile eşleşsin
          passwordHash: "********",
          role: "Citizen",
          score: 100,
          cityId: 34,
        ),
      );
      // --- MOCK VERİ BİTİŞİ ---
    } on DioException catch (e) {
      log.e(
        'DioException in LoginService: ${e.message}',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw mapDioErrorToNetworkException(e);
    } catch (e) {
      log.e('An unexpected error occurred in LoginService', error: e);
      throw NetworkException("Beklenmedik bir hata oluştu: ${e.toString()}");
    }
  }
}
