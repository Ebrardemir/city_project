import 'dart:async';
import 'package:city_project/Features/Home/view/home_view.dart';
import 'package:city_project/Features/Login/view/login_view.dart';
import 'package:city_project/Features/Login/view/register_view.dart';
import 'package:city_project/Features/Profile/view/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_router_constants.dart';

/// Firebase Auth durumunu dinleyen basit bir notifier
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRouter {
  static final _authNotifier = AuthNotifier();

  static final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: _authNotifier,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final goingToLogin =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isLoggedIn && !goingToLogin) {
        return '/login';
      }
      if (isLoggedIn && goingToLogin) {
        return '/home';
      }
      return null;
    },
    routes: [
      // --- 1. NAVBAR DIŞINDA KALANLAR (Giriş Ekranı vb.) ---
      GoRoute(
        name: AppRouterConstants.loginRouteName,
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        name: AppRouterConstants.registerRouteName,
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),

      // --- 2. NAVBAR İLE GÖRÜNECEK SAYFALAR (Ana Yapı) ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell, // Aktif olan sayfa burada görünür
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ev'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics),
                  label: 'İlçeler',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'Mesajlar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ],
              onTap: (index) => navigationShell.goBranch(index),
            ),
          );
        },
        branches: [
          // 0. İndeks: Ana Sayfa Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.homeRouteName,
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          // 1. İndeks: Analiz Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.analysisRouteName,
                path: '/analysis',
                builder: (context, state) =>
                    const Center(child: Text("ANALİZ SAYFASI")),
              ),
            ],
          ),
          // 2. İndeks: Mesajlar Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.messagesRouteName,
                path: '/messages',
                builder: (context, state) =>
                    const Center(child: Text("MESAJLAR SAYFASI")),
              ),
            ],
          ),
          // 3. İndeks: Profil Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.profileRouteName,
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
