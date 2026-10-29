import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/auth_widgets.dart';
import 'login_page.dart';
import 'register_page.dart';

// Ukuran rancangan mockup iPhone 15 (rasio sekitar 1 : 2,06)
const double _pLebar = 262;
const double _pTinggi = 540;

const Color _hijau = Color(0xFF16A34A);
const Color _kuning = Color(0xFFB45309);
const Color _titikKuning = Color(0xFFF59E0B);
const Color _merah = Color(0xFFDC2626);
const Color _ungu = Color(0xFFEA580C);
const Color _layarTerang = Color(0xFFF8FAFC);

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _halaman = 0;

  static const List<String> _judul = [
    'Stok gudang terpantau, tanpa ribet',
    'Scan barcode, catat dalam hitungan detik',
    'Pisahkan barang rusak dari stok layak',
  ];

  static const List<String> _sub = [
    'Lihat semua barang, jumlah, dan statusnya dalam satu daftar.',
    'Catat barang masuk dan keluar langsung dari ponselmu.',
    'Stok tetap akurat karena barang cacat tidak ikut terhitung.',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_halaman + 1) % _judul.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _keRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
    );
  }

  void _keLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Widget _layar(int i) {
    switch (i) {
      case 0:
        return const _LayarDaftar();
      case 1:
        return const _LayarScan();
      default:
        return const _LayarRusak();
    }
  }

  // Ponsel selebar ~74% layar, memenuhi tinggi area, bagian bawah terpotong
  Widget _areaPonsel(int i) {
    return LayoutBuilder(
      builder: (context, c) {
        final lebar = (c.maxWidth * 0.74).clamp(220.0, 300.0);

        return Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: lebar,
                height: c.maxHeight,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: _Ponsel(layar: _layar(i), gelap: i == 1),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.bg.withOpacity(0),
                        AppColors.bg,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _slide(int i) {
    return Column(
      children: [
        Expanded(child: _areaPonsel(i)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Text(
                _judul[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _sub[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 14, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LogoMerek(ukuran: 34, tampilNama: false),
                  SizedBox(width: 10),
                  Text(
                    'Stockin',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _judul.length,
                onPageChanged: (i) => setState(() => _halaman = i),
                itemBuilder: (context, i) => _slide(i),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_judul.length, (i) {
                final aktif = i == _halaman;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: aktif ? 26 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: aktif ? AppColors.textDark : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _keRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Mulai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sudah punya akun? ',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14.5),
                ),
                GestureDetector(
                  onTap: _keLogin,
                  child: const Text(
                    'Masuk',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// Mockup iPhone 15 (digambar dengan widget, ukuran tetap lalu diskalakan)
// ========================================================================

class _Ponsel extends StatelessWidget {
  final Widget layar;
  final bool gelap; // true kalau layar di dalamnya gelap (status bar jadi putih)

  const _Ponsel({required this.layar, this.gelap = false});

  Widget _tombol(double tinggi) {
    return Container(
      width: 4,
      height: tinggi,
      decoration: BoxDecoration(
        color: const Color(0xFF4B5563),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warnaStatus = gelap ? Colors.white : AppColors.textDark;

    return SizedBox(
      width: _pLebar,
      height: _pTinggi,
      child: Stack(
        children: [
          // tombol samping
          Positioned(left: 0, top: 92, child: _tombol(26)),
          Positioned(left: 0, top: 132, child: _tombol(44)),
          Positioned(left: 0, top: 186, child: _tombol(44)),
          Positioned(right: 0, top: 150, child: _tombol(68)),

          // bodi
          Positioned.fill(
            left: 3,
            right: 3,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(46),
                border: Border.all(color: const Color(0xFF4B5563), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(color: _layarTerang, child: layar),
                    ),
                    // status bar
                    Positioned(
                      top: 14,
                      left: 22,
                      right: 20,
                      child: Row(
                        children: [
                          Text(
                            '9:41',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: warnaStatus,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.signal_cellular_alt, size: 13, color: warnaStatus),
                          const SizedBox(width: 4),
                          Icon(Icons.wifi, size: 13, color: warnaStatus),
                          const SizedBox(width: 4),
                          Icon(Icons.battery_full, size: 15, color: warnaStatus),
                        ],
                      ),
                    ),
                    // Dynamic Island
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 74,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// Layar 1: daftar barang
// ------------------------------------------------------------------------

class _Brg {
  final IconData ikon;
  final String nama;
  final String info;
  final String stok;
  final String status;
  final Color warna;
  final Color titik;

  const _Brg(this.ikon, this.nama, this.info, this.stok, this.status,
      this.warna, this.titik);
}

const List<_Brg> _dataBarang = [
  _Brg(Icons.mouse_outlined, 'Mousepad Gaming', 'SKU004 · Aksesoris', '25',
      'Aman', _hijau, _hijau),
  _Brg(Icons.cable_outlined, 'Kabel HDMI', 'SKU002 · Kabel', '4', 'Menipis',
      _kuning, _titikKuning),
  _Brg(Icons.keyboard_outlined, 'Keyboard Mekanik', 'SKU007 · Aksesoris', '0',
      'Habis', _merah, _merah),
  _Brg(Icons.headphones_outlined, 'Headset Gaming', 'SKU011 · Audio', '18',
      'Aman', _hijau, _hijau),
  _Brg(Icons.videocam_outlined, 'Webcam HD', 'SKU012 · Kamera', '12', 'Aman',
      _hijau, _hijau),
  _Brg(Icons.usb_outlined, 'Flashdisk 32GB', 'SKU015 · Penyimpanan', '3',
      'Menipis', _kuning, _titikKuning),
  _Brg(Icons.desktop_windows_outlined, 'Monitor 24 inci', 'SKU018 · Monitor',
      '9', 'Aman', _hijau, _hijau),
];

class _LayarDaftar extends StatelessWidget {
  const _LayarDaftar();

  Widget _kolom(String angka, String label, Color warna, {bool aktif = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: aktif ? warna.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            Text(
              angka,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: warna,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: aktif ? warna : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _baris(_Brg b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(b.ikon, size: 16, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.nama,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  b.info,
                  style: const TextStyle(fontSize: 8.5, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                b.stok,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(color: b.titik, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    b.status,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: b.warna,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 54, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Barang',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            '11 produk · 164 unit tersedia',
            style: TextStyle(fontSize: 10, color: AppColors.textGrey),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _kolom('11', 'Semua', AppColors.textDark, aktif: true),
                _kolom('8', 'Aman', _hijau),
                _kolom('2', 'Menipis', _kuning),
                _kolom('1', 'Habis', _merah),
                _kolom('2', 'Rusak', _ungu),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (int i = 0; i < _dataBarang.length; i++) ...[
                  _baris(_dataBarang[i]),
                  if (i != _dataBarang.length - 1)
                    const Divider(
                      height: 1,
                      indent: 51,
                      color: AppColors.border,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// Layar 2: scan barcode
// ------------------------------------------------------------------------

class _BingkaiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cat = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const p = 28.0;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(const Offset(0, p), const Offset(0, 0), cat);
    canvas.drawLine(const Offset(0, 0), const Offset(p, 0), cat);
    canvas.drawLine(Offset(w - p, 0), Offset(w, 0), cat);
    canvas.drawLine(Offset(w, 0), Offset(w, p), cat);
    canvas.drawLine(Offset(0, h - p), Offset(0, h), cat);
    canvas.drawLine(Offset(0, h), Offset(p, h), cat);
    canvas.drawLine(Offset(w - p, h), Offset(w, h), cat);
    canvas.drawLine(Offset(w, h), Offset(w, h - p), cat);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LayarScan extends StatelessWidget {
  const _LayarScan();

  @override
  Widget build(BuildContext context) {
    const lebarBatang = [3.0, 1.0, 2.0, 1.0, 4.0, 2.0, 1.0, 3.0, 1.0, 2.0, 3.0, 1.0];

    return Stack(
      children: [
        // tampilan kamera
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF334155), Color(0xFF0F172A)],
              ),
            ),
          ),
        ),
        // bingkai scan + barcode + garis laser
        Positioned(
          top: 104,
          left: 0,
          right: 0,
          child: Center(
            child: SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(150, 150),
                    painter: _BingkaiPainter(),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final w in lebarBatang)
                        Container(
                          width: w,
                          height: 58,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          color: Colors.white70,
                        ),
                    ],
                  ),
                  Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF22C55E).withOpacity(0.8),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          top: 268,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Arahkan kamera ke barcode SKU',
              style: TextStyle(color: Colors.white70, fontSize: 10.5),
            ),
          ),
        ),
        // kartu hasil scan
        Positioned(
          top: 306,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.mouse_outlined,
                    size: 19,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mousepad Gaming',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'SKU004 · stok 25',
                        style: TextStyle(fontSize: 9, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Catat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------
// Layar 3: pisahkan barang rusak
// ------------------------------------------------------------------------

class _LayarRusak extends StatelessWidget {
  const _LayarRusak();

  Widget _label(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        t,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _kotakIsian(String isi, {String? akhir, IconData? ikon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isi,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textDark),
            ),
          ),
          if (akhir != null)
            Text(
              akhir,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textGrey),
            ),
          if (ikon != null) Icon(ikon, size: 18, color: AppColors.textGrey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 54, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pemisahan Barang Rusak',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Sortir barang cacat dari stok layak',
            style: TextStyle(fontSize: 10, color: AppColors.textGrey),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mousepad Gaming',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'SKU004',
                        style: TextStyle(fontSize: 9.5, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Layak: 25',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _hijau,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Rusak: 0',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _ungu,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _label('Jumlah barang rusak'),
          _kotakIsian('5', akhir: 'pcs'),
          const SizedBox(height: 12),
          _label('Kondisi / alasan kerusakan'),
          _kotakIsian('Tidak berfungsi / mati', ikon: Icons.arrow_drop_down),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ungu,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_split, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Pisahkan ke Barang Rusak',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}