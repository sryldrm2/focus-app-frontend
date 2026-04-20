import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/social/notifiers/social_notifier.dart';
import 'package:focus_app/features/social/notifiers/social_state.dart';

final socialNotifierProvider = ChangeNotifierProvider<SocialNotifier>(
  (_) => SocialNotifier(),
);

final socialStateProvider = Provider<SocialState>(
  (ref) => ref.watch(socialNotifierProvider).state,
);