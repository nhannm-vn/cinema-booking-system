import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/app_constants.dart';
import '../../../shared/models/app_user.dart';
import '../../booking/models/booking_model.dart';
import '../../management/models/audit_log.dart';
import '../models/ticket_checkin_result.dart';

/// Repository / API xử lý nghiệp vụ Soát vé của Nhân viên (S18 - Staff Check-in API)
///
/// Tuân thủ quy chuẩn hệ thống theo `PROJECT.md`, `DATA.md` (mục 6.3) và `SCREENS.md` (mục S18):
/// 1. Tách biệt 2 pha: Tra cứu thẩm định vé (verify) -> Xác nhận cho vào (confirm).
/// 2. Kiểm tra chặt chẽ điều kiện: đúng rạp, đúng trạng thái, đúng khung giờ chiếu (-60' -> +15').
/// 3. Cảnh báo độ tuổi (T13/T16/T18) và nhắc nhở nhận combo đồ ăn tại quầy.
/// 4. Ghi nhận nhật ký kiểm toán (AuditLog) đầy đủ khi soát vé.
class StaffCheckinRepository {
  StaffCheckinRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Đẩy toàn bộ danh sách vé mẫu lên Cloud Firestore thật
  Future<int> seedDemoBookings() async {
    int count = 0;
    for (final entry in _mockBookings.entries) {
      final code = entry.key;
      final booking = entry.value;
      await _db.collection('bookings').doc(code).set({
        'cinemaId': booking.cinemaId,
        'cinemaName': booking.cinemaName,
        'movieTitle': booking.movieTitle,
        'roomName': booking.roomName,
        'ageRating': booking.ageRating,
        'status': booking.status,
        'foods': booking.foods,
        'seats': booking.seatIds.map((s) => {'id': s}).toList(),
        'showtimeStart': Timestamp.fromDate(booking.showtimeStart),
        'foodStatus': booking.foods.isNotEmpty ? 'pending' : 'none',
        'userId': booking.userId,
        'customerName': booking.customerName,
        'format': booking.format,
        'total': booking.totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // 1. TRA CỨU & KIỂM TRA ĐIỀU KIỆN VÉ (Verify Ticket)
  // ---------------------------------------------------------------------------
  /// Kiểm tra tính hợp lệ của mã vé mà chưa thay đổi dữ liệu trong cơ sở dữ liệu.
  /// Thích hợp để render Bottom Sheet thông tin vé cho nhân viên đối chiếu trước.
  Future<TicketVerificationResult> verifyTicket({
    required String bookingCode,
    required String cinemaId,
    DateTime? currentTime,
  }) async {
    try {
      final code = bookingCode.trim().toUpperCase().replaceAll('#', '');
      if (code.isEmpty) {
        return TicketVerificationResult.notFound(bookingCode);
      }

      final docRef = _db.collection('bookings').doc(code);
      DocumentSnapshot<Map<String, dynamic>>? snap;
      try {
        snap = await docRef.get();
      } catch (_) {}

      BookingModel booking;
      Map<String, dynamic> data;

      if (snap != null && snap.exists) {
        booking = BookingModel.fromFirestore(snap);
        data = snap.data() ?? {};
      } else if (_mockBookings.containsKey(code)) {
        booking = _mockBookings[code]!;
        data = {
          'cinemaId': booking.cinemaId,
          'cinemaName': booking.cinemaName,
          'movieTitle': booking.movieTitle,
          'roomName': booking.roomName,
          'ageRating': booking.ageRating,
          'status': booking.status,
          'foods': booking.foods,
          'seats': booking.seatIds.map((s) => {'id': s}).toList(),
          'showtimeStart': Timestamp.fromDate(booking.showtimeStart),
          'foodStatus': booking.foods.isNotEmpty ? 'pending' : 'none',
          'checkedInAt': booking.status == 'used'
              ? Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30)))
              : null,
          'checkedInBy': booking.status == 'used' ? 'Nguyễn Văn Tuấn' : null,
        };

        // Tự động ghi vào Firestore để DB có sẵn doc này thật
        try {
          docRef.set({
            ...data,
            'userId': booking.userId,
            'customerName': booking.customerName,
            'format': booking.format,
            'total': booking.totalAmount,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      } else {
        return TicketVerificationResult.notFound(code);
      }

      // 1. Kiểm tra rạp quản lý (Bảo mật cấp Repository)
      final bookingCinemaId = (data['cinemaId'] as String? ?? '').trim();
      if (bookingCinemaId.isNotEmpty &&
          cinemaId.isNotEmpty &&
          bookingCinemaId.toLowerCase() != cinemaId.trim().toLowerCase()) {
        return TicketVerificationResult.wrongCinema(
          bookingCinemaName: booking.cinemaName,
          staffCinemaId: cinemaId,
          booking: booking,
        );
      }

      // 2. Kiểm tra trạng thái vé
      final status = (data['status'] as String? ?? '').toLowerCase();
      if (status == 'used') {
        final checkedAt = (data['checkedInAt'] as Timestamp?)?.toDate();
        final checkedBy = data['checkedInBy'] as String?;
        return TicketVerificationResult.alreadyUsed(
          time: checkedAt,
          byStaff: checkedBy,
          booking: booking,
        );
      }

      if (status == 'cancelled') {
        return TicketVerificationResult.cancelled(booking: booking);
      }

      if (status == 'expired') {
        return TicketVerificationResult.notPaid(
          currentStatus: 'Đã hết hạn giữ chỗ',
          booking: booking,
        );
      }

      if (status != 'paid') {
        return TicketVerificationResult.notPaid(
          currentStatus: status,
          booking: booking,
        );
      }

      // 3. Kiểm tra khung giờ vào rạp (AppConstants: -60 phút đến +15 phút)
      final now = currentTime ?? DateTime.now();
      final showtimeStart = booking.showtimeStart;

      final earliestAllowed =
          showtimeStart.subtract(AppConstants.checkInWindowBeforeShow);
      final latestAllowed =
          showtimeStart.add(AppConstants.checkInWindowAfterShow);

      if (now.isBefore(earliestAllowed)) {
        return TicketVerificationResult.tooEarly(
          showtime: showtimeStart,
          minutesBeforeAllowed: AppConstants.checkInWindowBeforeShow.inMinutes,
          booking: booking,
        );
      }

      if (now.isAfter(latestAllowed)) {
        return TicketVerificationResult.tooLate(
          showtime: showtimeStart,
          minutesAfterAllowed: AppConstants.checkInWindowAfterShow.inMinutes,
          booking: booking,
        );
      }

      // 4. Kiểm tra cảnh báo độ tuổi & đồ ăn
      final ageRating = booking.ageRating.toUpperCase();
      final requiresIdCheck = ageRating == 'T13' ||
          ageRating == 'T16' ||
          ageRating == 'T18';

      final foodStatus = (data['foodStatus'] as String? ?? '').toLowerCase();
      final hasFoodPending = booking.foods.isNotEmpty &&
          (foodStatus == 'pending' || foodStatus.isEmpty || foodStatus == 'none');

      return TicketVerificationResult.valid(
        booking: booking,
        requiresIdCheck: requiresIdCheck,
        hasFoodPending: hasFoodPending,
      );
    } catch (e) {
      return TicketVerificationResult.systemError(e.toString());
    }
  }

  // ---------------------------------------------------------------------------
  // 2. XÁC NHẬN CHO VÀO / SOÁT VÉ (Confirm Check-in)
  // ---------------------------------------------------------------------------
  /// Đánh dấu vé đã sử dụng (Used) và ghi nhận Audit Log.
  Future<TicketCheckinActionResult> confirmCheckIn({
    required String bookingCode,
    required String cinemaId,
    required AppUser actor,
    bool idChecked = false,
    DateTime? currentTime,
  }) async {
    try {
      final code = bookingCode.trim().toUpperCase().replaceAll('#', '');
      final docRef = _db.collection('bookings').doc(code);

      // Thẩm định lại trước khi cập nhật
      final verification = await verifyTicket(
        bookingCode: code,
        cinemaId: cinemaId,
        currentTime: currentTime,
      );

      if (!verification.isSuccess) {
        return TicketCheckinActionResult.failure(
          bookingCode: code,
          booking: verification.booking,
          message: verification.message,
        );
      }

      // Ràng buộc kiểm tra giấy tờ với phim giới hạn độ tuổi
      if (verification.requiresIdCheck && !idChecked) {
        return TicketCheckinActionResult.failure(
          bookingCode: code,
          booking: verification.booking,
          message:
              'Phim ${verification.ageRating} yêu cầu nhân viên kiểm tra giấy tờ tùy thân trước khi xác nhận cho vào.',
        );
      }

      // Cập nhật trạng thái vé sang 'used'
      try {
        await docRef.update({
          'status': 'used',
          'checkedInBy': actor.fullName,
          'checkedInById': actor.uid,
          'checkedInAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        if (_mockBookings.containsKey(code)) {
          final old = _mockBookings[code]!;
          _mockBookings[code] = BookingModel(
            id: old.id,
            userId: old.userId,
            customerName: old.customerName,
            movieId: old.movieId,
            movieTitle: old.movieTitle,
            posterUrl: old.posterUrl,
            ageRating: old.ageRating,
            cinemaId: old.cinemaId,
            cinemaName: old.cinemaName,
            roomName: old.roomName,
            format: old.format,
            showtimeStart: old.showtimeStart,
            seatIds: old.seatIds,
            foods: old.foods,
            foodSummary: old.foodSummary,
            totalAmount: old.totalAmount,
            status: 'used',
            paymentMethod: old.paymentMethod,
            createdAt: old.createdAt,
            paidAt: old.paidAt,
          );
        }
      }

      // Ghi nhật ký thao tác (Audit Log)
      await _logAudit(
        actor: actor,
        action: 'checkIn',
        targetType: 'booking',
        targetId: code,
        cinemaId: cinemaId,
        reason: 'Soát vé thành công cho khách vào xem phim ${verification.booking?.movieTitle ?? ""}',
      );

      return TicketCheckinActionResult.success(
        bookingCode: code,
        booking: verification.booking,
        message: 'Soát vé thành công! Mời khách vào phòng chiếu.',
      );
    } catch (e) {
      return TicketCheckinActionResult.failure(
        bookingCode: bookingCode,
        message: 'Lỗi trong quá trình soát vé: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. GHI NHẬT KÝ THAO TÁC (Audit Log Helper)
  // ---------------------------------------------------------------------------
  Future<void> _logAudit({
    required AppUser actor,
    required String action,
    required String targetType,
    required String targetId,
    String? cinemaId,
    String? reason,
  }) async {
    try {
      final log = AuditLog(
        id: '',
        actorId: actor.uid,
        actorName: actor.fullName,
        actorRole: actor.role.name,
        cinemaId: cinemaId ?? actor.cinemaId,
        action: action,
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        createdAt: DateTime.now(),
      );

      await _db.collection('auditLogs').add(log.toFirestore());
    } catch (_) {
      // Ghi log phụ không làm gián đoạn luồng soát vé chính
    }
  }

  // ---------------------------------------------------------------------------
  // 4. MOCK DATA PHỤC VỤ DEMO TRỰC TIẾP TRÊN EMULATOR
  // ---------------------------------------------------------------------------
  static final Map<String, BookingModel> _mockBookings = {
    // 1. Vé hợp lệ (Suất chiếu còn 25', T16 + Combo bắp nước) - Rạp Q1
    'BK92M7XP': BookingModel(
      id: 'BK92M7XP',
      userId: 'user_cust_1',
      customerName: 'Hoàng Minh Quân',
      movieId: 'mov_dune2',
      movieTitle: 'Dune: Hành Tinh Cát 2',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      ageRating: 'T16',
      cinemaId: 'cn_q1',
      cinemaName: 'Cinema Flagship Q1',
      roomName: 'Phòng 01 - IMAX Laser',
      format: 'IMAX 2D',
      showtimeStart: DateTime.now().add(const Duration(minutes: 25)),
      seatIds: const ['D05', 'D06'],
      foods: const [
        {'name': 'Combo Bắp Nước Solo', 'qty': 2, 'unitPrice': 79000}
      ],
      foodSummary: '2x Combo Bắp Nước Solo',
      totalAmount: 398000,
      status: 'paid',
      paymentMethod: 'vnpay',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      paidAt: DateTime.now().subtract(const Duration(minutes: 55)),
    ),
    // 2. Vé đã sử dụng (Used)
    'BK7721AA': BookingModel(
      id: 'BK7721AA',
      userId: 'user_cust_2',
      customerName: 'Lê Thảo Vy',
      movieId: 'mov_exhuma',
      movieTitle: 'Exhuma: Quật Mộ Trùng Ma',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/muU9LpE1Ym821sL8iZfP9w7Zp7t.jpg',
      ageRating: 'T18',
      cinemaId: 'cn_q1',
      cinemaName: 'Cinema Flagship Q1',
      roomName: 'Phòng 01 - IMAX Laser',
      format: '2D',
      showtimeStart: DateTime.now().subtract(const Duration(hours: 1)),
      seatIds: const ['E01', 'E02'],
      foods: const [],
      foodSummary: null,
      totalAmount: 200000,
      status: 'used',
      paymentMethod: 'vnpay',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      paidAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    // 3. Vé thuộc rạp khác (Tân Bình cn_tb)
    'BK333TB': BookingModel(
      id: 'BK333TB',
      userId: 'user_cust_3',
      customerName: 'Nguyễn Văn Nam',
      movieId: 'mov_godzilla_kong',
      movieTitle: 'Godzilla x Kong: Đế Chế Mới',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/bQ2ywAsx97yKq4O06OAEZ6e9p0.jpg',
      ageRating: 'T13',
      cinemaId: 'cn_tb',
      cinemaName: 'Cinema Tân Bình Hub',
      roomName: 'Phòng 01 - Standard',
      format: '2D',
      showtimeStart: DateTime.now().add(const Duration(minutes: 30)),
      seatIds: const ['C04'],
      foods: const [],
      foodSummary: null,
      totalAmount: 110000,
      status: 'paid',
      paymentMethod: 'vnpay',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      paidAt: DateTime.now().subtract(const Duration(minutes: 50)),
    ),
  };
}
