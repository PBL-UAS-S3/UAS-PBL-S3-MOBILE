import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';

class VerifikasiEmailPage extends StatefulWidget {
  final String email;

  // true kalau dibuka dari login (akun belum verifikasi),
  // jadi kode baru langsung dikirim saat halaman terbuka
  final bool kirimOtomatis;

  const VerifikasiEmailPage({
    super.key,
    required this.email,
    this.kirimOtomatis = false,
  });

  @override
  State<VerifikasiEmailPage> createState() => _VerifikasiEmailPageState();
}

class _VerifikasiEmailPageState extends State<VerifikasiEmailPage> {
  final kodeController = TextEditingController();
  Timer? _timer;

  bool loading = false;
  bool mengirimUlang = false;
  String pesanError = '';
  String pesanInfo = '';
  int sisaDetik = 0;

  @override
  void initState() {
    super.initState();
    if (widget.kirimOtomatis) {
      kirimUlang();
    } else {
      _mulaiHitungMundur(60);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    kodeController.dispose();
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

  Future<void> verifikasi() async {
    final kode = kodeController.text.trim();
    if (kode.length != 6) {
      setState(() {
        pesanError = 'Masukkan 6 digit kode verifikasi';
        pesanInfo = '';
      });
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await kirimJson('/auth/verifikasi-email', {
      'email': widget.email,
      'kode': kode,
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

  Future<void> kirimUlang() async {
    setState(() {
      mengirimUlang = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await kirimJson('/auth/kirim-ulang-kode', {
      'email': widget.email,
    });

    if (!mounted) return;

    if (hasil.status == 200) {
      setState(() {
        mengirimUlang = false;
        pesanInfo = 'Kode baru sudah dikirim ke ${widget.email}';
      });
      _mulaiHitungMundur(60);
    } else {
      setState(() {
        mengirimUlang = false;
        pesanError = hasil.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      judul: 'Verifikasi email',
      subjudul: 'Kami mengirim kode 6 digit ke ${widget.email}. Kode berlaku 10 menit.',
      ikon: Icons.mark_email_read_outlined,
      children: [
        if (pesanError.isNotEmpty) AuthAlert(teks: pesanError),
        if (pesanInfo.isNotEmpty) AuthAlert(teks: pesanInfo, sukses: true),
        AuthField(
          controller: kodeController,
          label: 'Kode verifikasi',
          hint: '000000',
          kodeOtp: true,
          onSubmitted: (_) => verifikasi(),
        ),
        const SizedBox(height: 22),
        AuthButton(label: 'Verifikasi', onPressed: verifikasi, loading: loading),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: (sisaDetik > 0 || mengirimUlang) ? null : kirimUlang,
            child: Text(
              mengirimUlang
                  ? 'Mengirim...'
                  : sisaDetik > 0
                      ? 'Kirim ulang kode ($sisaDetik detik)'
                      : 'Kirim ulang kode',
              style: TextStyle(
                color: (sisaDetik > 0 || mengirimUlang)
                    ? AppColors.textGrey
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}