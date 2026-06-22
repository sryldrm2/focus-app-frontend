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
    final hasExistingNotifications = _state.notifications.isNotEmpty;
    if (!hasExistingNotifications) {
      _emit(_state.copyWith(isLoading: true, errorMessage: null));
    }

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Token bulunamadı');

      final fromDb = await _service.getNotifications(token);
      final merged = _mergeNotifications(fromDb, _state.notifications);
      final unreadCount = merged.where((n) => !n.isRead).length;

      _emit(
        _state.copyWith(
          isLoading: false,
          notifications: merged,
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

      final dbUnreadCount = await _service.getUnreadCount(token);
      final ephemeralUnreadCount = _state.notifications
          .where((n) => n.isEphemeral && !n.isRead)
          .length;

      _emit(
        _state.copyWith(unreadCount: dbUnreadCount + ephemeralUnreadCount),
      );
    } catch (_) {}
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _state.notifications.indexWhere(
      (n) => n.notificationId == notificationId,
    );
    if (index == -1) return;

    final notification = _state.notifications[index];

    if (notification.isEphemeral) {
      _markAsReadLocally(notificationId);
      return;
    }

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;

      await _service.markAsRead(token, notificationId);
      _markAsReadLocally(notificationId);
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

  // SignalR üzerinden gelen real-time bildirimleri listeye ekler.
  void addRealtimeNotification(NotificationModel notification) {
    if (_state.notifications
        .any((n) => n.notificationId == notification.notificationId)) {
      return;
    }

    final updated = [notification, ..._state.notifications];

    final unreadCount =
        notification.isRead ? _state.unreadCount : _state.unreadCount + 1;

    _emit(
      _state.copyWith(
        notifications: updated,
        unreadCount: unreadCount,
      ),
    );
  }

  List<NotificationModel> _mergeNotifications(
    List<NotificationModel> fromDb,
    List<NotificationModel> existing,
  ) {
    final byId = <String, NotificationModel>{
      for (final notification in fromDb) notification.notificationId: notification,
    };

    for (final notification in existing) {
      if (!byId.containsKey(notification.notificationId)) {
        byId[notification.notificationId] = notification;
      }
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    return merged;
  }

  void _markAsReadLocally(String notificationId) {
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
  }
}