import 'package:flutter/foundation.dart';
import 'package:focus_app/core/network/token_storage.dart';
import 'package:focus_app/features/notifications/models/notification_model.dart';
import 'package:focus_app/features/notifications/network/notification_service.dart';

class NotificationState {
  final bool isLoading;
  final String? errorMessage;
  final List<NotificationModel> notifications;
  final int unreadCount;

  const NotificationState({
    this.isLoading = false,
    this.errorMessage,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<NotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends ChangeNotifier {
  final _service = NotificationService();

  NotificationState _state = const NotificationState();
  NotificationState get state => _state;

  void _emit(NotificationState state) {
    _state = state;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    _emit(_state.copyWith(isLoading: true, errorMessage: null));

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Token bulunamadı');

      final notifications = await _service.getNotifications(token);
      final unreadCount = notifications.where((n) => !n.isRead).length;

      _emit(
        _state.copyWith(
          isLoading: false,
          notifications: notifications,
          unreadCount: unreadCount,
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

  Future<void> loadUnreadCount() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      final count = await _service.getUnreadCount(token);
      _emit(_state.copyWith(unreadCount: count));
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      await _service.markAsRead(token, notificationId);

      final updated = _state.notifications.map((n) {
        if (n.notificationId == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updated.where((n) => !n.isRead).length;

      _emit(
        _state.copyWith(
          notifications: updated,
          unreadCount: unreadCount,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      await _service.markAllAsRead(token);

      final updated = _state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      _emit(
        _state.copyWith(
          notifications: updated,
          unreadCount: 0,
        ),
      );
    } catch (e) {
      _emit(
        _state.copyWith(
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}