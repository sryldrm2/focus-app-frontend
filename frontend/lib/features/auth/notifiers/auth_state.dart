import 'package:focus_app/features/auth/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final UserModel? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    UserModel? user,
  }) =>
      AuthState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        user: user ?? this.user,
      );
}