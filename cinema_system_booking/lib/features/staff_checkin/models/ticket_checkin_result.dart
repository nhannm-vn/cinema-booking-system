import '../../booking/models/booking_model.dart';

/// Các trạng thái kiểm tra vé khi quét QR / nhập mã tại quầy soát vé (S18)
enum TicketCheckinStatus {
  valid,
  notFound,
  wrongCinema,
  alreadyUsed,
  cancelled,
  notPaid,
  expired,
  tooEarly,
  tooLate,
  systemError,
}

/// Kết quả tra cứu và thẩm định vé trước khi cho khách vào phòng chiếu
class TicketVerificationResult {
  const TicketVerificationResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.booking,
    this.requiresIdCheck = false,
    this.ageRating,
    this.hasFoodPending = false,
    this.foodSummary,
    this.checkedInAt,
    this.checkedInBy,
  });

  final bool isSuccess;
  final TicketCheckinStatus status;
  final String message;
  final BookingModel? booking;
  final bool requiresIdCheck;
  final String? ageRating;
  final bool hasFoodPending;
  final String? foodSummary;
  final DateTime? checkedInAt;
  final String? checkedInBy;

  factory TicketVerificationResult.notFound(String code) {
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.notFound,
      message: 'Mã vé #$code không tồn tại trên hệ thống.',
    );
  }

  factory TicketVerificationResult.wrongCinema({
    required String bookingCinemaName,
    required String staffCinemaId,
    BookingModel? booking,
  }) {
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.wrongCinema,
      booking: booking,
      message:
          'Vé không thuộc rạp này. Vé đặt tại: $bookingCinemaName (Rạp hiện tại: ${staffCinemaId.toUpperCase()}).',
    );
  }

  factory TicketVerificationResult.alreadyUsed({
    required DateTime? time,
    required String? byStaff,
    BookingModel? booking,
  }) {
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ngày ${time.day}/${time.month}'
        : '';
    final staffStr = byStaff != null && byStaff.isNotEmpty ? ' bởi $byStaff' : '';
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.alreadyUsed,
      booking: booking,
      checkedInAt: time,
      checkedInBy: byStaff,
      message: 'Vé đã được sử dụng trước đó $timeStr$staffStr.',
    );
  }

  factory TicketVerificationResult.cancelled({BookingModel? booking}) {
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.cancelled,
      booking: booking,
      message: 'Vé này đã bị hủy hoặc hoàn tiền. Không thể vào rạp.',
    );
  }

  factory TicketVerificationResult.notPaid({
    required String currentStatus,
    BookingModel? booking,
  }) {
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.notPaid,
      booking: booking,
      message: 'Vé chưa hoàn tất thanh toán (Trạng thái đơn: $currentStatus).',
    );
  }

  factory TicketVerificationResult.tooEarly({
    required DateTime showtime,
    required int minutesBeforeAllowed,
    BookingModel? booking,
  }) {
    final showtimeStr =
        '${showtime.hour.toString().padLeft(2, '0')}:${showtime.minute.toString().padLeft(2, '0')}';
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.tooEarly,
      booking: booking,
      message:
          'Chưa đến giờ vào rạp. Suất chiếu lúc $showtimeStr. Chỉ được vào rạp trước giờ chiếu tối đa $minutesBeforeAllowed phút.',
    );
  }

  factory TicketVerificationResult.tooLate({
    required DateTime showtime,
    required int minutesAfterAllowed,
    BookingModel? booking,
  }) {
    final showtimeStr =
        '${showtime.hour.toString().padLeft(2, '0')}:${showtime.minute.toString().padLeft(2, '0')}';
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.tooLate,
      booking: booking,
      message:
          'Đã quá giờ vào rạp. Phim đã chiếu lúc $showtimeStr (quá giới hạn $minutesAfterAllowed phút).',
    );
  }

  factory TicketVerificationResult.systemError(String error) {
    return TicketVerificationResult(
      isSuccess: false,
      status: TicketCheckinStatus.systemError,
      message: 'Lỗi hệ thống khi kiểm tra vé: $error',
    );
  }

  factory TicketVerificationResult.valid({
    required BookingModel booking,
    required bool requiresIdCheck,
    required bool hasFoodPending,
  }) {
    return TicketVerificationResult(
      isSuccess: true,
      status: TicketCheckinStatus.valid,
      booking: booking,
      requiresIdCheck: requiresIdCheck,
      ageRating: booking.ageRating,
      hasFoodPending: hasFoodPending,
      foodSummary: booking.foodSummary,
      message: 'Vé hợp lệ! Sẵn sàng cho khách vào phòng chiếu.',
    );
  }
}

/// Kết quả của thao tác cập nhật xác nhận soát vé (XÁC NHẬN CHO VÀO)
class TicketCheckinActionResult {
  const TicketCheckinActionResult({
    required this.isSuccess,
    required this.message,
    this.bookingCode,
    this.booking,
  });

  final bool isSuccess;
  final String message;
  final String? bookingCode;
  final BookingModel? booking;

  factory TicketCheckinActionResult.success({
    required String bookingCode,
    BookingModel? booking,
    String? message,
  }) {
    return TicketCheckinActionResult(
      isSuccess: true,
      bookingCode: bookingCode,
      booking: booking,
      message: message ?? 'Soát vé thành công! Đã ghi nhận khách vào phòng chiếu.',
    );
  }

  factory TicketCheckinActionResult.failure({
    required String message,
    String? bookingCode,
    BookingModel? booking,
  }) {
    return TicketCheckinActionResult(
      isSuccess: false,
      bookingCode: bookingCode,
      booking: booking,
      message: message,
    );
  }
}
