import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/notifications/notifiers/notification_notifier.dart';

final notificationNotifierProvider =
    ChangeNotifierProvider<NotificationNotifier>(
  (_) => NotificationNotifier(),
);

final notificationStateProvider = Provider<NotificationState>(
  (ref) => ref.watch(notificationNotifierProvider).state,
);