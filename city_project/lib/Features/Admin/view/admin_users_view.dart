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
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
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
