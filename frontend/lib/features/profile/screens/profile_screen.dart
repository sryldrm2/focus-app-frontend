import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_app/core/theme/app_colors.dart';
import 'package:focus_app/features/auth/providers/auth_providers.dart';
import 'package:focus_app/features/profile/providers/profile_providers.dart';
import 'package:focus_app/features/profile/widgets/profile_header.dart';
import 'package:focus_app/features/profile/widgets/settings_section.dart';
import 'package:focus_app/features/profile/widgets/logout_button.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authNotifierProvider).state.user?.userId ?? '';
      if (userId.isEmpty) return;
      ref.read(profileNotifierProvider).load(userId);
    });
  }

  void _showEditSheet({
    required String userId,
    required String name,
    required String surname,
    required String nickname,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        userId: userId,
        initialName: name,
        initialSurname: surname,
        initialNickname: nickname,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider).state;
    final userId = auth.user?.userId ?? '';
    final profile = ref.watch(profileStateProvider);

    if (userId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Text(
            'Profil için giriş yapmalısın',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final user = profile.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: RefreshIndicator(
        onRefresh: () => ref.read(profileNotifierProvider).load(userId),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: user == null
                  ? _LoadingHeader(message: profile.errorMessage)
                  : ProfileHeader(
                      user: user,
                      friendCount: profile.friendCount,
                      onEditTap: () => _showEditSheet(
                        userId: user.userId,
                        name: user.name,
                        surname: user.surname,
                        nickname: user.nickname,
                      ),
                    ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (profile.errorMessage != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        profile.errorMessage!,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SettingsSection(),
                  const SizedBox(height: 16),
                  const LogoutButton(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _LoadingHeader extends StatelessWidget {
  final String? message;
  const _LoadingHeader({this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Text(
            'Profil',
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: Colors.white),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
class _EditProfileSheet extends ConsumerStatefulWidget {
  final String userId;
  final String initialName;
  final String initialSurname;
  final String initialNickname;
  const _EditProfileSheet({
    required this.userId,
    required this.initialName,
    required this.initialSurname,
    required this.initialNickname,
  });
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}
class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _surname;
  late final TextEditingController _nickname;
  bool _isLoading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _surname = TextEditingController(text: widget.initialSurname);
    _nickname = TextEditingController(text: widget.initialNickname);
  }
  @override
  void dispose() {
    _name.dispose();
    _surname.dispose();
    _nickname.dispose();
    super.dispose();
  }
  Future<void> _save() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(profileNotifierProvider).updateProfile(
            widget.userId,
            name: _name.text.trim(),
            surname: _surname.text.trim(),
            nickname: _nickname.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Profili Düzenle',
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Ad', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _Field(controller: _name),
            const SizedBox(height: 12),
            Text('Soyad', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _Field(controller: _surname),
            const SizedBox(height: 12),
            Text('Kullanıcı adı', style: GoogleFonts.nunito(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _Field(controller: _nickname),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: GoogleFonts.dmSans(color: AppColors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Kaydet',
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _Field extends StatelessWidget {
  final TextEditingController controller;
  const _Field({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.dmSans(fontSize: 15),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}