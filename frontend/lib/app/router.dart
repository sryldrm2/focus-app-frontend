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
        '/tasks',
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

      // Uygulamanın ana iskeletini (BottomNavigationBar) oluşturan ShellRoute
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/pomodoro',
            builder: (context, state) => PomodoroScreen(
              initialTaskId: state.extra as String?,
            ),
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsScreen(),
          ),
          GoRoute(
            path: '/social',
            builder: (_, __) => const SocialScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/tasks', builder: (_, __) => const TasksScreen()
          )
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    '/home',
    '/pomodoro',
    '/stats',
    '/social',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _tabs.indexWhere(
          (t) => location.startsWith(t),
    ).clamp(0, 4);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i]),
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