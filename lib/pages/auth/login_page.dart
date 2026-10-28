import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/gudang_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../gudang/gudang_saya_page.dart';
import '../main_shell.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';
import 'verifikasi_email_page.dart';

class LoginPage extends StatefulWidget {
  // Pesan hijau di atas form (misalnya setelah daftar berhasil)
  final String infoAwal;

  const LoginPage({super.key, this.infoAwal = ''});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FocusNode passwordFocus = FocusNode();

  String pesanError = '';
  String pesanInfo = '';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    pesanInfo = widget.infoAwal;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();

    if (email.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        pesanError = 'Email dan password wajib diisi';
        pesanInfo = '';
      });
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await kirimJson('/auth/login', {
      'email': email,
      'password': passwordController.text,
    });

    if (!mounted) return;

    // Login berhasil
    if (hasil.status == 200) {
      if (hasil.data['role'] != 'staff') {
        setState(() {
          pesanError =
              'Aplikasi mobile ini khusus untuk akun Staf. Gunakan web dashboard untuk akun Manager.';
          loading = false;
        });
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', hasil.data['token']);
      await prefs.setString('role', hasil.data['role']);
      await prefs.setString('nama', hasil.data['nama']);
      if (hasil.data['gudang_id'] != null) {
        await prefs.setString('gudang_id', hasil.data['gudang_id'].toString());
      } else {
        await prefs.remove('gudang_id');
      }

      // Staf yang belum aktif di gudang diarahkan ke halaman Gudang Saya dulu
      final status = await GudangService.ambilStatus();
      if (!mounted) return;

      final perluGabung = !status.gagal && !status.aktif;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => perluGabung
              ? const GudangSayaPage(awalLogin: true)
              : const MainShell(),
        ),
        (route) => false,
      );
      return;
    }

    setState(() => loading = false);

    // Email belum diverifikasi: arahkan ke halaman kode OTP
    if (hasil.data['perlu_verifikasi'] == true) {
      final berhasil = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => VerifikasiEmailPage(
            email: (hasil.data['email'] ?? email).toString(),
            kirimOtomatis: true,
          ),
        ),
      );
      if (berhasil == true && mounted) {
        setState(() => pesanInfo = 'Email berhasil diverifikasi, silakan masuk.');
      }
      return;
    }

    setState(() => pesanError = hasil.error);
    Future.delayed(Duration.zero, () => passwordFocus.requestFocus());
  }

  void _keRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  Future<void> _keLupaPassword() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ForgotPasswordPage(initialEmail: emailController.text.trim()),
      ),
    );
    if (berhasil == true && mounted) {
      setState(() {
        pesanError = '';
        pesanInfo = 'Password berhasil diubah. Silakan masuk dengan password baru.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: 'Masuk',
      subjudul: 'Selamat datang kembali. Masuk untuk melanjutkan.',
      tombolServer: true,
      children: [
        if (pesanError.isNotEmpty) AuthAlert(teks: pesanError),
        if (pesanInfo.isNotEmpty) AuthAlert(teks: pesanInfo, sukses: true),
        AuthField(
          controller: emailController,
          label: 'Email',
          hint: 'nama@email.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        AuthField(
          controller: passwordController,
          focusNode: passwordFocus,
          label: 'Password',
          hint: 'Masukkan password',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          onSubmitted: (_) => login(),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _keLupaPassword,
            child: const Text(
              'Lupa password?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AuthButton(label: 'Masuk', onPressed: login, loading: loading),
        const SizedBox(height: 24),
        AuthTautan(
          teks: 'Belum punya akun?',
          aksi: 'Daftar sebagai staf',
          onTap: _keRegister,
        ),
      ],
    );
  }
}