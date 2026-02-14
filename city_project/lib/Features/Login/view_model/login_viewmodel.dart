import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../service/login_service.dart';
import '../../../core/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final LoginService _loginService;
  final AuthService _authService;

  LoginViewModel(this._loginService, this._authService);

  // Controller'lar veriyi arayüzden çekmek için kullanılır
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Firebase Email/Password ile giriş
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      debugPrint("[Login] Firebase ile giriş başarılı");
    } on FirebaseAuthException catch (e) {
      debugPrint('[Login] FirebaseAuthException: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('[Login] Bilinmeyen hata: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..setCustomParameters({'prompt': 'select_account'});
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn(scopes: ['email']).signIn();
        if (googleUser == null) {
          throw Exception('Kullanıcı Google girişini iptal etti');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      debugPrint('[Login] Google ile giriş başarılı');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Login] FirebaseAuthException: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('[Login] Google giriş hatası: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
