import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.bookingId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type; // 'bookingPaid', 'showtimeCancelled', 'foodReady', 'reminder', 'system'
  final String title;
  final String body;
  final String? bookingId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      bookingId: bookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AppNotification(
      id: doc.id,
      type: data['type'] as String? ?? 'system',
      title: data['title'] as String? ?? 'Thông báo',
      body: data['body'] as String? ?? '',
      bookingId: data['bookingId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }
}
