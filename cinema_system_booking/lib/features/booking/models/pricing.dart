import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/widgets/seat_widget.dart';

class PricingRules {
  const PricingRules({
    required this.baseByFormat,
    required this.vipSurcharge,
    required this.coupleSurcharge,
    required this.weekendSurcharge,
    required this.primeTimeSurcharge,
    required this.primeStartHour,
    required this.primeEndHour,
    required this.weekendWeekdays,
  });

  final Map<String, int> baseByFormat;
  final int vipSurcharge;
  final int coupleSurcharge;
  final int weekendSurcharge;
  final int primeTimeSurcharge;
  final int primeStartHour;
  final int primeEndHour;
  final List<int> weekendWeekdays;

  static const defaultRules = PricingRules(
    baseByFormat: {
      '2D': 80000,
      '3D': 100000,
      'IMAX': 120000,
    },
    vipSurcharge: 20000,
    coupleSurcharge: 20000,
    weekendSurcharge: 10000,
    primeTimeSurcharge: 10000,
    primeStartHour: 18,
    primeEndHour: 22,
    weekendWeekdays: [5, 6, 7],
  );

  int calculateSeatPrice({
    required String format,
    required SeatType seatType,
    required DateTime showtime,
  }) {
    final base = baseByFormat[format] ?? baseByFormat['2D'] ?? 80000;
    final isWeekend = weekendWeekdays.contains(showtime.weekday);
    final isPrimeTime =
        showtime.hour >= primeStartHour && showtime.hour < primeEndHour;

    final timeSurcharge =
        (isWeekend ? weekendSurcharge : 0) + (isPrimeTime ? primeTimeSurcharge : 0);

    if (seatType == SeatType.couple) {
      return (2 * base) + coupleSurcharge + timeSurcharge;
    }

    final typeSurcharge = seatType == SeatType.vip ? vipSurcharge : 0;
    return base + typeSurcharge + timeSurcharge;
  }

  factory PricingRules.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawBase = data['baseByFormat'] as Map<String, dynamic>? ?? {};
    final base = rawBase.map((k, v) => MapEntry(k, (v as num).toInt()));

    return PricingRules(
      baseByFormat: base.isNotEmpty ? base : defaultRules.baseByFormat,
      vipSurcharge: (data['vipSurcharge'] as num?)?.toInt() ?? 20000,
      coupleSurcharge: (data['coupleSurcharge'] as num?)?.toInt() ?? 20000,
      weekendSurcharge: (data['weekendSurcharge'] as num?)?.toInt() ?? 10000,
      primeTimeSurcharge: (data['primeTimeSurcharge'] as num?)?.toInt() ?? 10000,
      primeStartHour: (data['primeStartHour'] as num?)?.toInt() ?? 18,
      primeEndHour: (data['primeEndHour'] as num?)?.toInt() ?? 22,
      weekendWeekdays: List<int>.from(data['weekendWeekdays'] ?? [5, 6, 7]),
    );
  }
}
