import 'package:flutter/material.dart';

import '../../services/gudang_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import '../main_shell.dart';

class GudangSayaPage extends StatefulWidget {
  // true kalau dibuka otomatis setelah login (staf belum aktif di gudang mana pun)
  final bool awalLogin;

  const GudangSayaPage({super.key, this.awalLogin = false});

  @override
  State<GudangSayaPage> createState() => _GudangSayaPageState();
}

class _GudangSayaPageState extends State<GudangSayaPage> {
  final kodeController = TextEditingController();

  StatusGudang? _status;
  bool _memuat = true;
  bool _proses = false;
  String pesanError = '';
  String pesanInfo = '';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    kodeController.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() => _memuat = true);
    final hasil = await GudangService.ambilStatus();
    if (!mounted) return;
    setState(() {
      _status = hasil;
      _memuat = false;
      if (hasil.gagal) pesanError = hasil.error!;
    });
  }

  Future<void> _ajukan() async {
    final kode = kodeController.text.trim();
    if (kode.isEmpty) {
      setState(() {
        pesanError = 'Kode gudang wajib diisi';
        pesanInfo = '';
      });
      return;
    }

    setState(() {
      _proses = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await GudangService.gabung(kode.toUpperCase());
    if (!mounted) return;

    if (hasil.ok) {
      kodeController.clear();
      await _muat();
      if (!mounted) return;
      setState(() {
        _proses = false;
        pesanInfo = hasil.pesan;
      });
    } else {
      setState(() {
        _proses = false;
        pesanError = hasil.pesan;
      });
    }
  }

  Future<void> _keluar({required bool batal}) async {
    final lanjut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          batal ? 'Batalkan permintaan?' : 'Keluar dari gudang?',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Text(
          batal
              ? 'Permintaan bergabungmu akan dibatalkan. Kamu bisa mengajukan lagi kapan saja.'
              : 'Kamu tidak bisa lagi melihat atau mencatat stok di gudang ini. Riwayat transaksimu tetap tersimpan.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(batal ? 'Batalkan' : 'Keluar'),
          ),
        ],
      ),
    );
    if (lanjut != true) return;

    setState(() {
      _proses = true;
      pesanError = '';
      pesanInfo = '';
    });

    final hasil = await GudangService.keluar();
    if (!mounted) return;

    if (hasil.ok) {
      await _muat();
      if (!mounted) return;
      setState(() => _proses = false);
    } else {
      setState(() {
        _proses = false;
        pesanError = hasil.pesan;
      });
    }
  }

  void _keAplikasi() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainShell()),
    );
  }

  Widget _kartuStatus({
    required IconData ikon,
    required Color warna,
    required Color latar,
    required String judul,
    required String isi,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: latar,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(ikon, color: warna, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isi,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tombolKeluar(String label, {required bool batal}) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: _proses ? null : () => _keluar(batal: batal),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _proses
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.danger,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  List<Widget> _isiStatus(StatusGudang s) {
    if (s.status == 'aktif') {
      return [
        _kartuStatus(
          ikon: Icons.check_circle_outline_rounded,
          warna: AppColors.success,
          latar: AppColors.successBg,
          judul: 'Tergabung',
          isi:
              'Kamu aktif di ${s.namaGudang ?? 'gudang ini'}. Stok dan riwayat gudang bisa kamu lihat dan catat.',
        ),
        const SizedBox(height: 20),
        _tombolKeluar('Keluar dari gudang', batal: false),
      ];
    }

    if (s.status == 'menunggu') {
      return [
        _kartuStatus(
          ikon: Icons.hourglass_top_rounded,
          warna: AppColors.warning,
          latar: AppColors.warningBg,
          judul: 'Menunggu persetujuan',
          isi:
              'Permintaanmu ke ${s.namaGudang ?? 'gudang'} sedang ditinjau Manager. Tarik layar ke bawah untuk memeriksa status terbaru.',
        ),
        const SizedBox(height: 20),
        _tombolKeluar('Batalkan permintaan', batal: true),
      ];
    }

    return [
      _kartuStatus(
        ikon: Icons.warehouse_outlined,
        warna: AppColors.primary,
        latar: AppColors.primarySoft,
        judul: 'Belum bergabung',
        isi:
            'Masukkan kode gudang dari Manager untuk mengajukan bergabung. Setelah disetujui, data stok gudang akan muncul di aplikasi.',
      ),
      const SizedBox(height: 22),
      AuthField(
        controller: kodeController,
        label: 'Kode gudang',
        hint: 'Contoh: K7M4QX',
        icon: Icons.vpn_key_outlined,
        maxLength: 10,
        textCapitalization: TextCapitalization.characters,
        onSubmitted: (_) => _ajukan(),
      ),
      const SizedBox(height: 18),
      AuthButton(label: 'Ajukan bergabung', onPressed: _ajukan, loading: _proses),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        automaticallyImplyLeading: !widget.awalLogin,
        title: const Text(
          'Gudang Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Muat ulang',
            onPressed: (_memuat || _proses) ? null : _muat,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              if (pesanError.isNotEmpty) AuthAlert(teks: pesanError),
              if (pesanInfo.isNotEmpty) AuthAlert(teks: pesanInfo, sukses: true),
              if (_memuat && s == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (s != null && !s.gagal)
                ..._isiStatus(s),
              if (widget.awalLogin) ...[
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: _keAplikasi,
                    child: Text(
                      'Masuk ke aplikasi',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}