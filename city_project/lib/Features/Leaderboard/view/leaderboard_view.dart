import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🏆 Liderlik Tablosu'),
          elevation: 0,
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          actions: [
            // DEBUG: Veri yoksa test verisi eklemek için buton
            if (const bool.fromEnvironment('DEBUG', defaultValue: true))
              IconButton(
                icon: const Icon(Icons.add_moderator),
                tooltip: 'Test Verisi Ekle',
                onPressed: () => _addTestUsers(context),
              ),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Vatandaşlar'),
              Tab(text: 'Belediyeler'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LeaderboardList(role: 'citizen'),
            _LeaderboardList(role: 'municipality'),
          ],
        ),
      ),
    );
  }
  Future<void> _addTestUsers(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final scaffold = ScaffoldMessenger.of(context);
    
    try {
      // 3 Vatandaş
      for (int i = 1; i <= 3; i++) {
        await firestore.collection('users').add({
          'fullName': 'Test Vatandaş $i',
          'email': 'testuser$i@mail.com',
          'role': 'citizen',
          'score': i * 100,
          'createdAt': FieldValue.serverTimestamp(),
          'city': 'İstanbul',
        });
      }
      
      // 3 Belediye
      for (int i = 1; i <= 3; i++) {
        await firestore.collection('users').add({
          'fullName': 'Test Belediye $i',
          'email': 'testbel$i@belediye.bel.tr',
          'role': 'municipality',
          'score': i * 150,
          'createdAt': FieldValue.serverTimestamp(),
          'city': 'İstanbul',
          'districts': ['Kadıköy', 'Üsküdar'],
        });
      }
      
      scaffold.showSnackBar(
        const SnackBar(content: Text('Test verileri eklendi!')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

}

class _LeaderboardList extends StatelessWidget {
  final String role;
  
  const _LeaderboardList({required this.role});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .orderBy('score', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                'Bir hata oluştu:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              role == 'citizen' 
                  ? 'Henüz vatandaş verisi yok' 
                  : 'Henüz belediye verisi yok',
            ),
          );
        }
        
        final users = snapshot.data!.docs;
        
        return Column(
          children: [
            // Top 3 Podium
            if (users.length >= 3) _buildPodium(users),
            
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
    );
  }
  
  Widget _buildPodium(List<QueryDocumentSnapshot> users) {
    final first = users[0].data() as Map<String, dynamic>;
    final second = users.length > 1 ? users[1].data() as Map<String, dynamic>? : null;
    final third = users.length > 2 ? users[2].data() as Map<String, dynamic>? : null;
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade100, Colors.amber.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2. Sıra
          if (second != null)
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
          if (third != null)
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
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            name.split(' ').first,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            fontWeight: FontWeight.bold,
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                fontSize: 14,
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
