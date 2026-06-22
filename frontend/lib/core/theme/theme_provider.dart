import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/theme_mode_notifier.dart';

final themeModeNotifierProvider =
    ChangeNotifierProvider<ThemeModeNotifier>((ref) {
  final notifier = ThemeModeNotifier();
  notifier.load();
  return notifier;
});

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeModeNotifierProvider).themeMode,
);

final isDarkModeProvider = Provider<bool>(
  (ref) => ref.watch(themeModeNotifierProvider).isDarkMode,
);
