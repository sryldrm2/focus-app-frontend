import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/notifications/models/notification_model.dart';

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

class LocalNotificationService {
  static const String channelId = 'focus_app_notifications';
  static const String channelName = 'Focus App Notifications';
  static const String channelDescription = 'Focus App realtime notifications';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final Set<String> _shownNotificationIds = {};

  bool _localNotificationsEnabled = true;

  bool get localNotificationsEnabled => _localNotificationsEnabled;

  void setLocalNotificationsEnabled(bool enabled) {
    _localNotificationsEnabled = enabled;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);

    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  Future<void> requestPermission() async {
    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    final iosImplementation = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> showNotification(NotificationModel notification) async {
    if (!_localNotificationsEnabled) return;
    if (!_initialized) return;

    if (notification.notificationId.isEmpty) return;
    if (_shownNotificationIds.contains(notification.notificationId)) return;

    _shownNotificationIds.add(notification.notificationId);

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        id: _stableNotificationId(notification.notificationId),
        title: notification.title,
        body: notification.message,
        notificationDetails: details,
      );
    } catch (e) {
      _shownNotificationIds.remove(notification.notificationId);
      debugPrint('Local notification show error: $e');
    }
  }

  void resetSession() {
    _shownNotificationIds.clear();
  }

  int _stableNotificationId(String notificationId) {
    return notificationId.hashCode & 0x7FFFFFFF;
  }
}
