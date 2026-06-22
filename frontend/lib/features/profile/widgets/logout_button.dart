import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/notifications/network/notification_hub_service.dart';
import 'package:focus_app/core/notifications/local_notification_service.dart';
import 'package:focus_app/features/pomodoro/providers/pomodoro_provider.dart';
import 'package:focus_app/features/profile/providers/profile_providers.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:focus_app/features/social/providers/workspace_provider.dart';
import 'package:focus_app/features/notifications/providers/notification_provider.dart';
import 'package:focus_app/features/stats/providers/stats_provider.dart';
import 'package:focus_app/features/tasks/providers/task_provider.dart';

class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            final dialogScheme = Theme.of(dialogContext).colorScheme;
            return Dialog(
            backgroundColor: dialogScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Çıkış Yap',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: dialogScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hesabından çıkış yapmak istediğine emin misin?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      height: 1.5,
                      color: dialogScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: dialogScheme.outline.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Vazgeç',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w700,
                              color: dialogScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);

                            // SignalR bağlantısını kapat ve real-time notifier'ı sıfırla.
                            await ref.read(notificationHubServiceProvider).disconnect();
                            ref.read(localNotificationServiceProvider).resetSession();

                            ref.invalidate(taskNotifierProvider);
                            ref.invalidate(pomodoroNotifierProvider);
                            ref.invalidate(statsNotifierProvider);
                            ref.invalidate(socialNotifierProvider);
                            ref.invalidate(workspaceNotifierProvider);
                            ref.invalidate(workspaceTaskNotifierProvider);
                            ref.invalidate(profileNotifierProvider);
                            ref.invalidate(notificationNotifierProvider);

                            await ref.read(authNotifierProvider).logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Çıkış Yap',
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Çıkış Yap',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
