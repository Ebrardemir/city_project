import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/message_model.dart';

/// Messages Service
/// Mesajlaşma işlemleri için servis sınıfı
class MessagesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mesaj gönder
  Future<bool> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
  }) async {
    try {
      print('📤 MessagesService: Mesaj gönderiliyor...');
      
      // Conversation ID oluştur (her zaman küçük ID önce)
      final conversationId = _getConversationId(senderId, receiverId);
      
      // Mesajı kaydet
      await _firestore
          .collection('messages')
          .doc(conversationId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'senderName': senderName,
            'receiverId': receiverId,
            'receiverName': receiverName,
            'content': content,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
      
      // Conversation özet bilgisini güncelle (her iki kullanıcı için)
      await _updateConversationSummary(
        conversationId: conversationId,
        userId1: senderId,
        userName1: senderName,
        userId2: receiverId,
        userName2: receiverName,
        lastMessage: content,
      );
      
      print('✅ MessagesService: Mesaj başarıyla gönderildi');
      return true;
    } catch (e) {
      print('❌ MessagesService: Mesaj gönderilirken hata: $e');
      return false;
    }
  }

  /// Konuşma ID'sini oluştur (küçük ID önce gelir)
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Konuşma özet bilgisini güncelle
  Future<void> _updateConversationSummary({
    required String conversationId,
    required String userId1,
    required String userName1,
    required String userId2,
    required String userName2,
    required String lastMessage,
  }) async {
    try {
      // User1 için özet
      await _firestore
          .collection('users')
          .doc(userId1)
          .collection('conversations')
          .doc(conversationId)
          .set({
            'userId': userId2,
            'userName': userName2,
            'lastMessage': lastMessage,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadCount': 0, // Gönderen için unread count 0
          });
      
      // User2 için özet (unread count artır)
      final user2ConvDoc = _firestore
          .collection('users')
          .doc(userId2)
          .collection('conversations')
          .doc(conversationId);
      
      final user2ConvSnapshot = await user2ConvDoc.get();
      final currentUnreadCount = user2ConvSnapshot.exists 
          ? (user2ConvSnapshot.data()?['unreadCount'] ?? 0)
          : 0;
      
      await user2ConvDoc.set({
        'userId': userId1,
        'userName': userName1,
        'lastMessage': lastMessage,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': currentUnreadCount + 1,
      });
    } catch (e) {
      print('⚠️ Conversation summary güncellenemedi: $e');
    }
  }

  /// Konuşmaları getir (user için)
  Stream<List<ConversationModel>> getConversations(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConversationModel.fromFirestore(doc))
            .toList());
  }

  /// Mesajları getir (konuşma ID'sine göre)
  Stream<List<MessageModel>> getMessages({
    required String senderId,
    required String receiverId,
  }) {
    final conversationId = _getConversationId(senderId, receiverId);
    
    return _firestore
        .collection('messages')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromFirestore(doc))
            .toList());
  }

  /// Mesajları okundu olarak işaretle
  Future<void> markAsRead({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final conversationId = _getConversationId(senderId, receiverId);
      
      // Konuşmadaki tüm okunmamış mesajları getir
      final snapshot = await _firestore
          .collection('messages')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: receiverId)
          .where('isRead', isEqualTo: false)
          .get();
      
      // Batch update
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      
      // Conversation unread count'u sıfırla
      await _firestore
          .collection('users')
          .doc(receiverId)
          .collection('conversations')
          .doc(conversationId)
          .update({'unreadCount': 0});
      
      print('✅ Mesajlar okundu olarak işaretlendi');
    } catch (e) {
      print('⚠️ Mesajlar okundu işaretlenirken hata: $e');
    }
  }

  /// Okunmamış mesaj sayısını getir
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('conversations')
          .get();
      
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        totalUnread += (doc.data()['unreadCount'] as int? ?? 0);
      }
      
      return totalUnread;
    } catch (e) {
      print('⚠️ Unread count alınırken hata: $e');
      return 0;
    }
  }
}
