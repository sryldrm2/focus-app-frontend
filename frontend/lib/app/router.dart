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
import 'package:focus_app/features/social/screens/social_screen.dart';

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
      ];

      if (loc == '/splash') {
        if (auth.status == AuthStatus.initial ||
            auth.status == AuthStatus.loading) {
          return null;
        }
        if (auth.status == AuthStatus.authenticated) return '/home';
        if (auth.status == AuthStatus.unauthenticated) return '/auth/login';
      }

      if (loc.startsWith('/auth/login') || loc.startsWith('/auth/register')) {
        if (auth.status == AuthStatus.authenticated) return '/home';
      }

      if (loc.startsWith('/auth/forgot')) {
        if (auth.status == AuthStatus.authenticated) return '/home';
        return null;
      }

      if (shellPrefixes.any((p) => loc.startsWith(p))) {
        if (auth.status == AuthStatus.authenticated) return null;
        if (auth.status == AuthStatus.unauthenticated) return '/auth/login';
        return null;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (_, __) => const TasksScreen(),
      ),

      // StatefulShellRoute — sekmeler arası geçişte widget dispose olmaz
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pomodoro',
                builder: (context, state) => PomodoroScreen(
                  initialTaskId: state.extra as String?,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (_, __) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/social',
                builder: (_, __) => const SocialScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE5D5),
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