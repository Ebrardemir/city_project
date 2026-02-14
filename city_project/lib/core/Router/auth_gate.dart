import 'package:city_project/Features/Login/view/login_view.dart';
import 'package:city_project/Features/Home/view/home_view.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Basitleştirilmiş Auth Gate - Firebase Auth durumuna göre yönlendirme yapar
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Bağlantı bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Kullanıcı giriş yapmış mı?
        if (snapshot.hasData) {
          return const HomeView();
        }

        // Kullanıcı giriş yapmamış
        return const LoginView();
      },
    );
  }
}
