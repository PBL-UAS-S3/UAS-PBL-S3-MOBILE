import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';

const int _minPassword = 8;

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController emailController;
  final kodeController = TextEditingController();
  final passwordController = TextEditingController();
  final konfirmasiController = TextEditingController();
  Timer? _timer;

  int langkah = 1; // 1 = isi email, 2 = isi kode + password baru
  bool loading = false;
  String pesanError = '';
  String pesanInfo = '';
  int sisaDetik = 0;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _timer?.cancel();
    emailController.dispose();
    kodeController.dispose();
    passwordController.dispose();
    konfirmasiController.dispose();
    super.dispose();
  }

  void _mulaiHitungMundur(int detik) {
    _timer?.cancel();
    setState(() => sisaDetik = detik);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (sisaDetik <= 1) {
        t.cancel();
        setState(() => sisaDetik = 0);
      } else {
        setState(() => sisaDetik--);
      }
    });
  }

  bool get _emailValid => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$')
      .hasMatch(emailController.text.trim());

  // Langkah 1: minta kode OTP ke email
  Future<void> kirimKode({bool ulang = false}) async {
    if (!_emailValid) {
      setState(() {
        pesanError = 'Masukkan alamat email yang valid';
        pesanInfo = '';
      });
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await kirimJson('/auth/lupa-password', {
      'email': emailController.text.trim(),
    });

    if (!mounted) return;

    if (hasil.status == 200) {
      setState(() {
        loading = false;
        langkah = 2;
        pesanInfo = ulang
            ? 'Kode baru sudah dikirim.'
            : 'Jika email terdaftar, kode 6 digit sudah dikirim ke ${emailController.text.trim()}.';
      });
      _mulaiHitungMundur(60);
    } else {
      setState(() {
        loading = false;
        pesanError = hasil.error;
      });
    }
  }

  // Langkah 2: cek kode OTP lalu ganti password
  Future<void> resetPassword() async {
    final kode = kodeController.text.trim();

    if (kode.length != 6) {
      setState(() {
        pesanError = 'Masukkan 6 digit kode dari email';
        pesanInfo = '';
      });
      return;
    }
    if (passwordController.text.length < _minPassword) {
      setState(() {
        pesanError = 'Password baru minimal $_minPassword karakter';
        pesanInfo = '';
      });
      return;
    }
    if (passwordController.text != konfirmasiController.text) {
      setState(() {
        pesanError = 'Konfirmasi password tidak sama';
        pesanInfo = '';
      });
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await kirimJson('/auth/reset-password', {
      'email': emailController.text.trim(),
      'kode': kode,
      'password_baru': passwordController.text,
    });

    if (!mounted) return;

    if (hasil.status == 200) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      loading = false;
      pesanError = hasil.error;
    });
  }

  void _gantiEmail() {
    _timer?.cancel();
    setState(() {
      langkah = 1;
      sisaDetik = 0;
      pesanError = '';
      pesanInfo = '';
      kodeController.clear();
      passwordController.clear();
      konfirmasiController.clear();
    });
  }

  List<Widget> _isiLangkah1() {
    return [
      AuthField(
        controller: emailController,
        label: 'Email akun',
        hint: 'nama@email.com',
        icon: Icons.mail_outline_rounded,
        keyboardType: TextInputType.emailAddress,
        onSubmitted: (_) => kirimKode(),
      ),
      const SizedBox(height: 22),
      AuthButton(
        label: 'Kirim kode',
        onPressed: kirimKode,
        loading: loading,
      ),
      const SizedBox(height: 18),
      Center(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Kembali ke halaman masuk',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _isiLangkah2() {
    return [
      AuthField(
        controller: kodeController,
        label: 'Kode dari email',
        hint: '000000',
        kodeOtp: true,
      ),
      const SizedBox(height: 18),
      AuthField(
        controller: passwordController,
        label: 'Password baru',
        hint: 'Minimal $_minPassword karakter',
        icon: Icons.lock_outline_rounded,
        isPassword: true,
      ),
      const SizedBox(height: 18),
      AuthField(
        controller: konfirmasiController,
        label: 'Ulangi password baru',
        hint: 'Ketik ulang password',
        icon: Icons.lock_reset_rounded,
        isPassword: true,
        onSubmitted: (_) => resetPassword(),
      ),
      const SizedBox(height: 22),
      AuthButton(
        label: 'Ubah password',
        onPressed: resetPassword,
        loading: loading,
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: loading ? null : _gantiEmail,
            child: Text(
              'Ganti email',
              style: TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: (sisaDetik > 0 || loading)
                ? null
                : () => kirimKode(ulang: true),
            child: Text(
              sisaDetik > 0 ? 'Kirim ulang ($sisaDetik)' : 'Kirim ulang kode',
              style: TextStyle(
                color: sisaDetik > 0 ? AppColors.textGrey : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: langkah == 1 ? 'Lupa password' : 'Atur password baru',
      subjudul: langkah == 1
          ? 'Masukkan email akunmu, kami kirim kode verifikasi 6 digit.'
          : 'Masukkan kode dari email, lalu buat password baru.',
      ikon: Icons.lock_reset_rounded,
      children: [
        if (pesanError.isNotEmpty) AuthAlert(teks: pesanError),
        if (pesanInfo.isNotEmpty) AuthAlert(teks: pesanInfo, sukses: true),
        ...(langkah == 1 ? _isiLangkah1() : _isiLangkah2()),
      ],
    );
  }
}