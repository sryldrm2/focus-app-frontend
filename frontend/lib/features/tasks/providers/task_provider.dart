import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/tasks/notifiers/task_notifier.dart';

final taskNotifierProvider = ChangeNotifierProvider<TaskNotifier>(
  (_) => TaskNotifier(),
);