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
  });
}
