import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';
import 'package:focus_app/shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(authNotifierProvider)
        .register(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        );
    if (!mounted) return;
    if (!success) {
      setState(() => _isSubmitting = false);
      final error = ref.read(authNotifierProvider).state.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Kayıt başarısız.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authLoading = ref.watch(authNotifierProvider).state.isLoading;
    final isBusy = _isSubmitting || authLoading;

    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.primary, toolbarHeight: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Focus",
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                "Hesap Oluştur",
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                "Odaklanma yolculuğuna başla",
                style: GoogleFonts.dmSans(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _nameController,
                      hint: "Adınız",
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Ad girin' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _surnameController,
                      hint: "Soyadınız",
                      icon: Icons.person_outline,
                      validator: (v) => v!.isEmpty ? 'Soyad girin' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: _nicknameController,
                hint: "Kullanıcı adı",
                icon: Icons.alternate_email,
                validator: (v) => v!.isEmpty ? 'Kullanıcı adı girin' : null,
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: _emailController,
                hint: "E-posta adresi",
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (!v!.contains('@')) ? 'Geçerli e-posta girin' : null,
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: _passwordController,
                hint: "Şifre",
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => v!.length < 6 ? 'En az 6 karakter' : null,
              ),

              const SizedBox(height: 14),

              AppTextField(
                controller: _confirmController,
                hint: "Şifre tekrar",
                icon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) => v != _passwordController.text
                    ? 'Şifreler eşleşmiyor'
                    : null,
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isBusy ? null : _onRegister,
                  child: isBusy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSocialDivider(colorScheme),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      label: "Google",
                      icon: Icons.g_mobiledata,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(
                      label: "Apple",
                      icon: Icons.apple,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider(ColorScheme colorScheme) => Row(
    children: [
      Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.35))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "VEYA ŞUNUNLA DEVAM ET",
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
      ),
      Expanded(child: Divider(color: colorScheme.outline.withOpacity(0.35))),
    ],
  );

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required ColorScheme colorScheme,
  }) =>
      OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: colorScheme.onSurface),
        label: Text(label, style: TextStyle(color: colorScheme.onSurface)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
