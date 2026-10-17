import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore? _firestore;
  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  String? _activeUserId;

  // Lưu trữ danh sách thông báo riêng biệt cho từng UserId
  final Map<String, List<AppNotification>> _userNotificationsMap = {
    // Chỉ tài khoản mẫu 'usr_cust_01' (khach1@cinema.vn) mới có thông báo đặt vé mẫu
    'usr_cust_01': [
      AppNotification(
        id: 'noti_cust_1',
        type: 'bookingPaid',
        title: 'Đặt vé thành công',
        body: 'Dune: Hành Tinh Cát 2 · Suất 19:30 tại Cinema Flagship Q.1 (Phòng 01 IMAX)',
        bookingId: 'DN8872KP',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      AppNotification(
        id: 'noti_cust_2',
        type: 'foodReady',
        title: 'Đồ ăn sẵn sàng',
        body: 'Combo Bắp phô mai và Coca-Cola đã được chuẩn bị tại Quầy Concession.',
        bookingId: 'DN8872KP',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'noti_cust_3',
        type: 'reminder',
        title: 'Nhắc nhở giờ chiếu',
        body: 'Suất chiếu sắp bắt đầu trong 30 phút nữa. Vui lòng đến rạp check-in sớm.',
        bookingId: 'DN8872KP',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> loadNotifications(String userId) async {
    _activeUserId = userId;
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
          _userNotificationsMap[userId] = _notifications;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }
    } catch (_) {
      // Fallback in-memory
    }

    // Fallback: Tải danh sách thông báo riêng cho từng tài khoản
    if (userId == 'guest' || userId.isEmpty) {
      _notifications = [
        AppNotification(
          id: 'noti_guest_welcome',
          type: 'system',
          title: 'Chào mừng quý khách đến với Cinema!',
          body:
              'Đăng nhập hoặc đăng ký thành viên để tích lũy điểm thưởng và nhận thông báo vé đã đặt.',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];
    } else {
      _notifications = _userNotificationsMap[userId] ?? [
        AppNotification(
          id: 'noti_sys_${userId}_1',
          type: 'system',
          title: 'Ưu đãi thành viên mới',
          body:
              'Nhập mã DISCOUNT20 để được giảm 20.000đ hoặc VIP50 giảm 50.000đ cho đơn đặt vé đầu tiên!',
          isRead: false,
          createdAt: DateTime.now(),
        ),
      ];
      _userNotificationsMap[userId] = _notifications;
    }

    _isLoading = false;
    notifyListeners();
  }

  void markAsRead(String notificationId, {String? userId}) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      notifyListeners();
    }

    final targetUid = userId ?? _activeUserId;
    if (targetUid != null && _userNotificationsMap.containsKey(targetUid)) {
      final list = _userNotificationsMap[targetUid]!;
      final userIdx = list.indexWhere((n) => n.id == notificationId);
      if (userIdx != -1) {
        list[userIdx] = list[userIdx].copyWith(isRead: true);
      }
    }

    try {
      if (targetUid != null && targetUid.isNotEmpty && targetUid != 'guest') {
        await _db
            .collection('users')
            .doc(targetUid)
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

    final targetUid = userId ?? _activeUserId;
    if (targetUid != null && _userNotificationsMap.containsKey(targetUid)) {
      _userNotificationsMap[targetUid] = [
        for (final n in _userNotificationsMap[targetUid]!)
          n.copyWith(isRead: true),
      ];
    }

    try {
      if (targetUid != null && targetUid.isNotEmpty && targetUid != 'guest') {
        final snap = await _db
            .collection('users')
            .doc(targetUid)
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

  void addNotification(AppNotification notification, {String? userId}) {
    final targetUid = userId ?? _activeUserId ?? 'guest';
    final userList = _userNotificationsMap.putIfAbsent(targetUid, () => []);
    userList.insert(0, notification);

    if (_activeUserId == targetUid) {
      _notifications = [...userList];
      notifyListeners();
    }

    if (targetUid.isNotEmpty && targetUid != 'guest') {
      try {
        _db
            .collection('users')
            .doc(targetUid)
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toFirestore());
      } catch (_) {}
    }
  }
}
