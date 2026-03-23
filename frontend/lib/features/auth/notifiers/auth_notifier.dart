import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_state.dart';

class AuthNotifier extends ChangeNotifier {
  AuthState _state = const AuthState();
  AuthState get state => _state;

  void _emit(AuthState s) {
    _state = s;
    notifyListeners();
  }

  // Splash: SharedPreferences'ta "logged_in" anahtarı var mı?
  Future<void> checkAuth() async {
    _emit(_state.copyWith(status: AuthStatus.loading));
    await Future.delayed(const Duration(milliseconds: 1200));
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('logged_in') ?? false;
    _emit(_state.copyWith(
      status: loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    ));
  }

  // Mock login — herhangi bir email/şifre kabul eder
  Future<bool> login({required String email, required String password}) async {
    _emit(_state.copyWith(status: AuthStatus.loading));
    await Future.delayed(const Duration(milliseconds: 800)); // API simülasyonu
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    _emit(_state.copyWith(status: AuthStatus.authenticated));
    return true;
  }

  // Mock register
  Future<bool> register({
    required String displayName,
    required String username,
    required String email,
    required String password,
  }) async {
    _emit(_state.copyWith(status: AuthStatus.loading));
    await Future.delayed(const Duration(milliseconds: 800));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    _emit(_state.copyWith(status: AuthStatus.authenticated));
    return true;
  }

  // Mock forgot password
  Future<bool> forgotPassword(String email) async {
    _emit(_state.copyWith(status: AuthStatus.loading));
    await Future.delayed(const Duration(milliseconds: 800));
    _emit(_state.copyWith(status: AuthStatus.unauthenticated));
    return true;
  }

  // Çıkış
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in');
    _emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}