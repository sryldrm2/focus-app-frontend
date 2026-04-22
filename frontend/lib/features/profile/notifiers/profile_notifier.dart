import 'package:flutter/foundation.dart';
import 'package:focus_app/features/profile/notifiers/profile_state.dart';
import 'package:focus_app/features/profile/network/users_service.dart';
import 'package:focus_app/features/social/network/social_service.dart';

class ProfileNotifier extends ChangeNotifier {
  final _users = UsersService();
  final _social = SocialService();

  ProfileState _state = const ProfileState();
  ProfileState get state => _state;

  void _emit(ProfileState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> load(String userId) async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final userRes = await _users.getById(userId);

      if (userRes.data == null) {
        _emit(
          _state.copyWith(
            isLoading: false,
            user: null,
            friendCount: 0,
            errorMessage: 'Kullanıcı bulunamadı.',
          ),
        );
        return;
      }

      _emit(
        _state.copyWith(
          isLoading: true,
          user: userRes.data,
          errorMessage: null,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return;
    }

    try {
      final friendsRes = await _social.getMyFriends();
      _emit(
        _state.copyWith(
          isLoading: false,
          friendCount: friendsRes.data?.length ?? 0,
        ),
      );
    } catch (_) {
      _emit(_state.copyWith(isLoading: false, friendCount: 0));
    }
  }

  Future<void> updateProfile(
    String userId, {
    String? name,
    String? surname,
    String? nickname,
  }) async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _users.update(
        userId,
        name: name,
        surname: surname,
        nickname: nickname,
      );
      await load(userId);
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      rethrow;
    }
  }
}
