import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_app/features/booking/models/pricing.dart';
import 'package:cinema_booking_app/features/booking/models/seat_model.dart';
import 'package:cinema_booking_app/features/booking/providers/booking_provider.dart';
import 'package:cinema_booking_app/features/booking/repositories/booking_repository.dart';
import 'package:cinema_booking_app/shared/widgets/seat_widget.dart';

void main() {
  group('Kiểm thử quy tắc tính giá vé (Pricing Rules)', () {
    const pricing = PricingRules.defaultRules;

    test('Tính giá ghế thường 2D ngày thường', () {
      // Thứ Ba (weekday = 2), 14:00 (không phải giờ vàng)
      final showtime = DateTime(2026, 10, 20, 14, 0);
      final price = pricing.calculateSeatPrice(
        format: '2D',
        seatType: SeatType.normal,
        showtime: showtime,
      );

      expect(price, 80000);
    });

    test('Tính giá ghế VIP 3D cuối tuần giờ vàng', () {
      // Thứ Bảy (weekday = 6), 19:30 (giờ vàng 18h-22h)
      // 100k (3D) + 20k (VIP) + 10k (Cuối tuần) + 10k (Giờ vàng) = 140k
      final showtime = DateTime(2026, 10, 24, 19, 30);
      final price = pricing.calculateSeatPrice(
        format: '3D',
        seatType: SeatType.vip,
        showtime: showtime,
      );

      expect(price, 140000);
    });

    test('Tính giá ghế Đôi IMAX ngày thường', () {
      // 2 * 120k + 20k (couple) = 260k
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

      // Chạm lại lần 2 để bỏ chọn
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

      // Thử chọn ghế thứ 9
      final ninthSuccess = provider.toggleSeatSelection('A9', SeatType.normal);
      expect(ninthSuccess, isFalse);
      expect(provider.selectedSeats.length, 8);
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
}
