import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/pomodoro/notifiers/pomodoro_notifier.dart';
 
final pomodoroNotifierProvider = ChangeNotifierProvider<PomodoroNotifier>(
  (_) => PomodoroNotifier(),
);
 