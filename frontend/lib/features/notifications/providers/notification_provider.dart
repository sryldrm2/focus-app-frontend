import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/notifications/notifiers/notification_notifier.dart';
import 'package:focus_app/features/notifications/notifiers/notification_settings_notifier.dart';

final notificationNotifierProvider =
    ChangeNotifierProvider<NotificationNotifier>(
  (_) => NotificationNotifier(),
);

final notificationSettingsProvider =
    ChangeNotifierProvider<NotificationSettingsNotifier>((ref) {
  final notifier = NotificationSettingsNotifier();
  notifier.load();
  return notifier;
});

final notificationStateProvider = Provider<NotificationState>(
  (ref) => ref.watch(notificationNotifierProvider).state,
);

final localNotificationsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(notificationSettingsProvider).localNotificationsEnabled,
);