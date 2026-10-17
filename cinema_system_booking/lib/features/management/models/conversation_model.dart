import 'package:cloud_firestore/cloud_firestore.dart';

class CinemaConversation {
  const CinemaConversation({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.cinemaId,
    required this.lastMessage,
    required this.lastMessageAt,
    this.bookingCode,
  });

  final String id;
  final String userId;
  final String customerName;
  final String cinemaId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final String? bookingCode;

  factory CinemaConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CinemaConversation(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Khách hàng',
      cinemaId: data['cinemaId'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: parseDate(data['lastMessageAt']),
      bookingCode: data['bookingCode'] as String?,
    );
  }
}

class ChatMessageItem {
  const ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.bookingCode,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderRole; // 'customer' · 'manager' · 'staff'
  final String text;
  final String? bookingCode;
  final DateTime createdAt;

  factory ChatMessageItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ChatMessageItem(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? 'customer',
      text: data['text'] as String? ?? '',
      bookingCode: data['bookingCode'] as String?,
      createdAt: parseDate(data['createdAt']),
    );
  }
}

