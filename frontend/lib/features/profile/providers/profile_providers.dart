import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/profile/notifiers/profile_notifier.dart';
import 'package:focus_app/features/profile/notifiers/profile_state.dart';

final profileNotifierProvider = ChangeNotifierProvider<ProfileNotifier>(
  (_) => ProfileNotifier(),
);

final profileStateProvider = Provider<ProfileState>(
  (ref) => ref.watch(profileNotifierProvider).state,
);