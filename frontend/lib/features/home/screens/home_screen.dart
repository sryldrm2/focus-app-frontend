import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/home/widgets/daily_progress_card.dart';
import 'package:focus_app/features/home/widgets/home_app_bar.dart';
import 'package:focus_app/features/home/widgets/today_plan_card.dart';
import 'package:focus_app/features/home/widgets/upcoming_exams_card.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/features/tasks/providers/task_provider.dart';
import 'package:focus_app/core/theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(taskNotifierProvider).loadTasks();
      await ref.read(pomodoroNotifierProvider).checkOngoing();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  const DailyProgressCard(),
                  const SizedBox(height: 16),
                  const TodayPlanCard(),
                  const SizedBox(height: 16),
                  UpcomingExamsCard(),
                ]),
              ),
            )
          ],
        ),
      ),
    );
  }
}

