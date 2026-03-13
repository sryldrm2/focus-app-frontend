import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focus_app/features/auth/screens/splash_screen.dart';
import 'package:focus_app/features/auth/screens/login_screen.dart';
import 'package:focus_app/features/auth/screens/register_screen.dart';
import 'package:focus_app/features/auth/screens/forgot_password_screen.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/auth/notifiers/auth_state.dart';
import 'package:focus_app/features/home/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/splash', 
    refreshListenable: authNotifier,
    redirect: (context, state) {
    
      final status = authNotifier.state.status;
      final loc = state.matchedLocation;

      // 1. Henüz kontrol aşamasındaysak Splash'te kal
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return loc == '/splash' ? null : '/splash';
      }

      final authed = status == AuthStatus.authenticated;

      // 2. Splash ekranındaysak ve kontrol bittiyse (auth durumuna göre yönlendir)
      if (loc == '/splash') {
        return authed ? '/home' : '/auth/login';
      }

      // 3. Giriş yapmamış kullanıcıyı korumalı sayfalardan Login'e at
      final isAuthRoute = loc.startsWith('/auth');
      if (!authed && !isAuthRoute) {
        return '/auth/login';
      }

      // 4. Giriş yapmış kullanıcıyı Login/Register sayfalarından Home'a at
      if (authed && isAuthRoute) {
        return '/home';
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

      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/pomodoro',
            builder: (_, __) => const Text("yakında"),
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const Text("yakında"),
          ),
          GoRoute(
            path: '/social',
            builder: (_, __) => const Text("yakında"),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Text("yakında"),
          ),
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