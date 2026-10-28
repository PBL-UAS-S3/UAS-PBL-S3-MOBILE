import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'login_page.dart';
import 'verifikasi_email_page.dart';

const int _minPassword = 8;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final teleponController = TextEditingController();
  final passwordController = TextEditingController();

  String pesanError = '';
  bool loading = false;

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    teleponController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Kembali ke halaman masuk, sisakan hanya halaman paling bawah (tampilan awal)
  void _keLogin({String info = ''}) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(infoAwal: info)),
      (route) => route.isFirst,
    );
  }

  Future<void> register() async {
    final nama = namaController.text.trim();
    final email = emailController.text.trim();

    if (nama.isEmpty || email.isEmpty || passwordController.text.isEmpty) {
      setState(() => pesanError = 'Nama, email, dan password wajib diisi');
      return;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(email)) {
      setState(() => pesanError = 'Format email tidak valid');
      return;
    }
    if (passwordController.text.length < _minPassword) {
      setState(() => pesanError = 'Password minimal $_minPassword karakter');
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
    });

    final hasil = await kirimJson('/auth/register-staff', {
      'nama': nama,
      'email': email,
      'password': passwordController.text,
      'telepon': teleponController.text.trim(),
    });

    if (!mounted) return;
    setState(() => loading = false);

    if (hasil.status != 201) {
      setState(() => pesanError = hasil.error);
      return;
    }

    // Akun dibuat, kode OTP sudah dikirim ke email
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => VerifikasiEmailPage(
          email: (hasil.data['email'] ?? email.toLowerCase()).toString(),
        ),
      ),
    );

    if (berhasil == true && mounted) {
      _keLogin(info: 'Akun siap dipakai. Silakan masuk.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: 'Buat akun',
      subjudul: 'Daftar sebagai staf, lalu gabung ke gudang setelah masuk.',
      tombolServer: true,
      children: [
        if (pesanError.isNotEmpty) AuthAlert(teks: pesanError),
        AuthField(
          controller: namaController,
          label: 'Nama lengkap',
          hint: 'Nama kamu',
          icon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 18),
        AuthField(
          controller: emailController,
          label: 'Email',
          hint: 'nama@email.com',
          helper: 'Gunakan email aktif, kode verifikasi akan dikirim ke sini.',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        AuthField(
          controller: teleponController,
          label: 'Nomor telepon (opsional)',
          hint: '08xx-xxxx-xxxx',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 18),
        AuthField(
          controller: passwordController,
          label: 'Password',
          hint: 'Minimal $_minPassword karakter',
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          onSubmitted: (_) => register(),
        ),
        const SizedBox(height: 14),
        const Text(
          'Setelah masuk, kamu bisa bergabung ke gudang lewat kode dari Manager. Manager akan menyetujui permintaanmu.',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4),
        ),
        const SizedBox(height: 22),
        AuthButton(label: 'Daftar', onPressed: register, loading: loading),
        const SizedBox(height: 24),
        AuthTautan(
          teks: 'Sudah punya akun?',
          aksi: 'Masuk',
          onTap: () => _keLogin(),
        ),
      ],
    );
  }
}