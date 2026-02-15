import 'dart:async';
import 'package:city_project/Features/CreateReport/view/create_report_view.dart';
import 'package:city_project/Features/Home/view/home_view.dart';
import 'package:city_project/Features/Login/view/login_view.dart';
import 'package:city_project/Features/Login/view/register_view.dart';
import 'package:city_project/Features/Home/model/report_model.dart';
import 'package:city_project/Features/NearbyReports/view/nearby_reports_view.dart';
import 'package:city_project/Features/Profile/view/profile_view.dart';
import 'package:city_project/Features/ReportDetail/view/report_detail_view.dart';
import 'package:city_project/Features/Municipality/view/municipality_dashboard_view.dart';
import 'package:city_project/Features/Municipality/view/municipality_statistics_view.dart';
import 'package:city_project/Features/Admin/view/admin_dashboard_view.dart';
import 'package:city_project/Features/Admin/view/admin_users_view.dart';
import 'package:city_project/Features/Admin/view/admin_reports_view.dart';
import 'package:city_project/Features/Leaderboard/view/leaderboard_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_router_constants.dart';
import 'package:city_project/Features/MyReports/view/my_reports_view.dart';

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
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final goingToLogin =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Giriş yapmamış kullanıcıyı login'e yönlendir
      if (!isLoggedIn && !goingToLogin) {
        return '/login';
      }
      
      // Giriş yapmış kullanıcı login/register'daysa ana sayfaya yönlendir
      if (isLoggedIn && goingToLogin) {
        // Kullanıcı rolünü kontrol et
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          final role = userDoc.data()?['role'] ?? 'citizen';
          
          // Role göre yönlendirme
          if (role == 'municipality') {
            return '/municipality-dashboard';
          } else if (role == 'admin') {
            return '/admin-dashboard';
          } else {
            return '/home';
          }
        } catch (e) {
          print('❌ Role kontrolü hatası: $e');
          return '/home';
        }
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
      GoRoute(
        name: 'leaderboard',
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardView(),
      ),

      // --- 2. VATANDAŞ (CITIZEN) - NAVBAR İLE ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
                BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Yakındaki'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Raporlarım'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              ],
              onTap: (index) => navigationShell.goBranch(index),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.homeRouteName,
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.nearbyReportsRouteName,
                path: '/nearby-reports',
                builder: (context, state) => const NearbyReportsView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouterConstants.myReportsRouteName,
                path: '/my-reports',
                builder: (context, state) => const MyReportsView(),
              ),
            ],
          ),
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
      
      // --- 3. BELEDİYE (MUNICIPALITY) - NAVBAR İLE ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              selectedItemColor: Colors.deepOrange,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Panel'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'İstatistik'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              ],
              onTap: (index) => navigationShell.goBranch(index),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'municipality-dashboard',
                path: '/municipality-dashboard',
                builder: (context, state) => const MunicipalityDashboardView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'municipality-statistics',
                path: '/municipality-statistics',
                builder: (context, state) => const MunicipalityStatisticsView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'municipality-profile',
                path: '/municipality-profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
      
      // --- 4. ADMİN - NAVBAR İLE ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: navigationShell.currentIndex,
              selectedItemColor: Colors.purple,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Kullanıcılar'),
                BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Raporlar'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
              ],
              onTap: (index) => navigationShell.goBranch(index),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'admin-dashboard',
                path: '/admin-dashboard',
                builder: (context, state) => const AdminDashboardView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'admin-users',
                path: '/admin-users',
                builder: (context, state) => const AdminUsersView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'admin-reports',
                path: '/admin-reports',
                builder: (context, state) => const AdminReportsView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'admin-profile',
                path: '/admin-profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
