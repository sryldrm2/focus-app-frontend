import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_providers.dart';

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
    if (!success && mounted) {
      final error = ref.read(authNotifierProvider).state.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Kayıt başarısız.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).state.isLoading;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(backgroundColor: AppColors.primary, toolbarHeight: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                    "Fokus",
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Hesap Oluştur",
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Odaklanma yolculuğuna başla",
                style: GoogleFonts.dmSans(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _buildInputLabel("Ad"),
              _buildTextField(
                controller: _nameController,
                hint: "Adınızı girin",
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Ad girin' : null,
              ),
              const SizedBox(height: 16),
              _buildInputLabel("Soyad"),
              _buildTextField(
                controller: _surnameController,
                hint: "Soyadınızı girin",
                icon: Icons.person_outline,
                validator: (v) => v!.isEmpty ? 'Soyad girin' : null,
              ),
              const SizedBox(height: 16),
              _buildInputLabel("Kullanıcı Adı"),
              _buildTextField(
                controller: _nicknameController,
                hint: "kullaniciadi",
                icon: Icons.alternate_email,
                validator: (v) => v!.isEmpty ? 'Kullanıcı adı girin' : null,
              ),
              const SizedBox(height: 16),
              _buildInputLabel("E-posta"),
              _buildTextField(
                controller: _emailController,
                hint: "ornek@mail.com",
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    (!v!.contains('@')) ? 'Geçerli e-posta girin' : null,
              ),
              const SizedBox(height: 16),
              _buildInputLabel("Şifre"),
              _buildTextField(
                controller: _passwordController,
                hint: "••••••••",
                icon: Icons.lock_outline,
                isPassword: true,
                obscureToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                obscure: _obscurePassword,
                validator: (v) => v!.length < 6 ? 'En az 6 karakter' : null,
              ),
              const SizedBox(height: 16),
              _buildInputLabel("Şifre Tekrar"),
              _buildTextField(
                controller: _confirmController,
                hint: "••••••••",
                icon: Icons.lock_outline,
                isPassword: true,
                obscureToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                obscure: _obscureConfirm,
                validator: (v) => v != _passwordController.text
                    ? 'Şifreler eşleşmiyor'
                    : null,
              ),
              const SizedBox(height: 32),
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
                  onPressed: isLoading ? null : _onRegister,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Kayıt Ol",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSocialDivider(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSocialButton(
                      label: "Google",
                      icon: Icons.g_mobiledata,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSocialButton(
                      label: "Apple",
                      icon: Icons.apple,
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

  Widget _buildInputLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? obscureToggle,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: isPassword && obscureToggle != null
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  onPressed: obscureToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSocialDivider() => const Row(
    children: [
      Expanded(child: Divider()),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "VEYA ŞUNUNLA DEVAM ET",
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ),
      Expanded(child: Divider()),
    ],
  );

  Widget _buildSocialButton({required String label, required IconData icon}) =>
      OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: Colors.black),
        label: Text(label, style: const TextStyle(color: Colors.black)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}
