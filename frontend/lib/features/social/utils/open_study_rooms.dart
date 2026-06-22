import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/features/social/providers/social_providers.dart';
import 'package:go_router/go_router.dart';

/// Çalışma Odaları sekmesi ile Sosyal ekranına gider.
void openStudyRooms(BuildContext context, WidgetRef ref) {
  ref.read(socialTabIndexProvider.notifier).state = 1;
  context.go('/social');
}
