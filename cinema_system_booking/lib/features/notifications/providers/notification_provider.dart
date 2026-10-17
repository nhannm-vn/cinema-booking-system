import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  List<AppNotification> _notifications = [..._defaultSampleNotifications];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (userId.isNotEmpty && userId != 'guest') {
        final snap = await _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy('createdAt', descending: true)
            .get();

        if (snap.docs.isNotEmpty) {
          _notifications =
              snap.docs.map((d) => AppNotification.fromFirestore(d)).toList();
        }
      }
    } catch (_) {
      // Fallback in-memory
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void markAsRead(String notificationId, {String? userId}) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }

    try {
      if (userId != null && userId.isNotEmpty && userId != 'guest') {
        await _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (_) {}
  }

  void markAllAsRead({String? userId}) async {
    _notifications = [
      for (final n in _notifications) n.copyWith(isRead: true),
    ];
    notifyListeners();

    try {
      if (userId != null && userId.isNotEmpty && userId != 'guest') {
        final snap = await _db
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();
        final batch = _db.batch();
        for (final doc in snap.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (_) {}
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  static final List<AppNotification> _defaultSampleNotifications = [
    AppNotification(
      id: 'noti_1',
      type: 'bookingPaid',
      title: 'Đặt vé thành công',
      body: 'Dune: Hành Tinh Cát 2 · Suất 19:30 tại Cinema Flagship Q.1 (Phòng 01 IMAX)',
      bookingId: 'DN8872KP',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    AppNotification(
      id: 'noti_2',
      type: 'foodReady',
      title: 'Đồ ăn sẵn sàng',
      body: 'Combo Bắp phô mai và Coca-Cola đã được chuẩn bị tại Quầy Bán Vé & Đồ Ăn.',
      bookingId: 'DN8872KP',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AppNotification(
      id: 'noti_3',
      type: 'reminder',
      title: 'Nhắc nhở giờ chiếu',
      body: 'Suất chiếu sắp bắt đầu trong 30 phút nữa. Vui lòng đến rạp và check-in sớm.',
      bookingId: 'DN8872KP',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 'noti_4',
      type: 'system',
      title: 'Ưu đãi thành viên mới',
      body: 'Nhập mã DISCOUNT20 để được giảm 20.000đ hoặc VIP50 giảm 50.000đ cho đơn đặt vé đầu tiên!',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
}
