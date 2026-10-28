import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import 'tekan_skala.dart';

/// Hasil panggilan API sederhana
class HasilApi {
  final int status;
  final Map<String, dynamic> data;
  HasilApi(this.status, this.data);

  bool get ok => status >= 200 && status < 300;

  String get error {
    if (data['error'] != null) return data['error'].toString();
    if (status == 0) return 'Gagal konek ke server (${ApiConfig.baseUrl})';
    if (status >= 500) return 'Server bermasalah (kode $status)';
    return 'Terjadi kesalahan, coba lagi';
  }
}

Future<HasilApi> kirimJson(String path, Map<String, dynamic> body) async {
  try {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    Map<String, dynamic> data = {};
    try {
      final d = jsonDecode(res.body);
      if (d is Map<String, dynamic>) data = d;
    } catch (_) {}
    return HasilApi(res.statusCode, data);
  } catch (e) {
    return HasilApi(0, {});
  }
}

/// Logo Stockin. Memakai assets/images/logo.png, kalau tidak ada tampil kotak ikon.
class LogoMerek extends StatelessWidget {
  final double ukuran;
  final bool terang; // true untuk latar gelap
  final bool mendatar; // logo di kiri, nama di kanan
  final bool tampilNama;

  const LogoMerek({
    super.key,
    this.ukuran = 56,
    this.terang = false,
    this.mendatar = false,
    this.tampilNama = true,
  });

  Widget _gambar() {
    return Image.asset(
      'assets/images/logo.png',
      width: ukuran,
      height: ukuran,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: ukuran,
        height: ukuran,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(ukuran * 0.28),
        ),
        child: Icon(Icons.inventory_2, color: Colors.white, size: ukuran * 0.52),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!tampilNama) return _gambar();

    final nama = Text(
      'Stockin',
      style: TextStyle(
        fontSize: ukuran * (mendatar ? 0.5 : 0.36),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: terang ? Colors.white : AppColors.primary,
      ),
    );

    if (mendatar) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [_gambar(), const SizedBox(width: 10), nama],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [_gambar(), const SizedBox(height: 6), nama],
    );
  }
}

/// Kerangka semua halaman auth: putih bersih, logo di atas, judul besar
class AuthScaffold extends StatelessWidget {
  final String judul;
  final String subjudul;
  final List<Widget> children;
  final bool tombolKembali;
  final bool tombolServer;

  // Tidak dipakai lagi, dipertahankan supaya halaman lama tidak error
  final IconData? ikon;

  const AuthScaffold({
    super.key,
    required this.judul,
    required this.subjudul,
    required this.children,
    this.ikon,
    this.tombolKembali = true,
    this.tombolServer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    if (tombolKembali)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textDark),
                        onPressed: () => Navigator.maybePop(context),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    if (tombolServer)
                      IconButton(
                        icon: const Icon(Icons.settings_outlined,
                            color: AppColors.textGrey),
                        tooltip: 'Pengaturan Server',
                        onPressed: () => showServerConfigDialog(context),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LogoMerek(ukuran: 64)),
                    const SizedBox(height: 28),
                    Text(
                      judul,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subjudul,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kolom isian dengan label di atas
class AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final bool isPassword;
  final bool kodeOtp;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.icon,
    this.isPassword = false,
    this.kodeOtp = false,
    this.maxLength,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _sembunyi = true;

  OutlineInputBorder _garis(Color warna, [double lebar = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: warna, width: lebar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otp = widget.kodeOtp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword ? _sembunyi : false,
          keyboardType: otp ? TextInputType.number : widget.keyboardType,
          textCapitalization: widget.textCapitalization,
          textAlign: otp ? TextAlign.center : TextAlign.start,
          maxLength: otp ? 6 : widget.maxLength,
          inputFormatters: otp ? [FilteringTextInputFormatter.digitsOnly] : null,
          onSubmitted: widget.onSubmitted,
          style: otp
              ? const TextStyle(
                  fontSize: 28,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                )
              : const TextStyle(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.textGrey.withOpacity(0.6),
              fontSize: otp ? 28 : 14,
              letterSpacing: otp ? 12 : 0,
            ),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20, color: AppColors.textGrey),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _sembunyi
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textGrey,
                    ),
                    onPressed: () => setState(() => _sembunyi = !_sembunyi),
                  )
                : null,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14, vertical: otp ? 16 : 14),
            border: _garis(AppColors.border),
            enabledBorder: _garis(AppColors.border),
            focusedBorder: _garis(AppColors.primary, 1.6),
          ),
        ),
        if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helper!,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ],
    );
  }
}

/// Tombol utama
/// Tombol utama
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return TekanSkala(
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? const SizedBox(
                    key: ValueKey('memuat'),
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
                    key: const ValueKey('teks'),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Kotak pesan error/sukses (selalu diletakkan di atas isian form)
class AuthAlert extends StatelessWidget {
  final String teks;
  final bool sukses;

  const AuthAlert({super.key, required this.teks, this.sukses = false});

  @override
  Widget build(BuildContext context) {
    final warna = sukses ? AppColors.success : AppColors.danger;
    final latar = sukses ? AppColors.successBg : AppColors.dangerBg;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            sukses ? Icons.check_circle_outline : Icons.error_outline,
            color: warna,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teks,
              style: TextStyle(color: warna, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris teks + tautan kecil di bawah form ("Belum punya akun? Daftar")
class AuthTautan extends StatelessWidget {
  final String teks;
  final String aksi;
  final VoidCallback onTap;

  const AuthTautan({
    super.key,
    required this.teks,
    required this.aksi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(teks, style: const TextStyle(color: AppColors.textGrey, fontSize: 14)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onTap,
          child: Text(
            aksi,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}