import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/notifications/local_notification_service.dart';
import 'app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final localNotificationService = LocalNotificationService();
  await localNotificationService.initialize();
  await localNotificationService.requestPermission();

  runApp(
    ProviderScope(
      overrides: [
        localNotificationServiceProvider.overrideWithValue(
          localNotificationService,
        ),
      ],
      child: const FocusApp(),
    ),
  );
}

class FocusApp extends ConsumerWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Fokus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}