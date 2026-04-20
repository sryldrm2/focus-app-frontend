import 'package:flutter/foundation.dart';
import 'package:focus_app/features/social/network/social_service.dart';
import 'package:focus_app/features/social/notifiers/social_state.dart';

class SocialNotifier extends ChangeNotifier {
  final _service = SocialService();

  SocialState _state = const SocialState();
  SocialState get state => _state;

  void _emit(SocialState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> loadAll() async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      final pending = await _service.getPendingRequests();
      final sent = await _service.getSentRequests();
      final friends = await _service.getMyFriends();

      _emit(
        _state.copyWith(
          isLoading: false,
          pendingRequests: pending.data ?? const [],
          sentRequests: sent.data ?? const [],
          myFriends: friends.data ?? const [],
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception', ''),
        ),
      );
    }
  }

  Future<void> sendRequest(String receiverId) async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.sendFriendRequest(receiverId: receiverId);
      final sent = await _service.getSentRequests();
      _emit(_state.copyWith(isLoading: false, sentRequests: sent.data ?? const []));
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception', ''),
      ));
      rethrow;
    }
  }

  Future<void> accept(String friendRequestId) async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.acceptFriendRequest(friendRequestId: friendRequestId);
      await loadAll();
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
  Future<void> reject(String friendRequestId) async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.rejectFriendRequest(friendRequestId: friendRequestId);
      await loadAll();
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
  Future<void> removeFriend(String friendId) async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));
    try {
      await _service.removeFriend(friendId: friendId);
      await loadAll();
    } catch (e) {
      _emit(_state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }
}