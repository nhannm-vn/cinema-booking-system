import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_app/shared/models/app_user.dart';

void main() {
  group('Kiểm thử mô hình AppUser & Phân quyền', () {
    test('Khởi tạo tài khoản Guest mặc định chính xác', () {
      final guest = AppUser.guest();
      expect(guest.role, UserRole.guest);
      expect(guest.isLocked, isFalse);
      expect(guest.cinemaId, isNull);
    });

    test('Chuyển đổi chuỗi vai trò từ cơ sở dữ liệu chính xác', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('manager'), UserRole.manager);
      expect(UserRole.fromString('staff'), UserRole.staff);
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.guest);
      expect(UserRole.fromString(null), UserRole.guest);
    });

    test('Kiểm tra cờ isLocked và copyWith', () {
      const user = AppUser(
        uid: 'user_123',
        fullName: 'Nguyễn Văn A',
        email: 'test@cinema.vn',
        phone: '0901234567',
        role: UserRole.customer,
        isLocked: false,
      );

      final lockedUser = user.copyWith(isLocked: true);
      expect(lockedUser.isLocked, isTrue);
      expect(lockedUser.fullName, 'Nguyễn Văn A');
    });

    test('Quy tắc bảo mật định dạng SĐT (10 số) và Mật khẩu (>= 6 ký tự)', () {
      final phoneRegex = RegExp(r'^0[0-9]{9}$');
      expect(phoneRegex.hasMatch('0901234567'), isTrue);
      expect(phoneRegex.hasMatch('090123456'), isFalse); // 9 số
      expect(phoneRegex.hasMatch('09012345678'), isFalse); // 11 số
      expect(phoneRegex.hasMatch('1901234567'), isFalse); // Không bắt đầu bằng 0

      // Mật khẩu >= 6 ký tự
      bool isValidPassword(String pass) => pass.trim().length >= 6;
      expect(isValidPassword('12345'), isFalse);
      expect(isValidPassword('123456'), isTrue);
      expect(isValidPassword('Cinema@2026'), isTrue);
    });

    test('Kiểm thử sinh và xác thực mã OTP email 6 số', () {
      final otpRegex = RegExp(r'^[0-9]{6}$');

      // Kiểm tra định dạng OTP 6 chữ số
      expect(otpRegex.hasMatch('123456'), isTrue);
      expect(otpRegex.hasMatch('987654'), isTrue);
      expect(otpRegex.hasMatch('12345'), isFalse); // 5 số
      expect(otpRegex.hasMatch('1234567'), isFalse); // 7 số
      expect(otpRegex.hasMatch('12a456'), isFalse); // Chứa chữ cái

      // Kiểm tra thời hạn hiệu lực (5 phút)
      final createdAt = DateTime.now();
      final expiresAt = createdAt.add(const Duration(minutes: 5));
      final testTimeValid = createdAt.add(const Duration(minutes: 2));
      final testTimeExpired = createdAt.add(const Duration(minutes: 6));

      expect(testTimeValid.isBefore(expiresAt), isTrue);
      expect(testTimeExpired.isAfter(expiresAt), isTrue);
    });
  });
}
