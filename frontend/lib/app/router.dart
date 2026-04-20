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
import 'package:focus_app/features/pomodoro/screens/pomodoro_screen.dart';
import 'package:focus_app/features/stats/screens/stats_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authNotifierProvider);

  return GoRouter(
    // Geliştirme sürecinde kolaylık olması için başlangıç ekranı Pomodoro olarak ayarlandı.
    // TODO: Arayüz geliştirme aşaması bittiğinde '/splash' olarak geri güncellenmelidir.
    initialLocation: '/pomodoro',
    refreshListenable: authNotifier,

    // Uygulama içi sayfa yönlendirme mantığı (Auth kontrolü)
    // TODO: Backend entegrasyonu başladığında aşağıdaki yönlendirme mantığı tekrar aktif edilmelidir.
    redirect: (context, state) {
      // Geliştirme aşamasında tüm sayfaları görebilmek için yönlendirme geçici olarak devre dışı bırakıldı.
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
            builder: (_, __) => const PomodoroScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (_, __) => const StatsScreen(),
          ),
          GoRoute(
            path: '/social',
            builder: (_, __) => const Text("Sosyal sayfa hazırlık aşamasında"),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Text("Profil sayfa hazırlık aşamasında"),
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