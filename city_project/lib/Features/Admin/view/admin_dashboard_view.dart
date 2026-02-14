import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Dashboard - Sistem yönetim ekranı
class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh logic
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh logic
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // İstatistik Kartları
            _buildStatsGrid(),
            
            const SizedBox(height: 24),
            
            // Son Aktiviteler
            _buildRecentActivities(),
            
            const SizedBox(height: 24),
            
            // Hızlı Erişim
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        final totalUsers = usersSnapshot.data?.docs.length ?? 0;
        final citizens = usersSnapshot.data?.docs
            .where((doc) => (doc.data() as Map)['role'] == 'citizen')
            .length ?? 0;
        final municipalities = usersSnapshot.data?.docs
            .where((doc) => (doc.data() as Map)['role'] == 'municipality')
            .length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
          builder: (context, reportsSnapshot) {
            final totalReports = reportsSnapshot.data?.docs.length ?? 0;
            final pendingReports = reportsSnapshot.data?.docs
                .where((doc) => (doc.data() as Map)['status'] == 'pending')
                .length ?? 0;
            final resolvedReports = reportsSnapshot.data?.docs
                .where((doc) => (doc.data() as Map)['status'] == 'resolved')
                .length ?? 0;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard('Toplam Kullanıcı', '$totalUsers', Icons.people, Colors.blue),
                _buildStatCard('Vatandaşlar', '$citizens', Icons.person, Colors.green),
                _buildStatCard('Belediyeler', '$municipalities', Icons.business, Colors.orange),
                _buildStatCard('Toplam Rapor', '$totalReports', Icons.report, Colors.purple),
                _buildStatCard('Bekleyen', '$pendingReports', Icons.hourglass_empty, Colors.amber),
                _buildStatCard('Çözülen', '$resolvedReports', Icons.check_circle, Colors.teal),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Son Aktiviteler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data!.docs;
                if (reports.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Henüz aktivite yok'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = reports[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.report, size: 20),
                      title: Text(
                        data['description'] ?? 'Açıklama yok',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${data['city']} - ${data['district']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Chip(
                        label: Text(
                          data['status'] ?? 'pending',
                          style: const TextStyle(fontSize: 10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı Erişim',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2,
          children: [
            _buildActionButton('Kullanıcılar', Icons.people, Colors.blue, () {}),
            _buildActionButton('Raporlar', Icons.report, Colors.orange, () {}),
            _buildActionButton('İstatistikler', Icons.analytics, Colors.purple, () {}),
            _buildActionButton('Ayarlar', Icons.settings, Colors.grey, () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
