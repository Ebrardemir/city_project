import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_router_constants.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login', // Uygulama giriş ekranıyla başlar
    routes: [
      // --- 1. NAVBAR DIŞINDA KALANLAR (Giriş Ekranı vb.) ---
      GoRoute(
        name: AppRouterConstants.loginRouteName,
        path: '/login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text("GİRİŞ SAYFASI (LoginView)")),
        ),
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
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analiz'),
                BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mesajlar'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
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
                path: '/',
                builder: (context, state) => const Center(child: Text("ANA SAYFA")),
              ),
            ],
          ),
          // 1. İndeks: Analiz Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.analysisRouteName,
                path: '/analysis',
                builder: (context, state) => const Center(child: Text("ANALİZ SAYFASI")),
              ),
            ],
          ),
          // 2. İndeks: Mesajlar Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.messagesRouteName,
                path: '/messages',
                builder: (context, state) => const Center(child: Text("MESAJLAR SAYFASI")),
              ),
            ],
          ),
          // 3. İndeks: Profil Dalı
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.profileRouteName,
                path: '/profile',
                builder: (context, state) => const Center(child: Text("PROFİL SAYFASI")),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}