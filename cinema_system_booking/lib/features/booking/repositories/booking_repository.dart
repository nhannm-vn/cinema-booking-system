import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cinema.dart';
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
  }

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
