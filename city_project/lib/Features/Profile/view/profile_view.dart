import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodel/profile_view_model.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats.dart';
import '../widgets/profile_menu.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ProfileViewModel>().fetchProfile());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    // final theme = Theme.of(context);

    if (vm.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.profile == null) {
       return const Scaffold(
        body: Center(child: Text("Profil yüklenemedi")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Ayarlar sayfası
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Header
            ProfileHeader(user: vm.profile!.user),
            const SizedBox(height: 24),
            
            // 🎮 Gamification Card
            _buildGamificationCard(vm.profile!.user.score),
            const SizedBox(height: 24),
            
            // Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ProfileStats(
                  reports: vm.profile!.reportsCount,
                  supported: vm.profile!.supportedCount,
                  resolved: vm.profile!.resolvedCount,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Menu
            Card(
              child: ProfileMenu(
                onMyReportsTap: () {
                  context.push('/my-reports');
                },
                onCreateReportTap: () {
                  context.push('/create-report');
                },
                onLogoutTap: () async {
                  try {
                    await context.read<ProfileViewModel>().logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Başarıyla çıkış yapıldı'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Çıkış yapılırken hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
            
            const SizedBox(height: 16),
                                  // 🔧 DEBUG: Rol Değiştirme Butonu
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final newRole = await context.read<ProfileViewModel>().changeRole();
                                        if (context.mounted && newRole != null) {
                                          // Role göre yönlendirme
                                          String targetRoute;
                                          if (newRole == 'municipality') {
                                            targetRoute = '/municipality-dashboard';
                                          } else if (newRole == 'admin') {
                                            targetRoute = '/admin-dashboard';
                                          } else {
                                            targetRoute = '/home';
                                          }
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('🔄 Rol değiştirildi: $newRole'),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                          
                                          // Yeni sayfaya yönlendir
                                          await Future.delayed(const Duration(milliseconds: 500));
                                          if (context.mounted) {
                                            context.go(targetRoute);
                                          }
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Rol değiştirilemedi: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.swap_horiz),
                                    label: const Text('DEBUG: Rol Değiştir'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[800],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
          ],
        ),
      ),
    );
  }

  /// Gamification puan kartı
  Widget _buildGamificationCard(int score) {
    // Rozet hesaplama
    String badge;
    IconData icon;
    Color color;
    int nextBadge;
    
    if (score < 100) {
      badge = '🌱 Yeni Başlayan';
      icon = Icons.star_border;
      color = Colors.grey;
      nextBadge = 100 - score;
    } else if (score < 500) {
      badge = '🥉 Bronz';
      icon = Icons.star_half;
      color = Colors.brown;
      nextBadge = 500 - score;
    } else if (score < 1000) {
      badge = '🥈 Gümüş';
      icon = Icons.star;
      color = Colors.grey.shade300;
      nextBadge = 1000 - score;
    } else if (score < 5000) {
      badge = '🥇 Altın';
      icon = Icons.star;
      color = Colors.amber;
      nextBadge = 5000 - score;
    } else {
      badge = '💎 Elmas';
      icon = Icons.diamond;
      color = Colors.blue;
      nextBadge = 0;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Toplam Puan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: 40,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Rozet Göstergesi
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (nextBadge > 0)
                      Text(
                        'Sonraki rozete $nextBadge puan kaldı',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Liderlik Tablosu Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/leaderboard');
              },
              icon: const Icon(Icons.leaderboard, size: 18),
              label: const Text('Liderlik Tablosunu Gör'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
