import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(backgroundColor: AppColors.primary, toolbarHeight: 4),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.timer, color: AppColors.primary, size: 32),
                ),
                const SizedBox(width: 8),
                Text("Fokus", style: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 24),
            Text("Hesap Oluştur", style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("Odaklanma yolculuğuna başla", style: GoogleFonts.dmSans(color: Colors.grey)),
            const SizedBox(height: 32),
            _buildInputLabel("Ad Soyad"),
            _buildTextField(hint: "Adınızı soyadınızı girin", icon: Icons.person_outline),
            const SizedBox(height: 16),
            _buildInputLabel("Kullanıcı Adı"),
            _buildTextField(hint: "kullaniciadi", icon: Icons.alternate_email),
            const SizedBox(height: 16),
            _buildInputLabel("E-posta"),
            _buildTextField(hint: "ornek@mail.com", icon: Icons.mail_outline),
            const SizedBox(height: 16),
            _buildInputLabel("Şifre"),
            _buildTextField(hint: "••••••••", icon: Icons.lock_outline, isPassword: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {},
                child: const Text("Kayıt Ol", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            _buildSocialDivider(),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildSocialButton(label: "Google", icon: Icons.g_mobiledata)),
                const SizedBox(width: 16),
                Expanded(child: _buildSocialButton(label: "Apple", icon: Icons.apple)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
  );

  Widget _buildTextField({required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSocialDivider() => const Row(
    children: [
      Expanded(child: Divider()),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("VEYA ŞUNUNLA DEVAM ET", style: TextStyle(fontSize: 10, color: Colors.grey))),
      Expanded(child: Divider()),
    ],
  );

  Widget _buildSocialButton({required String label, required IconData icon}) => OutlinedButton.icon(
    onPressed: () {},
    icon: Icon(icon, color: Colors.black),
    label: Text(label, style: const TextStyle(color: Colors.black)),
    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );
}