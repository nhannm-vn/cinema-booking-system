import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../notifications/services/local_notification_service.dart';

class OtpVerificationResult {
  const OtpVerificationResult({
    required this.isSuccess,
    this.errorMessage,
    this.isDemo = false,
  });

  final bool isSuccess;
  final String? errorMessage;
  final bool isDemo;

  factory OtpVerificationResult.success({bool isDemo = false}) {
    return OtpVerificationResult(isSuccess: true, isDemo: isDemo);
  }

  factory OtpVerificationResult.failure(String message) {
    return OtpVerificationResult(isSuccess: false, errorMessage: message);
  }
}

class _OtpRecord {
  _OtpRecord({
    required this.otp,
    required this.expiresAt,
    this.fullName,
  });

  final String otp;
  final DateTime expiresAt;
  final String? fullName;
  bool isVerified = false;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class EmailOtpService {
  EmailOtpService._();
  static final EmailOtpService instance = EmailOtpService._();

  /// URL Webhook gửi email (Có thể dùng Google Apps Script Web App hoặc Brevo/Resend API)
  static String? emailWebhookUrl;

  final Map<String, _OtpRecord> _cache = {};

  /// Lấy mã OTP đang hoạt động trong bộ nhớ đệm (nếu còn hạn)
  String? getActiveOtp(String email) {
    final key = email.trim().toLowerCase();
    final record = _cache[key];
    if (record == null || record.isExpired || record.isVerified) return null;
    return record.otp;
  }

  /// Sinh mã OTP 6 số ngẫu nhiên, lưu vào Firestore và gửi tới email của người dùng
  Future<String> sendOtp({
    required String email,
    String? fullName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // 1. Sinh mã OTP 6 số ngẫu nhiên
    final random = Random();
    final otpCode = (100000 + random.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    // 2. Lưu vào bộ nhớ cục bộ
    _cache[normalizedEmail] = _OtpRecord(
      otp: otpCode,
      expiresAt: expiresAt,
      fullName: fullName,
    );

    // 3. Lưu vào Cloud Firestore để đối soát an toàn
    try {
      await FirebaseFirestore.instance
          .collection('otp_verifications')
          .doc(normalizedEmail)
          .set({
        'email': normalizedEmail,
        'otp': otpCode,
        'fullName': fullName ?? '',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
      });
    } catch (e) {
      debugPrint('Lưu OTP lên Firestore thất bại: $e');
    }

    // 4. Gửi email qua Webhook nếu có cấu hình
    _dispatchEmailWebhook(
      email: normalizedEmail,
      otp: otpCode,
      fullName: fullName,
    );

    // 5. Bắn thông báo cục bộ trên thiết bị để tester nhận ngay mã trên thanh thông báo
    try {
      await LocalNotificationService.instance.showNotification(
        id: normalizedEmail.hashCode,
        title: '🔐 [CINEMA] Mã OTP xác thực: $otpCode',
        body:
            'Mã kích hoạt tài khoản của bạn là $otpCode (gửi đến $normalizedEmail). Mã có hiệu lực trong 5 phút.',
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }

    // 6. In log rõ ràng ra màn hình terminal
    debugPrint('==================================================');
    debugPrint('📧 [CINEMA EMAIL OTP SERVICE - ĐÃ GỬI MÃ OTP]');
    debugPrint('👤 Người nhận: ${fullName ?? 'Khách hàng'}');
    debugPrint('📬 Email: $normalizedEmail');
    debugPrint('🔑 MÃ OTP 6 CHỮ SỐ: $otpCode');
    debugPrint('⏱️ Hết hạn lúc: ${expiresAt.toIso8601String()} (5 phút)');
    debugPrint('==================================================');

    return otpCode;
  }

  /// Xác thực mã OTP người dùng nhập vào
  Future<OtpVerificationResult> verifyOtp({
    required String email,
    required String inputOtp,
  }) async {
    final code = inputOtp.trim();
    if (code.isEmpty) {
      return OtpVerificationResult.failure('Vui lòng nhập mã xác thực OTP 6 số');
    }
    if (code.length != 6) {
      return OtpVerificationResult.failure('Mã xác thực phải gồm đúng 6 chữ số');
    }

    // Hỗ trợ mã test demo cố định
    if (code == '123456') {
      return OtpVerificationResult.success(isDemo: true);
    }

    final normalizedEmail = email.trim().toLowerCase();

    // 1. Kiểm tra trong bộ nhớ đệm
    final record = _cache[normalizedEmail];
    if (record != null) {
      if (record.isExpired) {
        return OtpVerificationResult.failure(
            'Mã OTP đã hết hạn (sau 5 phút). Vui lòng nhấn gửi lại mã mới.');
      }
      if (record.isVerified) {
        return OtpVerificationResult.failure(
            'Mã OTP này đã được sử dụng. Vui lòng lấy mã mới.');
      }
      if (record.otp == code) {
        record.isVerified = true;
        _updateFirestoreVerified(normalizedEmail);
        return OtpVerificationResult.success();
      }
    }

    // 2. Kiểm tra trên Cloud Firestore nếu cache không có hoặc app reload
    try {
      final doc = await FirebaseFirestore.instance
          .collection('otp_verifications')
          .doc(normalizedEmail)
          .get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final dbOtp = data['otp'] as String?;
        final verified = data['verified'] as bool? ?? false;
        final expiresAtTs = data['expiresAt'] as Timestamp?;

        if (expiresAtTs != null &&
            DateTime.now().isAfter(expiresAtTs.toDate())) {
          return OtpVerificationResult.failure(
              'Mã OTP đã hết hạn. Vui lòng nhấn gửi lại mã mới.');
        }

        if (verified) {
          return OtpVerificationResult.failure(
              'Mã OTP này đã được sử dụng. Vui lòng lấy mã mới.');
        }

        if (dbOtp == code) {
          await _updateFirestoreVerified(normalizedEmail);
          return OtpVerificationResult.success();
        }
      }
    } catch (e) {
      debugPrint('Đọc OTP từ Firestore lỗi: $e');
    }

    return OtpVerificationResult.failure(
        'Mã xác thực không chính xác. Vui lòng kiểm tra lại.');
  }

  Future<void> _updateFirestoreVerified(String normalizedEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('otp_verifications')
          .doc(normalizedEmail)
          .update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Gửi HTTP POST tới Webhook Dispatcher
  Future<void> _dispatchEmailWebhook({
    required String email,
    required String otp,
    String? fullName,
  }) async {
    final webhook = emailWebhookUrl;
    if (webhook == null || webhook.isEmpty) return;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final uri = Uri.parse(webhook);
      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json; charset=utf-8');

      final body = jsonEncode({
        'action': 'send_otp',
        'email': email,
        'otp': otp,
        'fullName': fullName ?? 'Khách hàng',
        'appName': 'Cinema Booking App',
      });

      request.add(utf8.encode(body));
      final response = await request.close();
      if (response.statusCode == 200) {
        debugPrint('Gửi email OTP qua Webhook thành công!');
      } else {
        debugPrint('Webhook trả về mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gửi email OTP qua Webhook gặp lỗi: $e');
    }
  }
}
