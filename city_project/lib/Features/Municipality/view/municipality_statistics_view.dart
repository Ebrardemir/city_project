import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

/// Belediye İstatistikleri - Rapor ve performans metrikleri
class MunicipalityStatisticsView extends StatelessWidget {
  const MunicipalityStatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 İstatistikler'),
      ),
      body: currentUser == null
          ? const Center(child: Text('Giriş yapmalısınız'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser.uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                final districts = List<String>.from(userData?['districts'] ?? []);
                
                if (districts.isEmpty) {
                  return const Center(
                    child: Text('İlçe bilgisi bulunamadı'),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('district', whereIn: districts)
                      .snapshots(),
                  builder: (context, reportsSnapshot) {
                    if (!reportsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reports = reportsSnapshot.data!.docs;
                    final pending = reports.where((doc) => 
                        (doc.data() as Map)['status'] == 'pending').length;
                    final approved = reports.where((doc) => 
                        (doc.data() as Map)['status'] == 'approved').length;
                    final resolved = reports.where((doc) => 
                        (doc.data() as Map)['status'] == 'resolved').length;
                    final fake = reports.where((doc) => 
                        (doc.data() as Map)['status'] == 'fake').length;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Toplam İstatistikler
                        _buildSummaryCard(
                          'Toplam Raporlar',
                          reports.length,
                          Icons.report,
                          Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        
                        // Durum Bazlı İstatistikler
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _buildStatCard('Bekleyen', pending, Icons.hourglass_empty, Colors.orange),
                            _buildStatCard('Onaylanan', approved, Icons.check, Colors.blue),
                            _buildStatCard('Çözülen', resolved, Icons.check_circle, Colors.green),
                            _buildStatCard('Sahte', fake, Icons.block, Colors.red),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Performans Metrikleri
                        _buildPerformanceCard(resolved, reports.length),
                        
                        const SizedBox(height: 24),
                        
                        // Kategori Bazlı Dağılım
                        _buildCategoryDistribution(reports),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: color),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
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

  Widget _buildPerformanceCard(int resolved, int total) {
    final percentage = total > 0 ? (resolved / total * 100).toStringAsFixed(1) : '0';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Çözüm Oranı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: total > 0 ? resolved / total : 0,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '$resolved / $total rapor çözüldü (%$percentage)',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistribution(List<QueryDocumentSnapshot> reports) {
    final categories = <String, int>{};
    for (final report in reports) {
      final data = report.data() as Map<String, dynamic>;
      final category = data['category'] ?? 'Diğer';
      categories[category] = (categories[category] ?? 0) + 1;
    }

    // Pie chart sections
    final List<PieChartSectionData> sections = [];
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    
    int colorIndex = 0;
    for (final entry in categories.entries) {
      final percentage = reports.isEmpty
          ? 0.0
          : (entry.value / reports.length * 100);
      
      sections.add(
        PieChartSectionData(
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          color: colors[colorIndex % colors.length],
          radius: 80,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
      colorIndex++;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Kategori Dağılımı',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Pie Chart
            if (sections.isNotEmpty)
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            
            if (sections.isEmpty)
              const SizedBox(
                height: 200,
                child: Center(
                  child: Text('Henüz kategori verisi yok'),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: categories.entries.map((entry) {
                final index = categories.keys.toList().indexOf(entry.key);
                final color = colors[index % colors.length];
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key} (${entry.value})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
