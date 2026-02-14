import 'package:city_project/Features/CreateReport/view/create_report_view.dart';
import 'package:city_project/Features/Home/view/home_view.dart';
import 'package:city_project/Features/Login/view/login_view.dart';
import 'package:city_project/Features/Login/view/register_view.dart';
import 'package:city_project/Features/MyReports/model/report_model.dart';
import 'package:city_project/Features/NearbyReports/view/nearby_reports_view.dart';
import 'package:city_project/Features/Profile/view/profile_view.dart';
import 'package:city_project/Features/ReportDetail/view/report_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_router_constants.dart';
import 'package:city_project/Features/MyReports/view/my_reports_view.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login', // Uygulama giriş ekranıyla başlar
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
      GoRoute(
        name: AppRouterConstants.myReportsRouteName,
        path: '/my-reports',
        builder: (context, state) => const MyReportsView(),
      ),

      GoRoute(
        name: 'report-detail',
        path: '/report-detail',
        builder: (context, state) {
          final report = state.extra as ReportModel;
          return ReportDetailView(report: report);
        },
      ),
      GoRoute(
        name: AppRouterConstants.createReportRouteName,
        path: '/create-report',
        builder: (context, state) => const CreateReportView(),
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
                  label: 'Yakındaki İhbarlar',
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
                name: AppRouterConstants.nearbyReportsRouteName,
                path: '/nearby-reports',
                builder: (context, state) => const NearbyReportsView(),
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
