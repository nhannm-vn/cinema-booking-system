import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../models/cinema.dart';
import '../models/food_item.dart';
import '../models/pricing.dart';
import '../models/room.dart';
import '../models/seat_model.dart';
import '../models/showtime.dart';

class SeatTakenException implements Exception {
  SeatTakenException(this.seatId);
  final String seatId;

  @override
  String toString() => 'Ghế $seatId vừa có người chọn. Vui lòng chọn ghế khác.';
}

class BookingRepository {
  BookingRepository({FirebaseFirestore? firestore}) : _firestore = firestore;

  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  Future<List<Cinema>> getCinemas() async {
    try {
      final snap = await _db
          .collection('cinemas')
          .where('isActive', isEqualTo: true)
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) => Cinema.fromFirestore(doc)).toList();
      }
    } catch (_) {}

    return _sampleCinemas;
  }

  Future<Room?> getRoom(String cinemaId, String roomId) async {
    try {
      final doc = await _db
          .collection('cinemas')
          .doc(cinemaId)
          .collection('rooms')
          .doc(roomId)
          .get();
      if (doc.exists) {
        return Room.fromFirestore(doc);
      }
    } catch (_) {}

    return _sampleRooms[roomId] ?? _defaultRoom;
  }

  Future<List<Showtime>> getShowtimes({
    required String movieId,
    required DateTime date,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      final snap = await _db
          .collection('showtimes')
          .where('movieId', isEqualTo: movieId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('startTime')
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => Showtime.fromFirestore(d)).toList();
      }
    } catch (_) {}

    return _generateFallbackShowtimes(movieId, date);
  }

  Stream<List<SeatState>> getSeatStatesStream(String showtimeId) {
    try {
      return _db
          .collection('showtimes')
          .doc(showtimeId)
          .collection('seats')
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => SeatState.fromFirestore(doc)).toList());
    } catch (_) {
      return Stream.value([]);
    }
  }

  Future<PricingRules> getPricingRules() async {
    try {
      final doc = await _db.collection('settings').doc('pricing').get();
      if (doc.exists) {
        return PricingRules.fromFirestore(doc);
      }
    } catch (_) {}

    return PricingRules.defaultRules;
  }

  Future<List<FoodItem>> getFoods(String cinemaId) async {
    try {
      final snap = await _db
          .collection('cinemas')
          .doc(cinemaId)
          .collection('foods')
          .get();
      if (snap.docs.isNotEmpty) {
        return snap.docs
            .map((doc) => FoodItem.fromFirestore(doc, cinemaId))
            .toList();
      }
    } catch (_) {}

    return _sampleFoods(cinemaId);
  }

  /// Atomic Firestore Transaction to hold seats (SEAT-03 & DATA.md 6.1)
  Future<void> holdSeats({
    required String showtimeId,
    required String bookingCode,
    required String uid,
    required List<String> seatIds,
    required Map<String, dynamic> bookingData,
    Duration holdFor = const Duration(minutes: 5),
  }) async {
    try {
      final seats =
          _db.collection('showtimes').doc(showtimeId).collection('seats');
      final bookingRef = _db.collection('bookings').doc(bookingCode);
      final holdUntil = Timestamp.fromDate(DateTime.now().add(holdFor));

      await _db.runTransaction((tx) async {
        final taken = await tx.get(bookingRef);
        if (taken.exists) throw StateError('Trùng mã booking, sinh mã khác');

        final now = Timestamp.now();
        final snaps = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final id in seatIds) {
          snaps.add(await tx.get(seats.doc(id)));
        }

        for (final s in snaps) {
          if (!s.exists) continue;
          final d = s.data()!;
          final mine = d['bookingId'] == bookingCode;
          final alive = d['status'] == 'holding' &&
              (d['holdUntil'] as Timestamp).compareTo(now) > 0;
          if (!mine && (d['status'] == 'sold' || alive)) {
            throw SeatTakenException(s.id);
          }
        }

        for (final id in seatIds) {
          tx.set(seats.doc(id), {
            'status': 'holding',
            'bookingId': bookingCode,
            'holderId': uid,
            'holdUntil': holdUntil,
          });
        }

        tx.set(bookingRef, {
          ...bookingData,
          'status': 'holding',
          'holdUntil': holdUntil,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (e is SeatTakenException) rethrow;
      // In offline / mock mode, allow holding to proceed gracefully
    }

    // Track locally for demo / offline consistency
    _localBookings.removeWhere((b) => b.id == bookingCode);
    _localBookings.insert(
      0,
      BookingModel(
        id: bookingCode,
        userId: uid,
        customerName: bookingData['customerName'] as String?,
        movieId: bookingData['movieId'] as String? ?? '',
        movieTitle:
            bookingData['movieTitle'] as String? ?? 'Dune: Hành Tinh Cát 2',
        posterUrl: bookingData['posterUrl'] as String? ??
            'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
        ageRating: bookingData['ageRating'] as String? ?? 'T16',
        cinemaId: bookingData['cinemaId'] as String? ?? 'cn_q1',
        cinemaName: bookingData['cinemaName'] as String? ?? 'Cinema Flagship',
        roomName: bookingData['roomName'] as String? ?? 'Screen 1',
        format: bookingData['format'] as String? ?? '2D',
        showtimeStart: bookingData['showtimeStart'] is DateTime
            ? bookingData['showtimeStart'] as DateTime
            : DateTime.now().add(const Duration(hours: 4)),
        seatIds: seatIds,
        foods: const [],
        foodSummary: null,
        totalAmount:
            (bookingData['priceSnapshot'] as Map?)?['total'] as int? ?? 120000,
        status: 'holding',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Update booking with selected foods before checkout
  Future<void> updateBookingFoods({
    required String bookingCode,
    required List<Map<String, dynamic>> foods,
    required int foodTotal,
    required int total,
  }) async {
    try {
      final bookingRef = _db.collection('bookings').doc(bookingCode);
      await bookingRef.update({
        'foods': foods,
        'foodStatus': foods.isEmpty ? 'none' : 'pending',
        'priceSnapshot.foodTotal': foodTotal,
        'priceSnapshot.total': total,
      });
    } catch (_) {}

    final idx = _localBookings.indexWhere((b) => b.id == bookingCode);
    if (idx != -1) {
      final b = _localBookings[idx];
      String? summary;
      if (foods.isNotEmpty) {
        summary = foods.map((f) => '${f['qty']}x ${f['name']}').join(', ');
      }
      _localBookings[idx] = BookingModel(
        id: b.id,
        userId: b.userId,
        customerName: b.customerName,
        movieId: b.movieId,
        movieTitle: b.movieTitle,
        posterUrl: b.posterUrl,
        ageRating: b.ageRating,
        cinemaId: b.cinemaId,
        cinemaName: b.cinemaName,
        roomName: b.roomName,
        format: b.format,
        showtimeStart: b.showtimeStart,
        seatIds: b.seatIds,
        foods: foods,
        foodSummary: summary,
        totalAmount: total,
        status: b.status,
        createdAt: b.createdAt,
      );
    }
  }

  /// Confirm payment atomic transaction (DATA.md 6.2)
  Future<void> confirmPaid({
    required String bookingCode,
    required String txnRef,
    required String vnpTransactionNo,
    required String bankCode,
    required String paymentMethod,
  }) async {
    try {
      final bookingRef = _db.collection('bookings').doc(bookingCode);

      await _db.runTransaction((tx) async {
        final b = await tx.get(bookingRef);
        if (!b.exists) return;
        final data = b.data()!;

        final showtimeRef =
            _db.collection('showtimes').doc(data['showtimeId'] as String);
        final seatList = data['seats'] as List? ?? [];
        final seatRefs = [
          for (final s in seatList)
            showtimeRef.collection('seats').doc((s as Map)['id'] as String),
        ];

        for (final r in seatRefs) {
          tx.update(r, {'status': 'sold', 'holdUntil': FieldValue.delete()});
        }
        tx.update(
            showtimeRef, {'soldSeats': FieldValue.increment(seatRefs.length)});

        final foods = data['foods'] as List? ?? [];
        tx.update(bookingRef, {
          'status': 'paid',
          'paymentMethod': paymentMethod,
          'vnpTransactionNo': vnpTransactionNo,
          'paidAt': FieldValue.serverTimestamp(),
          'holdUntil': FieldValue.delete(),
          'foodStatus': foods.isEmpty ? 'none' : 'pending',
        });

        tx.set(bookingRef.collection('payments').doc(txnRef), {
          'status': 'success',
          'provider': paymentMethod,
          'responseCode': '00',
          'vnpTransactionNo': vnpTransactionNo,
          'bankCode': bankCode,
          'paidAt': FieldValue.serverTimestamp(),
        });

        final uid = data['userId'] as String?;
        if (uid != null && uid.isNotEmpty) {
          tx.set(
            _db.collection('users').doc(uid).collection('notifications').doc(),
            {
              'type': 'bookingPaid',
              'title': 'Đặt vé thành công',
              'body': '${data['movieTitle']} · ${data['cinemaName']}',
              'bookingId': bookingCode,
              'isRead': false,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );
        }
      });
    } catch (_) {
      // In offline / demo mode
    }

    final idx = _localBookings.indexWhere((b) => b.id == bookingCode);
    if (idx != -1) {
      _localBookings[idx] = _localBookings[idx].copyWith(status: 'paid');
    }
  }

  /// Get user bookings (S10)
  Future<List<BookingModel>> getUserBookings(String userId) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
      }
    } catch (_) {}

    // Fallback: local memory cache or sample bookings
    final filtered = _localBookings
        .where((b) =>
            b.userId == userId ||
            userId == 'guest' ||
            b.userId.isEmpty ||
            b.userId == 'user_customer_1')
        .toList();

    if (filtered.isNotEmpty) {
      return filtered;
    }
    return _initialSampleBookings;
  }

  /// Cancel booking (Mục S - S10)
  Future<bool> cancelBooking(String bookingCode) async {
    try {
      final bookingRef = _db.collection('bookings').doc(bookingCode);
      await bookingRef.update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    final idx = _localBookings.indexWhere((b) => b.id == bookingCode);
    if (idx != -1) {
      _localBookings[idx] = _localBookings[idx].copyWith(status: 'cancelled');
    }
    return true;
  }

  // Local fallback storage
  static final List<BookingModel> _localBookings = [..._initialSampleBookings];

  static final List<BookingModel> _initialSampleBookings = [
    BookingModel(
      id: 'DN8872KP',
      userId: 'user_customer_1',
      customerName: 'Nguyễn Văn Tester',
      movieId: 'mv_dune2',
      movieTitle: 'Dune: Hành Tinh Cát 2',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/8b8R8l88Qje9dn9OE8PY05Nxl1X.jpg',
      ageRating: 'T16',
      cinemaId: 'cn_q1',
      cinemaName: 'Cinema Flagship Q.1',
      roomName: 'Phòng 01 (IMAX Laser)',
      format: 'IMAX 2D',
      showtimeStart: DateTime.now().add(const Duration(hours: 5)),
      seatIds: const ['F05', 'F06'],
      foods: const [
        {'name': 'Bắp Phô Mai Lớn', 'qty': 1, 'unitPrice': 49000},
        {'name': 'Coca-Cola 32oz', 'qty': 2, 'unitPrice': 30000},
      ],
      foodSummary: '1x Bắp Phô Mai Lớn, 2x Coca-Cola 32oz',
      totalAmount: 329000,
      status: 'paid',
      paymentMethod: 'VNPAY',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      paidAt: DateTime.now().subtract(const Duration(minutes: 55)),
    ),
    BookingModel(
      id: 'MAI9923L',
      userId: 'user_customer_1',
      customerName: 'Nguyễn Văn Tester',
      movieId: 'mv_mai',
      movieTitle: 'Mai',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/1XddMr7eSjF8q8lD5Cj3lJq3w1e.jpg',
      ageRating: 'T18',
      cinemaId: 'cn_q1',
      cinemaName: 'Cinema Flagship Q.1',
      roomName: 'Phòng 02 (Dolby Atmos)',
      format: '2D Phụ Đề',
      showtimeStart: DateTime.now().subtract(const Duration(days: 2)),
      seatIds: const ['D07', 'D08'],
      foods: const [],
      foodSummary: null,
      totalAmount: 200000,
      status: 'used',
      paymentMethod: 'VNPAY',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      paidAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    BookingModel(
      id: 'KONG104B',
      userId: 'user_customer_1',
      customerName: 'Nguyễn Văn Tester',
      movieId: 'mv_gxk',
      movieTitle: 'Godzilla x Kong: Đế Chế Mới',
      posterUrl:
          'https://image.tmdb.org/t/p/w500/bQ2ywkch097AcSJIRHGgf89293C.jpg',
      ageRating: 'T13',
      cinemaId: 'cn_tb',
      cinemaName: 'Cinema Tân Bình Hub',
      roomName: 'Phòng 03',
      format: '3D Lồng Tiếng',
      showtimeStart: DateTime.now().subtract(const Duration(days: 5)),
      seatIds: const ['E08'],
      foods: const [],
      foodSummary: null,
      totalAmount: 110000,
      status: 'cancelled',
      paymentMethod: 'VNPAY',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      paidAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];

  // Fallback and Mock data
  static final List<Cinema> _sampleCinemas = [
    const Cinema(
      id: 'cn_q1',
      name: 'Cinema Quận 1 Flagship',
      address: 'Số 1 Hai Bà Trưng, Bến Nghé, Quận 1, TP.HCM',
      phone: '19001001',
      openingHours: '08:00–23:30',
      latitude: 10.776889,
      longitude: 106.700806,
      imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba',
      isActive: true,
    ),
    const Cinema(
      id: 'cn_tb',
      name: 'Cinema Tân Bình Hub',
      address: 'Số 20 Cộng Hòa, Phường 4, Tân Bình, TP.HCM',
      phone: '19001002',
      openingHours: '08:30–23:00',
      latitude: 10.801556,
      longitude: 106.655861,
      imageUrl: 'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c',
      isActive: true,
    ),
    const Cinema(
      id: 'cn_bt',
      name: 'Cinema Landmark 81',
      address: 'Tầng B1 Vincom Landmark 81, 720A Điện Biên Phủ, Bình Thạnh, TP.HCM',
      phone: '19001003',
      openingHours: '09:00–23:30',
      latitude: 10.795100,
      longitude: 106.721800,
      imageUrl: 'https://images.unsplash.com/photo-1518173946687-a4c8a383392e',
      isActive: true,
    ),
    const Cinema(
      id: 'cn_q7',
      name: 'Cinema Crescent Mall',
      address: 'Tầng 5 Crescent Mall, 101 Tôn Dật Tiên, Tân Phú, Quận 7, TP.HCM',
      phone: '19001004',
      openingHours: '09:00–23:00',
      latitude: 10.729300,
      longitude: 106.719600,
      imageUrl: 'https://images.unsplash.com/photo-1478720568477-152d9b164e26',
      isActive: true,
    ),
  ];

  static const List<String> standardLayout = [
    'NNNNNNNNNN',
    'NNNNNNNNNN',
    'NNVVVVVVNN',
    'NNVVVVVVNN',
    'NNVVVVVVNN',
    'NNVVVVVVNN',
    'NNNNNNNNNN',
    'DDDDDDDDDD',
  ];

  static const _defaultRoom = Room(
    id: 'room_01',
    name: 'Phòng 01 - Standard Prime',
    formats: ['2D', '3D'],
    rows: 8,
    cols: 10,
    seatLayout: standardLayout,
    seatCount: 75,
  );

  static final Map<String, Room> _sampleRooms = {
    'room_01': _defaultRoom,
    'room_02': const Room(
      id: 'room_02',
      name: 'Phòng 02 - IMAX Laser',
      formats: ['IMAX'],
      rows: 8,
      cols: 10,
      seatLayout: standardLayout,
      seatCount: 75,
    ),
  };

  static List<FoodItem> _sampleFoods(String cinemaId) => [
        FoodItem(
          id: 'food_${cinemaId}_01',
          cinemaId: cinemaId,
          name: 'Combo Bắp Nước Solo',
          category: 'combo',
          price: 79000,
          description: '1 bắp ngọt 60oz + 1 nước ngọt 32oz',
          imageUrl:
              'https://images.unsplash.com/photo-1585647347384-2593bc35786b?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_02',
          cinemaId: cinemaId,
          name: 'Combo Couple Thân Mật',
          category: 'combo',
          price: 119000,
          description: '1 bắp lớn + 2 nước ngọt 32oz',
          imageUrl:
              'https://images.unsplash.com/photo-1505686994434-e3cc5abf1330?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_03',
          cinemaId: cinemaId,
          name: 'Combo Party Gia Đình',
          category: 'combo',
          price: 169000,
          description: '2 bắp ngọt + 4 nước ngọt + 1 snack khoai tây',
          imageUrl:
              'https://images.unsplash.com/photo-1572177812156-58036aae439c?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_04',
          cinemaId: cinemaId,
          name: 'Bắp Rang Phô Mai',
          category: 'popcorn',
          price: 49000,
          description: 'Bắp rang bơ lắc bột phô mai béo ngậy',
          imageUrl:
              'https://images.unsplash.com/photo-1578849278619-e73505e9610f?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_05',
          cinemaId: cinemaId,
          name: 'Bắp Rang Caramel',
          category: 'popcorn',
          price: 49000,
          description: 'Bắp thơm giòn phủ sốt caramel đậm vị',
          imageUrl:
              'https://images.unsplash.com/photo-1512149177596-f817c7ef5d4c?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_06',
          cinemaId: cinemaId,
          name: 'Coca-Cola Zero 32oz',
          category: 'drink',
          price: 32000,
          description: 'Nước ngọt có gas không calo mát lạnh',
          imageUrl:
              'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_07',
          cinemaId: cinemaId,
          name: 'Trà Đào Cam Sả',
          category: 'drink',
          price: 39000,
          description: 'Trà trái cây tươi thanh mát giải nhiệt',
          imageUrl:
              'https://images.unsplash.com/photo-1556881286-fc6915169721?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_08',
          cinemaId: cinemaId,
          name: 'Nước Khoáng Dasani 500ml',
          category: 'drink',
          price: 20000,
          description: 'Nước khoáng tinh khiết đóng chai',
          imageUrl:
              'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_09',
          cinemaId: cinemaId,
          name: 'Snack Khoai Tây Lay\'s Vị Tảo',
          category: 'snack',
          price: 25000,
          description: 'Khoai tây sấy giòn tan vị tảo biển',
          imageUrl:
              'https://images.unsplash.com/photo-1566478989037-eec170784d0b?w=400&auto=format&fit=crop&q=80',
          isAvailable: true,
        ),
        FoodItem(
          id: 'food_${cinemaId}_10',
          cinemaId: cinemaId,
          name: 'Xúc Xích Nướng Phô Mai',
          category: 'snack',
          price: 35000,
          description: 'Xúc xích Đức nướng nóng giòn kẹp phô mai',
          imageUrl:
              'https://images.unsplash.com/photo-1627054234584-386b03943343?w=400&auto=format&fit=crop&q=80',
          isAvailable: false,
        ),
      ];

  static List<Showtime> _generateFallbackShowtimes(
      String movieId, DateTime date) {
    final list = <Showtime>[];
    final hours = [
      {'h': 10, 'm': 0, 'f': '2D', 'r': 'room_01', 'c': 'cn_q1'},
      {'h': 13, 'm': 30, 'f': 'IMAX', 'r': 'room_02', 'c': 'cn_q1'},
      {'h': 16, 'm': 45, 'f': '2D', 'r': 'room_01', 'c': 'cn_q1'},
      {'h': 19, 'm': 15, 'f': 'IMAX', 'r': 'room_02', 'c': 'cn_q1'},
      {'h': 21, 'm': 30, 'f': '2D', 'r': 'room_01', 'c': 'cn_q1'},
      {'h': 11, 'm': 15, 'f': '2D', 'r': 'room_01', 'c': 'cn_tb'},
      {'h': 14, 'm': 0, 'f': '3D', 'r': 'room_01', 'c': 'cn_tb'},
      {'h': 18, 'm': 30, 'f': '2D', 'r': 'room_01', 'c': 'cn_tb'},
      {'h': 20, 'm': 45, 'f': '3D', 'r': 'room_01', 'c': 'cn_tb'},
      {'h': 10, 'm': 30, 'f': 'IMAX', 'r': 'room_02', 'c': 'cn_bt'},
      {'h': 15, 'm': 0, 'f': 'IMAX', 'r': 'room_02', 'c': 'cn_bt'},
      {'h': 19, 'm': 45, 'f': 'IMAX', 'r': 'room_02', 'c': 'cn_bt'},
      {'h': 12, 'm': 15, 'f': '2D', 'r': 'room_01', 'c': 'cn_q7'},
      {'h': 17, 'm': 30, 'f': '2D', 'r': 'room_01', 'c': 'cn_q7'},
      {'h': 21, 'm': 0, 'f': '3D', 'r': 'room_01', 'c': 'cn_q7'},
    ];

    for (int i = 0; i < hours.length; i++) {
      final item = hours[i];
      final start = DateTime(
          date.year, date.month, date.day, item['h'] as int, item['m'] as int);
      final end = start.add(const Duration(minutes: 120));

      list.add(Showtime(
        id: 'mock_shw_${item['c']}_${item['r']}_$i',
        movieId: movieId,
        cinemaId: item['c'] as String,
        roomId: item['r'] as String,
        format: item['f'] as String,
        startTime: start,
        endTime: end,
        status: 'scheduled',
        totalSeats: 75,
        soldSeats: (i * 7) % 30,
      ));
    }
    return list;
  }
}
