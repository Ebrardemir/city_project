# 🚀 YENİ GELİŞTİRME YOL HARİTASI - 2026
**Tarih:** 14 Şubat 2026  
**Hedef:** MVP'yi %70'den %95'e çıkarmak  
**Süre:** 3 Gün (24 saat)

---

## 📊 MEVCUT DURUM ÖZETİ

- **Tamamlanan:** %70 (10/15 ana feature)
- **Eksik:** %30 (5 feature + iyileştirmeler)
- **Kritik Sorun:** GamificationService yazılmış ama kullanılmıyor
- **Acil Görev:** Gamification entegrasyonu + Placeholder sayfaları doldurma

---

## 🎯 3 GÜNLÜK HIZLANDIRILMIŞ PLAN

### 📅 1. GÜN: Gamification & Leaderboard (8 saat)

#### **SAAT 0-3: Gamification Entegrasyonu** 🔴 KRİTİK
**Hedef:** GamificationService'i tüm feature'lara bağla

##### ✅ Adım 1.1: CreateReport Entegrasyonu (45 dk)
**Dosya:** `lib/Features/Home/view/create_report_screen.dart`

```dart
// Import ekle
import '../../../core/Services/gamification_service.dart';

// _submitReport() metoduna ekle (rapor başarıyla oluşturulduktan sonra):
if (docRef.id.isNotEmpty) {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    await GamificationService().onReportCreated(
      currentUser.uid,
      docRef.id,
    );
  }
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Rapor oluşturuldu! +10 puan kazandınız!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
```

**Test:** Yeni rapor aç → Firestore'da score +10 olmalı

---

##### ✅ Adım 1.2: Municipality Service Entegrasyonu (45 dk)
**Dosya:** `lib/Features/Municipality/service/municipality_service.dart`

```dart
// Import ekle
import '../../../core/Services/gamification_service.dart';

// resolveReport() metodunda (başarılı update sonrası):
Future<bool> resolveReport({...}) async {
  try {
    // Mevcut kod...
    await _firestore.collection('reports').doc(reportId).update({...});
    
    // 🆕 GAMIFICATION: Raporlayan kullanıcıya puan ver
    final reportDoc = await _firestore.collection('reports').doc(reportId).get();
    final reporterId = reportDoc.data()?['userId'];
    
    if (reporterId != null) {
      await GamificationService().onReportResolved(reporterId, reportId);
      print('🎮 Raporlayan kullanıcıya +25 puan verildi');
    }
    
    // 🆕 GAMIFICATION: Destekleyenlere de puan ver
    final supportedUserIds = List<String>.from(reportDoc.data()?['supportedUserIds'] ?? []);
    for (final userId in supportedUserIds) {
      await GamificationService().addPoints(
        userId: userId,
        points: 5,
        action: 'Desteklediğiniz rapor çözüldü',
        reportId: reportId,
      );
    }
    
    return true;
  } catch (e) {...}
}
```

**Test:** Belediye rapor çözsün → Raporlayan kullanıcı +25 puan almalı

---

##### ✅ Adım 1.3: Clustering Support Entegrasyonu (30 dk)
**Dosya:** `lib/core/Services/clustering_service.dart`

```dart
// Import ekle
import 'gamification_service.dart';

// addSupport() metodunda (başarılı update sonrası):
Future<bool> addSupport(String reportId, String userId) async {
  try {
    // Mevcut kod...
    await _firestore.collection('reports').doc(reportId).update({...});
    
    // 🆕 GAMIFICATION: Destek veren kullanıcıya puan ver
    await GamificationService().onReportSupported(userId, reportId);
    
    return true;
  } catch (e) {...}
}
```

**Test:** Yakın rapora destek ver → +5 puan almalı

---

##### ✅ Adım 1.4: Profile Gamification UI (1 saat)
**Dosya:** `lib/Features/Profile/view/profile_view.dart`

```dart
// ProfileHeader'dan sonra, body içine ekle:

// 🆕 Puan ve İstatistikler Kartı
Container(
  margin: const EdgeInsets.all(16),
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
                '${userModel?.score ?? 0}',
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
      _buildBadgeIndicator(userModel?.score ?? 0),
    ],
  ),
),

// Method olarak ekle:
Widget _buildBadgeIndicator(int score) {
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
  
  return Row(
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
  );
}
```

**Test:** Profile git → Puan kartı ve rozet göstergesini gör

---

#### **SAAT 3-6: Leaderboard Feature** 🟠 YÜKSEK ÖNCELİK

##### ✅ Adım 2.1: Leaderboard View Oluştur (2 saat)
**Yeni Dosya:** `lib/Features/Leaderboard/view/leaderboard_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Liderlik Tablosu'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('score', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Henüz veri yok'),
            );
          }
          
          final users = snapshot.data!.docs;
          
          return Column(
            children: [
              // Top 3 Podium
              _buildPodium(users),
              
              const SizedBox(height: 16),
              
              // Diğer kullanıcılar
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final isCurrentUser = userId == currentUser?.uid;
                    
                    return _buildLeaderboardCard(
                      rank: index + 1,
                      name: userData['fullName'] ?? 'Kullanıcı',
                      score: userData['score'] ?? 0,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPodium(List<QueryDocumentSnapshot> users) {
    if (users.length < 3) return const SizedBox();
    
    final first = users[0].data() as Map<String, dynamic>;
    final second = users[1].data() as Map<String, dynamic>;
    final third = users[2].data() as Map<String, dynamic>;
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Sıra
          _buildPodiumItem(
            rank: 2,
            name: second['fullName'] ?? 'İsim',
            score: second['score'] ?? 0,
            height: 120,
            color: Colors.grey.shade400,
          ),
          
          const SizedBox(width: 8),
          
          // 1. Sıra
          _buildPodiumItem(
            rank: 1,
            name: first['fullName'] ?? 'İsim',
            score: first['score'] ?? 0,
            height: 160,
            color: Colors.amber,
          ),
          
          const SizedBox(width: 8),
          
          // 3. Sıra
          _buildPodiumItem(
            rank: 3,
            name: third['fullName'] ?? 'İsim',
            score: third['score'] ?? 0,
            height: 100,
            color: Colors.brown.shade300,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPodiumItem({
    required int rank,
    required String name,
    required int score,
    required double height,
    required Color color,
  }) {
    String medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉';
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          medal,
          style: const TextStyle(fontSize: 32),
        ),
        Text(
          name.split(' ').first,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '#$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLeaderboardCard({
    required int rank,
    required String name,
    required int score,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Colors.blue.withOpacity(0.1) 
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser 
            ? Border.all(color: Colors.blue, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Sıralama
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? Colors.amber : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3 ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // İsim
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isCurrentUser 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    'Siz',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Puan
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

##### ✅ Adım 2.2: Router'a Ekle (30 dk)
**Dosya:** `lib/core/Router/app_router.dart`

```dart
// Import ekle
import 'package:city_project/Features/Leaderboard/view/leaderboard_view.dart';

// Citizen navbar dışında (GoRoute listesine ekle):
GoRoute(
  name: 'leaderboard',
  path: '/leaderboard',
  builder: (context, state) => const LeaderboardView(),
),
```

---

##### ✅ Adım 2.3: Profile'dan Link (15 dk)
**Dosya:** `lib/Features/Profile/view/profile_view.dart`

```dart
// Puan kartının altına buton ekle:
ElevatedButton.icon(
  onPressed: () {
    context.push('/leaderboard');
  },
  icon: const Icon(Icons.leaderboard),
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
```

**Test:** Profile → "Liderlik Tablosunu Gör" → Sıralı liste görmeli

---

#### **SAAT 6-8: fl_chart Grafikleri** 📊

##### ✅ Adım 3.1: Municipality Statistics Pie Chart (1 saat)
**Dosya:** `lib/Features/Municipality/view/municipality_statistics_view.dart`

```dart
// Import ekle
import 'package:fl_chart/fl_chart.dart';

// Kategori dağılımı için yeni widget:
Widget _buildCategoryChart(List<QueryDocumentSnapshot> reports) {
  // Kategori sayılarını hesapla
  Map<String, int> categoryCount = {
    'road': 0,
    'park': 0,
    'water': 0,
    'garbage': 0,
    'light': 0,
    'other': 0,
  };
  
  for (var doc in reports) {
    final category = (doc.data() as Map)['category'];
    if (category != null && categoryCount.containsKey(category)) {
      categoryCount[category] = categoryCount[category]! + 1;
    }
  }
  
  // Pie Chart sections
  List<PieChartSectionData> sections = [];
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.teal,
  ];
  
  int index = 0;
  categoryCount.forEach((category, count) {
    if (count > 0) {
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$count',
          color: colors[index % colors.length],
          radius: 50,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    index++;
  });
  
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Dağılımı',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Yol', Colors.blue),
            _buildLegendItem('Park', Colors.green),
            _buildLegendItem('Su', Colors.orange),
            _buildLegendItem('Çöp', Colors.red),
            _buildLegendItem('Aydınlatma', Colors.purple),
            _buildLegendItem('Diğer', Colors.teal),
          ],
        ),
      ],
    ),
  );
}

Widget _buildLegendItem(String label, Color color) {
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
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}

// StreamBuilder body içine ekle (GridView'dan sonra):
const SizedBox(height: 24),
_buildCategoryChart(reports),
```

**Test:** Municipality Statistics → Pie Chart görmeli

---

##### ✅ Adım 3.2: Admin Dashboard Line Chart (30 dk)
**Dosya:** `lib/Features/Admin/view/admin_dashboard_view.dart`

```dart
// Import ekle
import 'package:fl_chart/fl_chart.dart';

// Son 7 günlük trend grafiği ekle
Widget _buildTrendChart() {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son 7 Gün Rapor Trendi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    const FlSpot(0, 3),
                    const FlSpot(1, 5),
                    const FlSpot(2, 4),
                    const FlSpot(3, 7),
                    const FlSpot(4, 6),
                    const FlSpot(5, 9),
                    const FlSpot(6, 8),
                  ],
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(value.toInt().toString());
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                      return Text(days[value.toInt()]);
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
      ],
    ),
  );
}

// _buildStatsGrid() sonrasına ekle:
const SizedBox(height: 24),
_buildTrendChart(),
```

**Test:** Admin Dashboard → Line Chart görmeli

---

### 📅 2. GÜN: Admin Pages (8 saat)

#### **SAAT 0-4: Admin User Management**

##### ✅ Adım 4.1: Admin Users View (3 saat)
**Yeni Dosya:** `lib/Features/Admin/view/admin_users_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _selectedRole = 'all';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👥 Kullanıcı Yönetimi'),
        actions: [
          // Role Filter
          PopupMenuButton<String>(
            initialValue: _selectedRole,
            onSelected: (value) {
              setState(() {
                _selectedRole = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tümü')),
              const PopupMenuItem(value: 'citizen', child: Text('Vatandaş')),
              const PopupMenuItem(value: 'municipality', child: Text('Belediye')),
              const PopupMenuItem(value: 'admin', child: Text('Admin')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 4),
                  Text('Filtre'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _selectedRole == 'all'
            ? FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: _selectedRole)
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Kullanıcı bulunamadı'),
            );
          }
          
          final users = snapshot.data!.docs;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final userData = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              
              return _buildUserCard(
                userId: userId,
                name: userData['fullName'] ?? 'İsimsiz',
                email: userData['email'] ?? '',
                role: userData['role'] ?? 'citizen',
                score: userData['score'] ?? 0,
                city: userData['city'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildUserCard({
    required String userId,
    required String name,
    required String email,
    required String role,
    required int score,
    required String city,
  }) {
    Color roleColor;
    IconData roleIcon;
    
    switch (role) {
      case 'admin':
        roleColor = Colors.purple;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'municipality':
        roleColor = Colors.orange;
        roleIcon = Icons.business;
        break;
      default:
        roleColor = Colors.blue;
        roleIcon = Icons.person;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withOpacity(0.2),
          child: Icon(roleIcon, color: roleColor),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(email),
        trailing: Chip(
          label: Text(
            role.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: roleColor.withOpacity(0.2),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bilgiler
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Şehir',
                        city.isEmpty ? 'Belirtilmemiş' : city,
                        Icons.location_city,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Puan',
                        score.toString(),
                        Icons.star,
                      ),
                    ),
                  ],
                ),
                
                const Divider(height: 24),
                
                // Aksiyonlar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Role Değiştir
                    TextButton.icon(
                      onPressed: () => _showRoleChangeDialog(userId, role, name),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Role Değiştir'),
                    ),
                    
                    // Kullanıcıyı Sil (dikkatli!)
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(userId, name),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Sil', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _showRoleChangeDialog(String userId, String currentRole, String name) {
    showDialog(
      context: context,
      builder: (context) {
        String newRole = currentRole;
        
        return AlertDialog(
          title: Text('$name için role seç'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile(
                    title: const Text('Vatandaş'),
                    value: 'citizen',
                    groupValue: newRole,
                    onChanged: (value) {
                      setState(() {
                        newRole = value!;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Belediye'),
                    value: 'municipality',
                    groupValue: newRole,
                    onChanged: (value) {
                      setState(() {
                        newRole = value!;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Admin'),
                    value: 'admin',
                    groupValue: newRole,
                    onChanged: (value) {
                      setState(() {
                        newRole = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .update({'role': newRole});
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Role $newRole olarak güncellendi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }
  
  void _showDeleteDialog(String userId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kullanıcıyı Sil'),
          content: Text('$name kullanıcısını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .delete();
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kullanıcı silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }
}
```

---

##### ✅ Adım 4.2: Router Güncelle (15 dk)
**Dosya:** `lib/core/Router/app_router.dart`

```dart
// Import ekle
import 'package:city_project/Features/Admin/view/admin_users_view.dart';

// Admin users placeholder'ını değiştir:
StatefulShellBranch(
  routes: [
    GoRoute(
      name: 'admin-users',
      path: '/admin-users',
      builder: (context, state) => const AdminUsersView(), // 🆕
    ),
  ],
),
```

**Test:** Admin olarak giriş → "Kullanıcılar" tab → Kullanıcı listesi + role değiştirme

---

#### **SAAT 4-8: Admin Reports Management**

##### ✅ Adım 5: Admin Reports View (3.5 saat)
**Yeni Dosya:** `lib/Features/Admin/view/admin_reports_view.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../Home/model/report_model.dart';

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Tüm Raporlar'),
        actions: [
          // Filters
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _buildQuery(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Rapor bulunamadı'));
          }
          
          final reports = snapshot.data!.docs;
          
          return Column(
            children: [
              // Özet Kartlar
              _buildSummaryCards(reports),
              
              // Rapor Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final reportData = reports[index].data() as Map<String, dynamic>;
                    final report = ReportModel.fromMap(reportData, reports[index].id);
                    
                    return _buildReportCard(report);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true);
    
    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    if (_selectedCategory != 'all') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    
    return query.limit(100).snapshots();
  }
  
  Widget _buildSummaryCards(List<QueryDocumentSnapshot> reports) {
    final total = reports.length;
    final pending = reports.where((r) => (r.data() as Map)['status'] == 'pending').length;
    final approved = reports.where((r) => (r.data() as Map)['status'] == 'approved').length;
    final resolved = reports.where((r) => (r.data() as Map)['status'] == 'resolved').length;
    final fake = reports.where((r) => (r.data() as Map)['status'] == 'fake').length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _buildSummaryCard('Toplam', total, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Bekleyen', pending, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Onaylı', approved, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Çözülen', resolved, Colors.purple)),
          const SizedBox(width: 8),
          Expanded(child: _buildSummaryCard('Sahte', fake, Colors.red)),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportCard(ReportModel report) {
    Color statusColor;
    switch (report.status) {
      case ReportStatus.pending:
        statusColor = Colors.orange;
        break;
      case ReportStatus.approved:
        statusColor = Colors.green;
        break;
      case ReportStatus.resolved:
        statusColor = Colors.blue;
        break;
      case ReportStatus.fake:
        statusColor = Colors.red;
        break;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          context.push('/report-detail', extra: report);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Thumbnail
                  if (report.imageUrlBefore != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        report.imageUrlBefore!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  
                  const SizedBox(width: 12),
                  
                  // Bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${report.category.name.toUpperCase()} - ${report.district}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                report.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.userFullName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 14, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              '${report.supportCount} destek',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Aksiyonlar
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (report.status == ReportStatus.pending)
                    TextButton.icon(
                      onPressed: () => _approveReport(report.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Onayla'),
                    ),
                  
                  if (report.status != ReportStatus.fake)
                    TextButton.icon(
                      onPressed: () => _markAsFake(report.id),
                      icon: const Icon(Icons.block, size: 16, color: Colors.red),
                      label: const Text('Sahte', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtreler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Durum Filtresi
                  const Text('Durum'),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tümü'),
                        selected: _selectedStatus == 'all',
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = 'all';
                          });
                          this.setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                      FilterChip(
                        label: const Text('Bekleyen'),
                        selected: _selectedStatus == 'pending',
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = 'pending';
                          });
                          this.setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                      FilterChip(
                        label: const Text('Onaylı'),
                        selected: _selectedStatus == 'approved',
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = 'approved';
                          });
                          this.setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                      FilterChip(
                        label: const Text('Çözülen'),
                        selected: _selectedStatus == 'resolved',
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = 'resolved';
                          });
                          this.setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                      FilterChip(
                        label: const Text('Sahte'),
                        selected: _selectedStatus == 'fake',
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = 'fake';
                          });
                          this.setState(() {});
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _approveReport(String reportId) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapor onaylandı'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _markAsFake(String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sahte rapor olarak işaretle'),
          content: const Text('Bu işlem geri alınamaz. Devam etmek istiyor musunuz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('İşaretle'),
            ),
          ],
        );
      },
    );
    
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'fake',
        'markedAsFakeAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rapor sahte olarak işaretlendi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
```

---

##### ✅ Adım 5.2: Router Güncelle (15 dk)
**Dosya:** `lib/core/Router/app_router.dart`

```dart
// Import ekle
import 'package:city_project/Features/Admin/view/admin_reports_view.dart';

// Admin reports placeholder'ını değiştir:
StatefulShellBranch(
  routes: [
    GoRoute(
      name: 'admin-reports',
      path: '/admin-reports',
      builder: (context, state) => const AdminReportsView(), // 🆕
    ),
  ],
),
```

**Test:** Admin → "Raporlar" tab → Tüm raporları gör + onaylama/sahte işaretleme

---

### 📅 3. GÜN: Polish & Testing (8 saat)

#### **SAAT 0-3: Push Notifications** 🔔

##### ✅ Adım 6: FCM Setup (3 saat)
**Yeni Dosya:** `lib/core/services/notification_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  /// Notification izinlerini al ve setup yap
  static Future<void> initialize() async {
    // iOS için izin iste
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // FCM token al
    final token = await _messaging.getToken();
    print('📲 FCM Token: $token');
    
    // Local notifications setup
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(initSettings);
    
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      print('📩 Foreground mesaj: ${message.notification?.title}');
      _showLocalNotification(message);
    });
  }
  
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    print('📩 Background mesaj: ${message.notification?.title}');
  }
  
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'city_pulse_channel',
      'CityPulse Bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      notificationDetails,
    );
  }
}
```

**main.dart'ta initialize et:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize(); // 🆕
  
  runApp(const MyApp());
}
```

**Test:** Uygulama açıldığında FCM token log'da görünmeli

---

#### **SAAT 3-5: Performance Optimizations** ⚡

##### ✅ Adım 7: CachedNetworkImage Kullan (1.5 saat)

**Tüm NetworkImage kullanımlarını değiştir:**

```dart
// ÖNCESİ:
Image.network(imageUrl, fit: BoxFit.cover)

// SONRASI:
CachedNetworkImage(
  imageUrl: imageUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => const Center(
    child: CircularProgressIndicator(),
  ),
  errorWidget: (context, url, error) => const Icon(Icons.error),
)
```

**Değiştirilmesi gereken dosyalar:**
- `report_media_header.dart`
- `municipality_dashboard_view.dart`
- `admin_reports_view.dart`
- `home_view.dart` (marker thumbnails)

---

##### ✅ Adım 8: Pagination (30 dk)

**HomePage'de pagination ekle:**
```dart
// Firestore query'ye limit ekle
.limit(20)

// "Daha Fazla Yükle" butonu ekle
```

---

#### **SAAT 5-8: Testing & Bug Fixes** 🧪

##### ✅ Adım 9: Test Senaryoları

**Test Listesi:**
1. ✅ Yeni rapor aç → +10 puan al
2. ✅ Yakın rapora destek ver → +5 puan al
3. ✅ Belediye rapor çözsün → Raporlayan +25 puan alsın
4. ✅ Leaderboard'da sıralamayı gör
5. ✅ Admin olarak kullanıcı rolü değiştir
6. ✅ Admin olarak tüm raporları gör
7. ✅ Municipality Statistics'te pie chart gör
8. ✅ Admin Dashboard'da line chart gör
9. ✅ Profile'da puan kartını ve rozet göster
10. ✅ Push notification gelsin (test için manuel gönder)

---

## 📊 SONUÇ

### Tamamlanma Hedefi
- **Başlangıç:** %70
- **3 Gün Sonra:** %95
- **Kalan:** Messages feature (%5)

### Kazanımlar
- ✅ Gamification tam entegre
- ✅ Leaderboard çalışır
- ✅ Admin paneli tam fonksiyonel
- ✅ Grafikler (pie + line chart)
- ✅ Push notifications hazır
- ✅ Performance optimize

### MVP Durumu
**3 gün sonunda proje demo için hazır!** 🚀

---

## 🎯 SONRAKİ ADIMLAR (Opsiyonel)

1. Messages feature (8-10 saat)
2. AI Fake Detection (6-8 saat)
3. Mahalle yönetimi (3-4 saat)
4. Daha fazla grafik (heatmap, bar charts)
5. UI/UX animasyonlar

**ÖNERİ:** Bu roadmap'i takip et, 3 günde MVP'yi %95'e çıkar! 💪
