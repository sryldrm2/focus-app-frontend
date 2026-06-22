import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:focus_app/features/social/widgets/friends_tab.dart';
import 'package:focus_app/features/social/widgets/study_rooms_tab.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(socialTabIndexProvider).clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab,
    );
    _tabController.addListener(_syncTabToProvider);
  }

  void _syncTabToProvider() {
    if (_tabController.indexIsChanging) return;
    final current = ref.read(socialTabIndexProvider);
    if (current != _tabController.index) {
      ref.read(socialTabIndexProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_syncTabToProvider);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    ref.listen<int>(socialTabIndexProvider, (previous, next) {
      final target = next.clamp(0, 1);
      if (_tabController.index != target) {
        _tabController.animateTo(target);
      }
    });

    final nickname = ref.watch(authNotifierProvider).state.user?.nickname ?? '';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ───────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sosyal',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arkadaşlarınla birlikte çalış',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (nickname.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kullanıcı adın',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  nickname,
                                  style: GoogleFonts.dmMono(
                                    fontSize: 12,
                                    color: colorScheme.onSurface,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Arkadaş eklerken bunu paylaş.',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Kopyala',
                            onPressed: () async {
                              final toCopy = nickname.startsWith('@')
                                  ? nickname
                                  : '@$nickname';
                              await Clipboard.setData(
                                ClipboardData(text: toCopy),
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Kullanıcı adı kopyalandı',
                                    style: GoogleFonts.dmSans(fontSize: 14),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Kullanıcı adın için giriş yap.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab Bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: colorScheme.onPrimary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: '👥 Arkadaşlar'),
                    Tab(text: '🏠 Çalışma Odaları'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab Views ────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [FriendsTab(), StudyRoomsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
