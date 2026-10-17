import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/models/app_user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;
  StreamSubscription? _authSub;
  StreamSubscription? _userDocSub;

  AppUser _currentUser = AppUser.guest();
  bool _isLoading = true;
  String? _errorMessage;

  AuthProvider({AuthRepository? repo}) : _repo = repo ?? AuthRepository() {
    _init();
  }

  AppUser get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser.role != UserRole.guest;
  String? get errorMessage => _errorMessage;

  UserRole get currentRole => _currentUser.role;
  String? get currentCinemaId => _currentUser.cinemaId;

  void _init() {
    _authSub = _repo.authStateChanges.listen((fbUser) {
      _userDocSub?.cancel();
      if (fbUser == null) {
        _currentUser = AppUser.guest();
        _isLoading = false;
        notifyListeners();
      } else {
        _userDocSub =
            _repo.userProfileStream(fbUser.uid).listen((profile) async {
          if (profile == null) {
            _currentUser = AppUser.guest();
          } else if (profile.isLocked) {
            // Ngay lập tức đăng xuất nếu tài khoản bị khóa lúc đang mở app
            await _repo.signOut();
            _currentUser = AppUser.guest();
            _errorMessage = 'Tài khoản đã bị khóa';
          } else {
            _currentUser = profile;
            _errorMessage = null;
          }
          _isLoading = false;
          notifyListeners();
        }, onError: (e) {
          _errorMessage = e.toString();
          _isLoading = false;
          notifyListeners();
        });
      }
    });
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repo.signInWithEmailPassword(
        email: email,
        password: password,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceAll('StateError: ', '')
          .replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repo.registerCustomer(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceAll('StateError: ', '')
          .replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    await _repo.signOut();
    _currentUser = AppUser.guest();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userDocSub?.cancel();
    super.dispose();
  }
}
