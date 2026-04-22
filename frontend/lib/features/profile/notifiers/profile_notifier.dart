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
      final friendsRes = await _social.getMyFriends();
      _emit(
        _state.copyWith(
          isLoading: false,
          user: userRes.data,
          friendCount: friendsRes.data?.length ?? 0,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
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