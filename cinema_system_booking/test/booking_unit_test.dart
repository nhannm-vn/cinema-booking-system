import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_app/features/booking/models/food_item.dart';
import 'package:cinema_booking_app/features/booking/models/pricing.dart';
import 'package:cinema_booking_app/features/booking/models/seat_model.dart';
import 'package:cinema_booking_app/features/booking/providers/booking_provider.dart';
import 'package:cinema_booking_app/features/booking/repositories/booking_repository.dart';
import 'package:cinema_booking_app/shared/widgets/seat_widget.dart';

void main() {
  group('Kiểm thử quy tắc tính giá vé (Pricing Rules)', () {
    const pricing = PricingRules.defaultRules;

    test('Tính giá ghế thường 2D ngày thường', () {
      final showtime = DateTime(2026, 10, 20, 14, 0);
      final price = pricing.calculateSeatPrice(
        format: '2D',
        seatType: SeatType.normal,
        showtime: showtime,
      );

      expect(price, 80000);
    });

    test('Tính giá ghế VIP 3D cuối tuần giờ vàng', () {
      final showtime = DateTime(2026, 10, 24, 19, 30);
      final price = pricing.calculateSeatPrice(
        format: '3D',
        seatType: SeatType.vip,
        showtime: showtime,
      );

      expect(price, 140000);
    });

    test('Tính giá ghế Đôi IMAX ngày thường', () {
      final showtime = DateTime(2026, 10, 21, 14, 0);
      final price = pricing.calculateSeatPrice(
        format: 'IMAX',
        seatType: SeatType.couple,
        showtime: showtime,
      );

      expect(price, 260000);
    });
  });

  group('Kiểm thử BookingProvider & Giới hạn chọn tối đa 8 ghế', () {
    late BookingProvider provider;

    setUp(() {
      provider = BookingProvider(repo: BookingRepository());
    });

    test('Chọn và bỏ chọn ghế thành công', () {
      expect(provider.selectedSeats.isEmpty, isTrue);

      final added = provider.toggleSeatSelection('A1', SeatType.normal);
      expect(added, isTrue);
      expect(provider.selectedSeats.length, 1);
      expect(provider.selectedSeats.first.id, 'A1');

      final removed = provider.toggleSeatSelection('A1', SeatType.normal);
      expect(removed, isTrue);
      expect(provider.selectedSeats.isEmpty, isTrue);
    });

    test('Chặn không cho chọn quá 8 ghế trong một lần đặt', () {
      for (int i = 1; i <= 8; i++) {
        final success = provider.toggleSeatSelection('A$i', SeatType.normal);
        expect(success, isTrue);
      }
      expect(provider.selectedSeats.length, 8);

      final ninthSuccess = provider.toggleSeatSelection('A9', SeatType.normal);
      expect(ninthSuccess, isFalse);
      expect(provider.selectedSeats.length, 8);
    });

    test('Sinh mã booking 8 ký tự hợp lệ và không chứa ký tự dễ nhầm lẫn (O, I)', () {
      for (int i = 0; i < 20; i++) {
        final code = provider.generateBookingCode();
        expect(code.length, 8);
        expect(code.contains('O'), isFalse);
        expect(code.contains('I'), isFalse);
      }
    });

    test('Tăng/giảm số lượng món ăn và tính tổng tiền đồ ăn chính xác', () {
      const food1 = FoodItem(
        id: 'f1',
        cinemaId: 'c1',
        name: 'Combo Solo',
        category: 'combo',
        price: 79000,
        description: '',
        imageUrl: '',
        isAvailable: true,
      );

      const food2 = FoodItem(
        id: 'f2',
        cinemaId: 'c1',
        name: 'Bắp Caramel',
        category: 'popcorn',
        price: 49000,
        description: '',
        imageUrl: '',
        isAvailable: true,
      );

      expect(provider.foodTotal, 0);

      // Thêm 2 Combo Solo và 1 Bắp Caramel
      provider.incrementFood(food1);
      provider.incrementFood(food1);
      provider.incrementFood(food2);

      expect(provider.getFoodQuantity('f1'), 2);
      expect(provider.getFoodQuantity('f2'), 1);
      expect(provider.foodTotal, 2 * 79000 + 49000); // 207000

      // Giảm 1 Combo Solo
      provider.decrementFood(food1);
      expect(provider.getFoodQuantity('f1'), 1);
      expect(provider.foodTotal, 79000 + 49000); // 128000
    });

    test('Áp dụng mã giảm giá Voucher chính xác', () {
      // Mã sai
      final wrong = provider.applyVoucher('SAI_MA');
      expect(wrong, isFalse);
      expect(provider.discount, 0);

      // Mã đúng DISCOUNT20
      final valid = provider.applyVoucher('DISCOUNT20');
      expect(valid, isTrue);
      expect(provider.discount, 20000);

      // Xóa voucher
      provider.removeVoucher();
      expect(provider.discount, 0);
    });
  });

  group('Kiểm thử trạng thái ghế SeatState', () {
    test('Ghế đã bán không bao giờ còn trống', () {
      const soldSeat = SeatState(
        seatId: 'B5',
        status: 'sold',
        bookingId: 'BK123',
        holderId: 'uid_other',
      );

      expect(soldSeat.isAvailableFor('uid_me'), isFalse);
      expect(soldSeat.isAvailableFor('uid_other'), isFalse);
    });

    test('Ghế đang giữ hết hạn được xem như ghế trống', () {
      final expiredSeat = SeatState(
        seatId: 'B6',
        status: 'holding',
        bookingId: 'BK123',
        holderId: 'uid_other',
        holdUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(expiredSeat.isAvailableFor('uid_me'), isTrue);
    });
  });

  group('Kiểm thử Quản lý vé của tôi (S10 My Tickets)', () {
    late BookingProvider provider;

    setUp(() {
      provider = BookingProvider(repo: BookingRepository());
    });

    test('Tải danh sách vé và phân loại chính xác 3 tab', () async {
      await provider.loadUserBookings('user_customer_1');

      expect(provider.userBookings.isNotEmpty, isTrue);
      expect(provider.upcomingBookings.isNotEmpty, isTrue);
      expect(provider.usedBookings.isNotEmpty, isTrue);
      expect(provider.cancelledBookings.isNotEmpty, isTrue);

      final upcoming = provider.upcomingBookings.first;
      expect(upcoming.status, 'paid');
      expect(upcoming.isUpcoming, isTrue);
    });

    test('Hủy vé thành công và chuyển vào danh sách vé đã hủy', () async {
      await provider.loadUserBookings('user_customer_1');
      final initialUpcomingCount = provider.upcomingBookings.length;
      final targetTicket = provider.upcomingBookings.first;

      final cancelled =
          await provider.cancelBooking(targetTicket.id, 'user_customer_1');
      expect(cancelled, isTrue);

      expect(provider.upcomingBookings.length, initialUpcomingCount - 1);
      final hasCancelled =
          provider.cancelledBookings.any((b) => b.id == targetTicket.id);
      expect(hasCancelled, isTrue);
    });
  });
}
