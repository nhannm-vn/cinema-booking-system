abstract final class AppConstants {
  static const String appName = 'CINEMA';

  // Booking Limits & Expiry (Theo REQUIREMENTS.md & DATA.md)
  static const int maxSeatsPerBooking = 8;
  static const Duration holdDurationOnline = Duration(minutes: 5);
  static const Duration holdDurationCounter = Duration(minutes: 3);
  static const Duration onlineCutoffBeforeShow = Duration(minutes: 15);
  static const Duration counterCutoffAfterShow = Duration(minutes: 15);
  static const Duration checkInWindowBeforeShow = Duration(minutes: 60);
  static const Duration checkInWindowAfterShow = Duration(minutes: 15);
  static const Duration cancellationDeadline = Duration(hours: 2);
}
