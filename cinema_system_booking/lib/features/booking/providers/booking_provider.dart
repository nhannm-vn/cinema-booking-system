import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../core/config/app_constants.dart';
import '../../../shared/widgets/seat_widget.dart';
import '../models/cinema.dart';
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

  int get totalSeatPrice =>
      _selectedSeats.fold(0, (sum, seat) => sum + seat.price);

  String get selectedSeatIdsText =>
      _selectedSeats.map((s) => s.id).join(', ');

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
    _seatError = null;
    _isLoadingSeats = true;
    notifyListeners();

    try {
      _selectedRoom = await _repo.getRoom(showtime.cinemaId, showtime.roomId);

      // Listen to realtime seat updates
      _seatSub?.cancel();
      _seatSub = _repo.getSeatStatesStream(showtime.id).listen((states) {
        _seatStates = {for (final s in states) s.seatId: s};
        // Auto remove any selected seat that was taken by others
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

  /// Toggle selecting a seat with max limit check (SEAT-01, REQUIREMENTS 4.1)
  bool toggleSeatSelection(String seatId, SeatType type) {
    final existingIndex = _selectedSeats.indexWhere((s) => s.id == seatId);
    if (existingIndex >= 0) {
      _selectedSeats.removeAt(existingIndex);
      notifyListeners();
      return true;
    }

    if (_selectedSeats.length >= AppConstants.maxSeatsPerBooking) {
      return false; // Exceeded limit
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

  /// Sinh mã booking 8 ký tự ngẫu nhiên (A-Z bỏ O, I; số 2-9)
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

      return bookingCode;
    } finally {
      _isHolding = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _seatSub?.cancel();
    super.dispose();
  }
}
