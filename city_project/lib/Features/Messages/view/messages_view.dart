import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../model/message_model.dart';
import '../service/messages_service.dart';
import 'package:intl/intl.dart';

/// Messages View - Konuşma listesi
/// Kullanıcının tüm konuşmalarını listeler
class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  final MessagesService _service = MessagesService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;
    
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('💬 Mesajlar')),
        body: const Center(
          child: Text('Oturum açmanız gerekiyor'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showNewConversationDialog(),
            tooltip: 'Yeni Konuşma',
          ),
        ],
      ),
      body: StreamBuilder<List<ConversationModel>>(
        stream: _service.getConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Hata: ${snapshot.error}'),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz konuşma yok',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showNewConversationDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni Konuşma Başlat'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationTile(conversation);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          conversation.userName.isNotEmpty
              ? conversation.userName[0].toUpperCase()
              : '?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        conversation.userName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        conversation.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: conversation.unreadCount > 0
              ? Colors.black87
              : Colors.grey[600],
          fontWeight: conversation.unreadCount > 0
              ? FontWeight.w500
              : FontWeight.normal,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageTime),
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0
                  ? Colors.blue
                  : Colors.grey[600],
            ),
          ),
          if (conversation.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        context.push('/chat', extra: {
          'receiverId': conversation.userId,
          'receiverName': conversation.userName,
        });
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE', 'tr_TR').format(time);
    } else {
      return DateFormat('dd.MM.yyyy').format(time);
    }
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => _NewConversationDialog(),
    );
  }
}

/// Yeni konuşma başlatma dialogu
class _NewConversationDialog extends StatefulWidget {
  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fullName', isGreaterThanOrEqualTo: query)
          .where('fullName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _users = snapshot.docs
            .where((doc) => doc.id != currentUserId) // Kendini hariç tut
            .map((doc) => {
                  'id': doc.id,
                  'name': doc.data()['fullName'] ?? 'İsimsiz',
                  'role': doc.data()['role'] ?? 'citizen',
                })
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      print('❌ Kullanıcı arama hatası: $e');
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Konuşma'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Kullanıcı ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_users.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _searchController.text.isEmpty
                      ? 'Kullanıcı aramak için yazın'
                      : 'Kullanıcı bulunamadı',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: user['role'] == 'municipality'
                            ? Colors.orange
                            : user['role'] == 'admin'
                                ? Colors.purple
                                : Colors.blue,
                        child: Text(
                          user['name'][0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(user['name']),
                      subtitle: Text(
                        user['role'] == 'municipality'
                            ? 'Belediye'
                            : user['role'] == 'admin'
                                ? 'Admin'
                                : 'Vatandaş',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/chat', extra: {
                          'receiverId': user['id'],
                          'receiverName': user['name'],
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
      ],
    );
  }
}
