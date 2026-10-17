import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const androidInitSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const darwinInitSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: darwinInitSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped with payload: ${response.payload}');
        },
      );

      // Yêu cầu quyền thông báo trên Android 13+ (API 33+)
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('LocalNotificationService initialize error: $e');
    }
  }

  Future<void> showBookingSuccessNotification({
    required String bookingCode,
    required String movieTitle,
    required String showtime,
  }) async {
    await showNotification(
      id: bookingCode.hashCode,
      title: '🎉 ĐẶT VÉ THÀNH CÔNG · [$bookingCode]',
      body:
          'Phim: $movieTitle · Suất chiếu: $showtime. Mở vé điện tử trong app để check-in tại rạp!',
      payload: bookingCode,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'cinema_system_channel',
        'Cinema Booking Notifications',
        channelDescription:
            'Kênh thông báo trạng thái đặt vé, đồ ăn và nhắc giờ suất chiếu',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('LocalNotificationService showNotification error: $e');
    }
  }
}
