import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifiers/auth_notifier.dart';
import '../notifiers/auth_state.dart';

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>(
  (_) => AuthNotifier(),
);

final authStatusProvider = Provider<AuthStatus>(
  (ref) => ref.watch(authNotifierProvider).state.status,
);