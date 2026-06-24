import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/profile/screens/profile_screen.dart';
import 'package:focus_app/features/tasks/screens/tasks_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_app/features/auth/screens/splash_screen.dart';
import 'package:focus_app/features/auth/screens/login_screen.dart';
import 'package:focus_app/features/auth/screens/register_screen.dart';
import 'package:focus_app/features/auth/screens/forgot_password_screen.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/auth/notifiers/auth_state.dart';
import 'package:focus_app/features/home/screens/home_screen.dart';
import 'package:focus_app/features/pomodoro/screens/pomodoro_screen.dart';
import 'package:focus_app/features/stats/screens/stats_screen.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:focus_app/features/social/screens/social_screen.dart';
import 'package:focus_app/features/notifications/screens/notifications_screen.dart';
import 'package:focus_app/features/notifications/network/notification_hub_service.dart';
import 'package:focus_app/features/notifications/providers/notification_provider.dart';
import 'package:focus_app/core/notifications/local_notification_service.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/social/utils/workspace_realtime_sync.dart';
import 'package:focus_app/features/notifications/models/notification_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);
  final authState = ref.watch(authNotifierProvider.select((n) => n.state));

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,

    redirect: (context, state) {
      final auth = authState;
      final loc = state.matchedLocation;

      const shellPrefixes = [
        '/home',
        '/pomodoro',
        '/stats',
        '/social',
        '/profile',
        '/tasks',
        '/notifications',
      ];

      // Splash: checkAuth bitene kadar bekle; sonra home veya login
      if (loc == '/splash') {
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return null;
        }
        if (auth.status == AuthStatus.authenticated) {
          return '/home';
        }
        if (auth.status == AuthStatus.unauthenticated) {
          return '/auth/login';
        }
      }

      // Giriş yapmışken login/register'a düşmesin
      if (loc.startsWith('/auth/login') || loc.startsWith('/auth/register')) {
        if (auth.status == AuthStatus.authenticated) {
          return '/home';
        }
      }

      if (loc.startsWith('/auth/forgot')) {
        if (auth.status == AuthStatus.authenticated) {
          return '/home';
        }
        return null;
      }

      // Shell: sadece oturum açıkken; aksi halde login veya splash
      if (shellPrefixes.any((p) => loc.startsWith(p))) {
        if (auth.status == AuthStatus.authenticated) {
          return null;
        }
        if (auth.status == AuthStatus.unauthenticated) {
          return '/auth/login';
        }
        return '/splash';
      }

      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Uygulamanın ana iskeletini (BottomNavigationBar) oluşturan ShellRoute
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/pomodoro',
            builder: (context, state) =>
                PomodoroScreen(initialTaskId: state.extra as String?),
          ),
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/social', builder: (_, __) => const SocialScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
        ],
      ),
    ],
  );
});

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = ['/home', '/pomodoro', '/stats', '/social', '/profile'];

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  Timer? _invitationPollTimer;
  NotificationHubService? _hubService;

  Future<void> _pollWorkspaceInvitations() async {
    if (!mounted) return;

    final newInvites =
        await ref.read(workspaceNotifierProvider).pollPendingInvitations();

    if (!mounted) return;

    for (final inv in newInvites) {
      final notification = NotificationModel.fromWorkspaceInvitation(inv);
      ref
          .read(notificationNotifierProvider)
          .addRealtimeNotification(notification);

      if (!mounted) return;

      if (ref.read(notificationSettingsProvider).localNotificationsEnabled) {
        ref
            .read(localNotificationServiceProvider)
            .showNotification(notification);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _hubService = ref.read(notificationHubServiceProvider);

    Future.microtask(() async {
      if (!mounted) return;

      final settings = ref.read(notificationSettingsProvider);
      await settings.load();

      if (!mounted) return;

      ref
          .read(localNotificationServiceProvider)
          .setLocalNotificationsEnabled(settings.localNotificationsEnabled);

      await _hubService!.connect(
            onReceive: (notification) {
              if (!mounted) return;
              ref
                  .read(notificationNotifierProvider)
                  .addRealtimeNotification(notification);

              if (ref
                  .read(notificationSettingsProvider)
                  .localNotificationsEnabled) {
                ref
                    .read(localNotificationServiceProvider)
                    .showNotification(notification);
              }
            },
            onWorkspaceTaskCreated: (task) {
              if (!mounted) return;
              dispatchWorkspaceTaskCreated(ref, task);
            },
            onWorkspacePomodoroStarted: (session) {
              if (!mounted) return;
              debugPrint(
                '[WorkspaceSync] Router callback received WorkspacePomodoroStarted '
                'pomoId=${session.pomoId} taskId=${session.taskId}',
              );
              dispatchWorkspacePomodoroStarted(ref, session);
            },
            onWorkspacePomodoroPaused: (event) {
              if (!mounted) return;
              dispatchWorkspacePomodoroPaused(ref, event);
            },
            onWorkspacePomodoroResumed: (event) {
              if (!mounted) return;
              dispatchWorkspacePomodoroResumed(ref, event);
            },
            onWorkspacePomodoroCancelled: (event) {
              if (!mounted) return;
              dispatchWorkspacePomodoroCancelled(ref, event);
            },
          );

      if (!mounted) return;

      await _pollWorkspaceInvitations();

      if (!mounted) return;

      _invitationPollTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {
          if (!mounted) return;
          _pollWorkspaceInvitations();
        },
      );
    });
  }

  @override
  void dispose() {
    _invitationPollTimer?.cancel();
    _invitationPollTimer = null;

    // dispose içinde ref kullanılmaz; hub servisi initState'te alınmıştı.
    final hub = _hubService;
    _hubService = null;
    if (hub != null) {
      unawaited(hub.disconnect());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = MainShell._tabs
        .indexWhere((t) => location.startsWith(t))
        .clamp(0, 4);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          final dest = MainShell._tabs[i];
          if (dest == '/social') {
            ref.read(socialTabIndexProvider.notifier).state = 0;
          }
          context.go(dest);
        },
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFE85D04)),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer, color: Color(0xFFE85D04)),
            label: 'Pomodoro',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFFE85D04)),
            label: 'İstatistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: Color(0xFFE85D04)),
            label: 'Sosyal',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFE85D04)),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
