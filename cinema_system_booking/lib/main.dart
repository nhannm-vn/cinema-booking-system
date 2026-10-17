import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/booking/providers/booking_provider.dart';
import 'features/booking/repositories/booking_repository.dart';
import 'features/movies/providers/movie_provider.dart';
import 'features/movies/repositories/movie_repository.dart';
import 'features/management/providers/management_provider.dart';
import 'features/management/repositories/management_repository.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/notifications/services/local_notification_service.dart';
import 'features/splash/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'shared/widgets/app_scaffold_shell.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('vi', null);
  } catch (e) {
    debugPrint('DateFormatting initialization notice: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  try {
    await LocalNotificationService.instance.initialize();
  } catch (e) {
    debugPrint('LocalNotificationService initialization notice: $e');
  }

  runApp(const CinemaBookingApp());
}

class CinemaBookingApp extends StatelessWidget {
  const CinemaBookingApp({
    super.key,
    this.authRepository,
    this.movieRepository,
    this.bookingRepository,
    this.managementRepository,
    this.showSplash = true,
  });

  final AuthRepository? authRepository;
  final MovieRepository? movieRepository;
  final BookingRepository? bookingRepository;
  final ManagementRepository? managementRepository;
  final bool showSplash;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repo: authRepository ?? AuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              MovieProvider(repo: movieRepository ?? MovieRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BookingProvider(repo: bookingRepository ?? BookingRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ManagementProvider(
            repo: managementRepository ?? ManagementRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Cinema Booking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: showSplash ? const SplashScreen() : const AppScaffoldShell(),
      ),
    );
  }
}
