import 'package:flutter_test/flutter_test.dart';
import 'package:cinema_booking_app/core/config/app_constants.dart';
import 'package:cinema_booking_app/features/booking/models/booking_model.dart';
import 'package:cinema_booking_app/features/staff_checkin/models/ticket_checkin_result.dart';
import 'package:cinema_booking_app/shared/models/app_user.dart';

void main() {
  group('Kiểm thử API Soát vé Nhân viên (S18 - Staff Check-in API)', () {
    const staffUser = AppUser(
      uid: 'staff_q1_01',
      fullName: 'Nguyễn Văn Soát Vé',
      email: 'staff1@cinema.vn',
      phone: '0901112233',
      role: UserRole.staff,
      cinemaId: 'cn_q1',
      isLocked: false,
    );

    BookingModel createSampleBooking({
      String id = 'BK123456',
      String cinemaId = 'cn_q1',
      String cinemaName = 'Cinema Quận 1 Flagship',
      String status = 'paid',
      String ageRating = 'P',
      required DateTime showtimeStart,
      List<Map<String, dynamic>> foods = const [],
    }) {
      return BookingModel(
        id: id,
        userId: 'user_cust_01',
        customerName: 'Trần Khách Hàng',
        movieId: 'mov_dune2',
        movieTitle: 'Dune: Hành Tinh Cát - Phần 2',
        posterUrl: 'https://example.com/poster.jpg',
        ageRating: ageRating,
        cinemaId: cinemaId,
        cinemaName: cinemaName,
        roomName: 'Phòng 01 (IMAX)',
        format: 'IMAX',
        showtimeStart: showtimeStart,
        seatIds: ['C5', 'C6'],
        foods: foods,
        foodSummary: foods.isNotEmpty ? '1x Combo Bắp Nước' : null,
        totalAmount: 240000,
        status: status,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        paidAt: DateTime.now().subtract(const Duration(hours: 3)),
      );
    }

    test('Kiểm tra hằng số khung giờ soát vé chuẩn AppConstants', () {
      expect(AppConstants.checkInWindowBeforeShow.inMinutes, 60);
      expect(AppConstants.checkInWindowAfterShow.inMinutes, 15);
    });

    test('Thẩm định vé hợp lệ trong khung giờ (-60 phút đến +15 phút)', () {
      final now = DateTime(2026, 10, 25, 19, 0); // 19:00
      final showtime = DateTime(2026, 10, 25, 19, 30); // Suất 19:30 (còn 30 phút)

      final booking = createSampleBooking(showtimeStart: showtime);

      final diff = showtime.difference(now);
      final isWithinWindow =
          now.isAfter(showtime.subtract(AppConstants.checkInWindowBeforeShow)) &&
              now.isBefore(showtime.add(AppConstants.checkInWindowAfterShow));

      expect(diff.inMinutes, 30);
      expect(isWithinWindow, isTrue);

      final result = TicketVerificationResult.valid(
        booking: booking,
        requiresIdCheck: false,
        hasFoodPending: false,
      );

      expect(result.isSuccess, isTrue);
      expect(result.status, TicketCheckinStatus.valid);
      expect(result.requiresIdCheck, isFalse);
    });

    test('Từ chối khi vé thuộc rạp khác (Phân quyền dữ liệu theo cinemaId)', () {
      final now = DateTime(2026, 10, 25, 19, 0);
      final booking = createSampleBooking(
        cinemaId: 'cn_tb', // Rạp Tân Bình
        cinemaName: 'Cinema Tân Bình Hub',
        showtimeStart: now.add(const Duration(minutes: 30)),
      );

      final isWrongCinema = booking.cinemaId != staffUser.cinemaId;
      expect(isWrongCinema, isTrue);

      final result = TicketVerificationResult.wrongCinema(
        bookingCinemaName: booking.cinemaName,
        staffCinemaId: staffUser.cinemaId!,
        booking: booking,
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, TicketCheckinStatus.wrongCinema);
      expect(result.message, contains('Vé không thuộc rạp này'));
      expect(result.message, contains('Cinema Tân Bình Hub'));
    });

    test('Từ chối khi vé đã qua sử dụng trước đó (Used)', () {
      final checkedInAt = DateTime(2026, 10, 25, 18, 45);
      final result = TicketVerificationResult.alreadyUsed(
        time: checkedInAt,
        byStaff: 'Lê Nhân Viên',
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, TicketCheckinStatus.alreadyUsed);
      expect(result.message, contains('Vé đã được sử dụng trước đó'));
      expect(result.message, contains('18:45'));
      expect(result.message, contains('Lê Nhân Viên'));
    });

    test('Từ chối khi vé đã bị hủy hoặc chưa thanh toán', () {
      final cancelledResult = TicketVerificationResult.cancelled();
      expect(cancelledResult.isSuccess, isFalse);
      expect(cancelledResult.status, TicketCheckinStatus.cancelled);
      expect(cancelledResult.message, contains('đã bị hủy hoặc hoàn tiền'));

      final unpaidResult = TicketVerificationResult.notPaid(
        currentStatus: 'holding',
      );
      expect(unpaidResult.isSuccess, isFalse);
      expect(unpaidResult.status, TicketCheckinStatus.notPaid);
    });

    test('Kiểm tra giới hạn thời gian: Vào quá sớm (> 60 phút)', () {
      final now = DateTime(2026, 10, 25, 17, 0);
      final showtime = DateTime(2026, 10, 25, 19, 0); // Cách 120 phút

      final isTooEarly = now.isBefore(
        showtime.subtract(AppConstants.checkInWindowBeforeShow),
      );
      expect(isTooEarly, isTrue);

      final result = TicketVerificationResult.tooEarly(
        showtime: showtime,
        minutesBeforeAllowed: AppConstants.checkInWindowBeforeShow.inMinutes,
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, TicketCheckinStatus.tooEarly);
      expect(result.message, contains('Chưa đến giờ vào rạp'));
      expect(result.message, contains('60 phút'));
    });

    test('Kiểm tra giới hạn thời gian: Vào quá muộn (> 15 phút sau giờ chiếu)', () {
      final showtime = DateTime(2026, 10, 25, 19, 0);
      final now = DateTime(2026, 10, 25, 19, 20); // Đã qua 20 phút

      final isTooLate = now.isAfter(
        showtime.add(AppConstants.checkInWindowAfterShow),
      );
      expect(isTooLate, isTrue);

      final result = TicketVerificationResult.tooLate(
        showtime: showtime,
        minutesAfterAllowed: AppConstants.checkInWindowAfterShow.inMinutes,
      );

      expect(result.isSuccess, isFalse);
      expect(result.status, TicketCheckinStatus.tooLate);
      expect(result.message, contains('Đã quá giờ vào rạp'));
      expect(result.message, contains('15 phút'));
    });

    test('Nhận diện điều kiện kiểm tra CCCD với phim T16 / T18', () {
      final showtime = DateTime.now().add(const Duration(minutes: 30));

      final bookingP = createSampleBooking(ageRating: 'P', showtimeStart: showtime);
      final bookingT16 =
          createSampleBooking(ageRating: 'T16', showtimeStart: showtime);
      final bookingT18 =
          createSampleBooking(ageRating: 'T18', showtimeStart: showtime);

      bool checkRequiresId(String rating) =>
          rating == 'T13' || rating == 'T16' || rating == 'T18';

      expect(checkRequiresId(bookingP.ageRating), isFalse);
      expect(checkRequiresId(bookingT16.ageRating), isTrue);
      expect(checkRequiresId(bookingT18.ageRating), isTrue);
    });

    test('Nhận diện thông báo nhận đồ ăn kèm tại quầy (S19)', () {
      final showtime = DateTime.now().add(const Duration(minutes: 30));
      final bookingWithFood = createSampleBooking(
        showtimeStart: showtime,
        foods: [
          {'name': 'Combo Bắp Nước 1', 'qty': 1, 'price': 79000}
        ],
      );

      final result = TicketVerificationResult.valid(
        booking: bookingWithFood,
        requiresIdCheck: false,
        hasFoodPending: true,
      );

      expect(result.hasFoodPending, isTrue);
      expect(result.foodSummary, contains('Combo Bắp Nước'));
    });

    test('Thao tác xác nhận soát vé thành công tạo TicketCheckinActionResult chuẩn', () {
      final actionSuccess = TicketCheckinActionResult.success(
        bookingCode: 'BK998877',
      );

      expect(actionSuccess.isSuccess, isTrue);
      expect(actionSuccess.bookingCode, 'BK998877');
      expect(actionSuccess.message, contains('Soát vé thành công'));
    });
  });
}
