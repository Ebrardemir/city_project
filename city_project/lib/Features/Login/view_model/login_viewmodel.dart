import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel();
  
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

      // 🔄 Firestore Kontrolü
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          debugPrint('[Login] Yeni Google kullanıcısı, Firestore kaydı oluşturuluyor...');
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': user.displayName ?? 'Google Kullanıcısı',
            'email': user.email,
            'role': 'citizen',
            'score': 0,
            'districts': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('[Login] Firestore kaydı tamamlandı.');
        }
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
