import '../model/profile_response.dart';
import '../../Login/model/user_model.dart'; // pathini projene göre ayarla

class ProfileService {
  Future<ProfileResponse> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // MOCK USER
    final mockUser = UserModel(
      id: 1,
      fullName: "Ahmet Yılmaz",
      email: "ahmet@citypulse.com",
      role: "Citizen",
      score: 1250,
      cityId: 34,
      cityName: "İstanbul",
    );

    // MOCK PROFILE RESPONSE
    return ProfileResponse(
      user: mockUser,
      reportsCount: 12,
      supportedCount: 7,
      resolvedCount: 5,
    );
  }
}
