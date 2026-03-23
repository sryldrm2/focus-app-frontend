import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/home/widgets/ai_suggestion_card.dart';
import 'package:focus_app/features/home/widgets/daily_progress_card.dart';
import 'package:focus_app/features/home/widgets/home_app_bar.dart';
import 'package:focus_app/features/home/widgets/quick_start_card.dart';
import 'package:focus_app/features/home/widgets/today_plan_card.dart';
import 'package:focus_app/features/home/widgets/upcoming_exams_card.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: HomeAppBar()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 17, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DailyProgressCard(),
                  const SizedBox(height: 16),
                  QuickStartCard(),
                  const SizedBox(height: 16),
                  TodayPlanCard(),
                  const SizedBox(height: 16),
                  UpcomingExamsCard(),
                  const SizedBox(height: 16),
                  AiSuggestionCard(),
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}

