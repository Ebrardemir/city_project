

import 'package:city_project/Features/Login/model/user_model.dart';

class ProfileResponse {
  final UserModel user;
  final int reportsCount;
  final int supportedCount;
  final int resolvedCount;

  ProfileResponse({
    required this.user,
    required this.reportsCount,
    required this.supportedCount,
    required this.resolvedCount,
  });
}