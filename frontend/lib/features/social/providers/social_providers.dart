import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/social/notifiers/social_notifier.dart';
import 'package:focus_app/features/social/notifiers/social_state.dart';

final socialNotifierProvider = ChangeNotifierProvider<SocialNotifier>(
  (_) => SocialNotifier(),
);

final socialStateProvider = Provider<SocialState>(
  (ref) => ref.watch(socialNotifierProvider).state,
);

/// Sosyal ekranındaki aktif sekme: 0 = Arkadaşlar, 1 = Çalışma Odaları
final socialTabIndexProvider = StateProvider<int>((ref) => 0);