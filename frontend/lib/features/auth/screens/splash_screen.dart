import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) ref.read(authNotifierProvider).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍅', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              'Fokus',
              style: GoogleFonts.nunito(
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Odaklan. Geliş. Kazan.',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 64),
            CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}