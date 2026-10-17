import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_constants.dart';
import '../../../shared/widgets/seat_widget.dart';
import '../models/booking_model.dart';
import '../models/cinema.dart';
import '../models/food_item.dart';
import '../models/pricing.dart';
import '../models/room.dart';
import '../models/seat_model.dart';
import '../models/showtime.dart';
import '../repositories/booking_repository.dart';

class BookingProvider extends ChangeNotifier {
  BookingProvider({required BookingRepository repo}) : _repo = repo {
    _initDates();
    _loadPricing();
  }

  final BookingRepository _repo;

  // Showtime selection state (S05)
  late List<DateTime> _availableDates;
  DateTime _selectedDate = DateTime.now();
  List<Showtime> _showtimes = [];
  List<Cinema> _cinemas = [];
  bool _isLoadingShowtimes = false;
  String? _showtimeError;

  // Seat selection state (S06)
  Showtime? _selectedShowtime;
  Cinema? _selectedCinema;
  Room? _selectedRoom;
  Map<String, SeatState> _seatStates = {};
  final List<SelectedSeat> _selectedSeats = [];
  PricingRules _pricing = PricingRules.defaultRules;
  bool _isLoadingSeats = false;
  String? _seatError;
  bool _isHolding = false;
  StreamSubscription<List<SeatState>>? _seatSub;

  // Booking & Hold state
  String? _currentBookingCode;
  DateTime? _holdUntil;

  // Food selection state (S07)
  List<FoodItem> _foodList = [];
  bool _isLoadingFoods = false;
  final Map<String, SelectedFood> _selectedFoods = {};

  // Payment state (S08)
  String? _voucherCode;
  int _discount = 0;
  bool _isPaying = false;

  List<DateTime> get availableDates => _availableDates;
  DateTime get selectedDate => _selectedDate;
  List<Showtime> get showtimes => _showtimes;
  List<Cinema> get cinemas => _cinemas;
  bool get isLoadingShowtimes => _isLoadingShowtimes;
  String? get showtimeError => _showtimeError;

  Showtime? get selectedShowtime => _selectedShowtime;
  Cinema? get selectedCinema => _selectedCinema;
  Room? get selectedRoom => _selectedRoom;
  Map<String, SeatState> get seatStates => _seatStates;
  List<SelectedSeat> get selectedSeats => List.unmodifiable(_selectedSeats);
  PricingRules get pricing => _pricing;
  bool get isLoadingSeats => _isLoadingSeats;
  String? get seatError => _seatError;
  bool get isHolding => _isHolding;

  String? get currentBookingCode => _currentBookingCode;
  DateTime? get holdUntil => _holdUntil;

  List<FoodItem> get foodList => _foodList;
  bool get isLoadingFoods => _isLoadingFoods;
  Map<String, SelectedFood> get selectedFoods => Map.unmodifiable(_selectedFoods);

  String? get voucherCode => _voucherCode;
  int get discount => _discount;
  bool get isPaying => _isPaying;

  int get totalSeatPrice =>
      _selectedSeats.fold(0, (sum, seat) => sum + seat.price);

  int get foodTotal => _selectedFoods.values
      .fold(0, (sum, item) => sum + item.totalPrice);

  int get grandTotal => (totalSeatPrice + foodTotal - _discount).clamp(0, 999999999);

  String get selectedSeatIdsText =>
      _selectedSeats.map((s) => s.id).join(', ');

  String get foodSummary {
    if (_selectedFoods.isEmpty) return '';
    return _selectedFoods.values
        .map((f) => '${f.quantity}x ${f.name}')
        .join(', ');
  }

  void _initDates() {
    final now = DateTime.now();
    _availableDates = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day + i);
    });
    _selectedDate = _availableDates.first;
  }

  Future<void> _loadPricing() async {
    _pricing = await _repo.getPricingRules();
    notifyListeners();
  }

  Future<void> loadShowtimes(String movieId, {DateTime? date}) async {
    if (date != null) {
      _selectedDate = date;
    }
    _isLoadingShowtimes = true;
    _showtimeError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repo.getCinemas(),
        _repo.getShowtimes(movieId: movieId, date: _selectedDate),
      ]);

      _cinemas = results[0] as List<Cinema>;
      _showtimes = results[1] as List<Showtime>;
    } catch (e) {
      _showtimeError = 'Không thể tải lịch chiếu: $e';
    } finally {
      _isLoadingShowtimes = false;
      notifyListeners();
    }
  }

  void selectDate(DateTime date, String movieId) {
    _selectedDate = date;
    loadShowtimes(movieId, date: date);
  }

  Future<void> initSeatSelection({
    required Showtime showtime,
    required Cinema cinema,
  }) async {
    _selectedShowtime = showtime;
    _selectedCinema = cinema;
    _selectedSeats.clear();
    _selectedFoods.clear();
    _voucherCode = null;
    _discount = 0;
    _seatError = null;
    _isLoadingSeats = true;
    _currentBookingCode = null;
    _holdUntil = null;
    notifyListeners();

    try {
      _selectedRoom = await _repo.getRoom(showtime.cinemaId, showtime.roomId);

      _seatSub?.cancel();
      _seatSub = _repo.getSeatStatesStream(showtime.id).listen((states) {
        _seatStates = {for (final s in states) s.seatId: s};
        _selectedSeats.removeWhere((selected) {
          final state = _seatStates[selected.id];
          return state != null && state.status == 'sold';
        });
        notifyListeners();
      });
    } catch (e) {
      _seatError = 'Không thể tải sơ đồ ghế: $e';
    } finally {
      _isLoadingSeats = false;
      notifyListeners();
    }
  }

  bool toggleSeatSelection(String seatId, SeatType type) {
    final existingIndex = _selectedSeats.indexWhere((s) => s.id == seatId);
    if (existingIndex >= 0) {
      _selectedSeats.removeAt(existingIndex);
      notifyListeners();
      return true;
    }

    if (_selectedSeats.length >= AppConstants.maxSeatsPerBooking) {
      return false;
    }

    final price = _pricing.calculateSeatPrice(
      format: _selectedShowtime?.format ?? '2D',
      seatType: type,
      showtime: _selectedShowtime?.startTime ?? DateTime.now(),
    );

    _selectedSeats.add(SelectedSeat(
      id: seatId,
      type: type,
      price: price,
    ));
    notifyListeners();
    return true;
  }

  void clearSelection() {
    _selectedSeats.clear();
    notifyListeners();
  }

  String generateBookingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> holdSeats({
    required String uid,
    required String movieTitle,
    required String posterUrl,
    required String ageRating,
  }) async {
    if (_selectedShowtime == null ||
        _selectedCinema == null ||
        _selectedRoom == null) {
      throw StateError('Chưa chọn suất chiếu');
    }

    if (_selectedSeats.isEmpty) {
      throw StateError('Vui lòng chọn ít nhất 1 ghế');
    }

    _isHolding = true;
    notifyListeners();

    final bookingCode = generateBookingCode();
    final holdExpiry = DateTime.now().add(AppConstants.holdDurationOnline);

    try {
      final bookingData = {
        'userId': uid,
        'customerName': null,
        'channel': 'online',
        'soldBy': null,
        'showtimeId': _selectedShowtime!.id,
        'cinemaId': _selectedCinema!.id,
        'cinemaName': _selectedCinema!.name,
        'movieId': _selectedShowtime!.movieId,
        'movieTitle': movieTitle,
        'posterUrl': posterUrl,
        'ageRating': ageRating,
        'roomName': _selectedRoom!.name,
        'format': _selectedShowtime!.format,
        'showtimeStart': _selectedShowtime!.startTime,
        'seats': _selectedSeats.map((s) => s.toMap()).toList(),
        'foods': [],
        'foodStatus': 'none',
        'priceSnapshot': {
          'ticketTotal': totalSeatPrice,
          'foodTotal': 0,
          'discount': 0,
          'total': totalSeatPrice,
        },
      };

      await _repo.holdSeats(
        showtimeId: _selectedShowtime!.id,
        bookingCode: bookingCode,
        uid: uid,
        seatIds: _selectedSeats.map((s) => s.id).toList(),
        bookingData: bookingData,
        holdFor: AppConstants.holdDurationOnline,
      );

      _currentBookingCode = bookingCode;
      _holdUntil = holdExpiry;
      return bookingCode;
    } finally {
      _isHolding = false;
      notifyListeners();
    }
  }

  // Food Methods (S07)
  Future<void> loadFoods() async {
    if (_selectedCinema == null) return;
    _isLoadingFoods = true;
    notifyListeners();

    try {
      _foodList = await _repo.getFoods(_selectedCinema!.id);
    } finally {
      _isLoadingFoods = false;
      notifyListeners();
    }
  }

  void incrementFood(FoodItem food) {
    final current = _selectedFoods[food.id];
    final qty = (current?.quantity ?? 0) + 1;
    _selectedFoods[food.id] = SelectedFood(
      foodId: food.id,
      name: food.name,
      quantity: qty,
      unitPrice: food.price,
    );
    notifyListeners();
  }

  void decrementFood(FoodItem food) {
    final current = _selectedFoods[food.id];
    if (current == null) return;

    if (current.quantity <= 1) {
      _selectedFoods.remove(food.id);
    } else {
      _selectedFoods[food.id] = SelectedFood(
        foodId: food.id,
        name: food.name,
        quantity: current.quantity - 1,
        unitPrice: food.price,
      );
    }
    notifyListeners();
  }

  int getFoodQuantity(String foodId) {
    return _selectedFoods[foodId]?.quantity ?? 0;
  }

  Future<void> saveBookingFoods() async {
    if (_currentBookingCode == null) return;
    final foodMaps = _selectedFoods.values.map((f) => f.toMap()).toList();
    await _repo.updateBookingFoods(
      bookingCode: _currentBookingCode!,
      foods: foodMaps,
      foodTotal: foodTotal,
      total: grandTotal,
    );
  }

  // Voucher & Payment Methods (S08)
  bool applyVoucher(String code) {
    final cleaned = code.trim().toUpperCase();
    if (cleaned == 'DISCOUNT20' || cleaned == 'CINEMA20') {
      _voucherCode = cleaned;
      _discount = 20000;
      notifyListeners();
      return true;
    } else if (cleaned == 'VIP50') {
      _voucherCode = cleaned;
      _discount = 50000;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeVoucher() {
    _voucherCode = null;
    _discount = 0;
    notifyListeners();
  }

  Future<void> confirmPayment({
    required String paymentMethod,
    String? txnRef,
  }) async {
    if (_currentBookingCode == null) {
      throw StateError('Mã đơn không tồn tại');
    }

    _isPaying = true;
    notifyListeners();

    try {
      final ref = txnRef ?? 'TXN-${DateTime.now().millisecondsSinceEpoch}';
      final vnpNo = 'VNP${Random().nextInt(99999999).toString().padLeft(8, '0')}';

      await _repo.confirmPaid(
        bookingCode: _currentBookingCode!,
        txnRef: ref,
        vnpTransactionNo: vnpNo,
        bankCode: 'NCB',
        paymentMethod: paymentMethod,
      );
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }

  // User Bookings state (S10)
  List<BookingModel> _userBookings = [];
  bool _isLoadingBookings = false;

  List<BookingModel> get userBookings => _userBookings;
  bool get isLoadingBookings => _isLoadingBookings;

  List<BookingModel> get upcomingBookings =>
      _userBookings.where((b) => b.isUpcoming).toList();

  List<BookingModel> get usedBookings =>
      _userBookings.where((b) => b.isUsed).toList();

  List<BookingModel> get cancelledBookings =>
      _userBookings.where((b) => b.isCancelled).toList();

  Future<void> loadUserBookings(String userId) async {
    _isLoadingBookings = true;
    notifyListeners();

    try {
      _userBookings = await _repo.getUserBookings(userId);
    } catch (_) {
      _userBookings = [];
    } finally {
      _isLoadingBookings = false;
      notifyListeners();
    }
  }

  Future<bool> cancelBooking(String bookingCode, String userId) async {
    final success = await _repo.cancelBooking(bookingCode);
    if (success) {
      await loadUserBookings(userId);
    }
    return success;
  }

  @override
  void dispose() {
    _seatSub?.cancel();
    super.dispose();
  }
}
