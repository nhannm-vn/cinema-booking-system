import 'package:flutter/foundation.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/models/food_item.dart';
import '../../booking/models/showtime.dart';
import '../../../shared/models/app_user.dart';
import '../models/audit_log.dart';
import '../repositories/management_repository.dart';

class ManagementProvider extends ChangeNotifier {
  ManagementProvider({
    ManagementRepository? repo,
  }) : _repo = repo ?? ManagementRepository();

  final ManagementRepository _repo;

  // Dashboard state
  DashboardStats? _dashboardStats;
  DashboardStats? get dashboardStats => _dashboardStats;
  String _selectedPeriod = 'today';
  String get selectedPeriod => _selectedPeriod;

  // Showtimes state
  List<Showtime> _showtimes = [];
  List<Showtime> get showtimes => _showtimes;
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // Bookings state
  List<BookingModel> _bookings = [];
  List<BookingModel> get bookings => _bookings;
  String _bookingStatusFilter = 'all';
  String get bookingStatusFilter => _bookingStatusFilter;
  String _bookingChannelFilter = 'all';
  String get bookingChannelFilter => _bookingChannelFilter;
  String _bookingSearchQuery = '';
  String get bookingSearchQuery => _bookingSearchQuery;

  // Staff state
  List<AppUser> _staffList = [];
  List<AppUser> get staffList => _staffList;

  // Foods state
  List<FoodItem> _foodList = [];
  List<FoodItem> get foodList => _foodList;

  // Audit logs state
  List<AuditLog> _auditLogs = [];
  List<AuditLog> get auditLogs => _auditLogs;

  // Loading and Error flags
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // 1. DASHBOARD
  // ---------------------------------------------------------------------------
  Future<void> loadDashboard(String cinemaId, {String? period}) async {
    if (period != null) _selectedPeriod = period;
    _setLoading(true);
    _errorMessage = null;

    try {
      _dashboardStats = await _repo.getDashboardStats(
        cinemaId: cinemaId,
        period: _selectedPeriod,
      );
    } catch (e) {
      _errorMessage = 'Không thể tải thống kê: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 2. SHOWTIMES
  // ---------------------------------------------------------------------------
  Future<void> loadShowtimes(String cinemaId, {DateTime? date}) async {
    if (date != null) _selectedDate = date;
    _setLoading(true);
    _errorMessage = null;

    try {
      _showtimes = await _repo.getShowtimesForCinema(
        cinemaId: cinemaId,
        date: _selectedDate,
      );
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách suất chiếu: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createShowtime({
    required String cinemaId,
    required String movieId,
    required String roomId,
    required String format,
    required DateTime startTime,
    required int durationMin,
    required int totalSeats,
    required AppUser actor,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repo.createShowtime(
        cinemaId: cinemaId,
        movieId: movieId,
        roomId: roomId,
        format: format,
        startTime: startTime,
        durationMin: durationMin,
        totalSeats: totalSeats,
        actor: actor,
      );
      await loadShowtimes(cinemaId, date: startTime);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('StateError: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteShowtime({
    required Showtime showtime,
    required AppUser actor,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repo.deleteShowtime(showtime: showtime, actor: actor);
      await loadShowtimes(showtime.cinemaId, date: _selectedDate);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('StateError: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<int> cancelShowtime({
    required Showtime showtime,
    required String reason,
    required AppUser actor,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final count = await _repo.cancelShowtime(
        showtime: showtime,
        reason: reason,
        actor: actor,
      );
      await loadShowtimes(showtime.cinemaId, date: _selectedDate);
      return count;
    } catch (e) {
      _errorMessage = 'Lỗi hủy suất chiếu: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 3. BOOKINGS
  // ---------------------------------------------------------------------------
  Future<void> loadBookings(
    String cinemaId, {
    String? status,
    String? channel,
    String? search,
  }) async {
    if (status != null) _bookingStatusFilter = status;
    if (channel != null) _bookingChannelFilter = channel;
    if (search != null) _bookingSearchQuery = search;

    _setLoading(true);
    _errorMessage = null;

    try {
      _bookings = await _repo.getBookingsForCinema(
        cinemaId: cinemaId,
        statusFilter: _bookingStatusFilter,
        channelFilter: _bookingChannelFilter,
        searchQuery: _bookingSearchQuery,
      );
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách đơn đặt: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelOrRefundBooking({
    required String bookingCode,
    required String reason,
    required AppUser actor,
    required String cinemaId,
  }) async {
    _setLoading(true);
    try {
      await _repo.cancelOrRefundBooking(
        bookingCode: bookingCode,
        reason: reason,
        actor: actor,
        cinemaId: cinemaId,
      );
      await loadBookings(cinemaId);
    } catch (e) {
      _errorMessage = 'Lỗi hoàn vé: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 4. STAFF
  // ---------------------------------------------------------------------------
  Future<void> loadStaff(String cinemaId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _staffList = await _repo.getStaffForCinema(cinemaId);
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách nhân viên: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createStaff({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String cinemaId,
    required AuthRepository authRepo,
    required AppUser actor,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repo.createStaffAccount(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
        cinemaId: cinemaId,
        authRepo: authRepo,
        actor: actor,
      );
      await loadStaff(cinemaId);
    } catch (e) {
      _errorMessage = 'Lỗi tạo tài khoản nhân viên: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleStaffLock({
    required AppUser staff,
    required bool isLocked,
    required String reason,
    required AppUser actor,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _repo.toggleStaffLock(
        staff: staff,
        isLocked: isLocked,
        reason: reason,
        actor: actor,
      );
      await loadStaff(staff.cinemaId ?? actor.cinemaId ?? 'cn_q1');
    } catch (e) {
      _errorMessage = 'Lỗi cập nhật trạng thái nhân viên: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 5. FOODS
  // ---------------------------------------------------------------------------
  Future<void> loadFoods(String cinemaId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _foodList = await _repo.getFoodsForCinema(cinemaId);
    } catch (e) {
      _errorMessage = 'Không thể tải thực đơn: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> toggleFoodAvailability({
    required String cinemaId,
    required String foodId,
    required bool isAvailable,
    required AppUser actor,
  }) async {
    try {
      // Optimistic update
      final idx = _foodList.indexWhere((f) => f.id == foodId);
      if (idx != -1) {
        final old = _foodList[idx];
        _foodList[idx] = FoodItem(
          id: old.id,
          cinemaId: old.cinemaId,
          name: old.name,
          category: old.category,
          price: old.price,
          description: old.description,
          imageUrl: old.imageUrl,
          isAvailable: isAvailable,
        );
        notifyListeners();
      }

      await _repo.toggleFoodAvailability(
        cinemaId: cinemaId,
        foodId: foodId,
        isAvailable: isAvailable,
        actor: actor,
      );
    } catch (e) {
      await loadFoods(cinemaId);
      rethrow;
    }
  }

  Future<void> saveFood({
    required String cinemaId,
    String? foodId,
    required String name,
    required String category,
    required int price,
    required String description,
    required String imageUrl,
    required bool isAvailable,
    required AppUser actor,
  }) async {
    _setLoading(true);
    try {
      await _repo.saveFood(
        cinemaId: cinemaId,
        foodId: foodId,
        name: name,
        category: category,
        price: price,
        description: description,
        imageUrl: imageUrl,
        isAvailable: isAvailable,
        actor: actor,
      );
      await loadFoods(cinemaId);
    } catch (e) {
      _errorMessage = 'Lỗi lưu món ăn: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteFood({
    required String cinemaId,
    required String foodId,
    required AppUser actor,
  }) async {
    _setLoading(true);
    try {
      await _repo.deleteFood(
        cinemaId: cinemaId,
        foodId: foodId,
        actor: actor,
      );
      await loadFoods(cinemaId);
    } catch (e) {
      _errorMessage = 'Lỗi xóa món ăn: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // 6. AUDIT LOGS
  // ---------------------------------------------------------------------------
  Future<void> loadAuditLogs(String cinemaId) async {
    _setLoading(true);
    try {
      _auditLogs = await _repo.getAuditLogs(cinemaId);
    } catch (_) {}
    _setLoading(false);
  }
}

