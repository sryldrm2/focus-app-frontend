import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/stats/notifiers/stats_notifier.dart';

final statsNotifierProvider = ChangeNotifierProvider<StatsNotifier>(
  (_) => StatsNotifier(),
);

final statsStateProvider = Provider<StatsState>(
  (ref) => ref.watch(statsNotifierProvider).state,
);