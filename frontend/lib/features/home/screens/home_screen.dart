import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/home/widgets/daily_progress_card.dart';
import 'package:focus_app/features/home/widgets/home_app_bar.dart';
import 'package:focus_app/features/home/widgets/quick_start_card.dart';
import 'package:focus_app/features/home/widgets/today_plan_card.dart';
import 'package:focus_app/features/home/widgets/priority_suggestion_card.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/stats/providers/stats_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const double _horizontalPadding = 16;
  static const double _cardSpacing = 16;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(pomodoroNotifierProvider).checkOngoing();
      await ref.read(statsNotifierProvider).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: HomeAppBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                8,
                _horizontalPadding,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DailyProgressCard(),
                  const SizedBox(height: _cardSpacing),
                  QuickStartCard(),
                  const SizedBox(height: _cardSpacing),
                  TodayPlanCard(),
                  const SizedBox(height: _cardSpacing),
                  PrioritySuggestionCard(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
