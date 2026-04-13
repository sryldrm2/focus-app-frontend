import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/auth_service.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/auth/models/user_model.dart';
import 'auth_state.dart';

class AuthNotifier extends ChangeNotifier {
  final _service = AuthService();

  AuthState _state = const AuthState();
  AuthState get state => _state;

  void _emit(AuthState s) {
    _state = s;
    notifyListeners();
  }

  // ─── SPLASH: token var mı kontrol et ──────────────────────
  Future<void> checkAuth() async {
    _emit(_state.copyWith(status: AuthStatus.loading));
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null) {
        _emit(_state.copyWith(status: AuthStatus.unauthenticated));
        return;
      }
      final response = await _service.getMe(accessToken);
      final data = response['data'] as Map<String, dynamic>?;
      final user = data != null
          ? UserModel(
              userId: data['userId'] ?? '',
              name: '',
              surname: '',
              nickname: data['nickname'] ?? '',
              email: data['email'] ?? '',
              currentStatus: false,
              totalPoints: 0,
              lastSeen: DateTime.now(),
              isOnline: false,
            )
          : null;
      _emit(_state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (_) {
      await _tryRefresh();
    }
  }

  Future<void> _tryRefresh() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken == null) throw Exception('Refresh token yok');
      final response = await _service.refreshToken(refreshToken);
      final data = response['data'] as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      _emit(_state.copyWith(status: AuthStatus.authenticated));
    } catch (_) {
      await TokenStorage.clear();
      _emit(_state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  // ─── LOGIN ────────────────────────────────────────────────
  Future<bool> login({required String email, required String password}) async {
    _emit(_state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final response = await _service.login(
        emailOrNickname: email,
        password: password,
      );
      final data = response['data'] as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _emit(_state.copyWith(status: AuthStatus.authenticated, user: user));
      return true;
    } catch (e) {
      _emit(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.toString().replaceFirst('Exception', ''),
        ),
      );
      return false;
    }
  }

  // ─── REGISTER ─────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String surname,
    required String nickname,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _emit(_state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final response = await _service.register(
        name: name,
        surname: surname,
        nickname: nickname,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      final data = response['data'] as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _emit(_state.copyWith(status: AuthStatus.authenticated, user: user));
      return true;
    } catch (e) {
      _emit(
        _state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: e.toString().replaceFirst('Exception', ''),
        ),
      );
      return false;
    }
  }

  // ─── LOGOUT ───────────────────────────────────────────────
  Future<void> logout() async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken != null) await _service.logout(accessToken);
    } catch (_) {}
    await TokenStorage.clear();
    _emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  // ─── FORGOT PASSWORD ──────────────────────────────────────
  Future<bool> forgotPassword(String email) async {
    return false;
  }
}
