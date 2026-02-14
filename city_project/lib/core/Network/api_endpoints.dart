class ApiEndpoints {
  ApiEndpoints._();

  static const AccountEndpoints account = AccountEndpoints();
}

/// Hesap işlemleri (Account)
class AccountEndpoints {
  const AccountEndpoints();

  // NOT: Önde '/' yok; baseUrl'e relatif.
  final String login = 'Account/Login';
  final String register = 'Account/Register';
  final String home = 'Home';

  final String getProfile = 'Account/GetProfile';

  final String updatePassword = 'Account/UpdatePassword';
}
