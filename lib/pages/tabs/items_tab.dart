import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../products/barang_rusak_page.dart';
import '../products/produk_detail_page.dart';

enum _FilterStok { semua, aman, menipis, rusak }

class ItemsTab extends StatefulWidget {
  final List products;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onTambah;

  const ItemsTab({
    super.key,
    required this.products,
    required this.loading,
    required this.onRefresh,
    required this.onTambah,
  });

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  _FilterStok filter = _FilterStok.semua;

  int _getInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  bool _menipis(Map item) {
    final stok = _getInt(item['stok_saat_ini']);
    final min = _getInt(item['stok_minimum']);
    return stok <= min;
  }

  bool _adaRusak(Map item) {
    final rusak = _getInt(item['stok_rusak']);
    return rusak > 0;
  }

  int get totalUnitRusak {
    int total = 0;
    for (final p in widget.products) {
      if (p is Map) total += _getInt(p['stok_rusak']);
    }
    return total;
  }

  List get produkTersaring {
    switch (filter) {
      case _FilterStok.menipis:
        return widget.products.where((p) => _menipis(p)).toList();
      case _FilterStok.aman:
        return widget.products.where((p) => !_menipis(p)).toList();
      case _FilterStok.rusak:
        return widget.products.where((p) => _adaRusak(p)).toList();
      case _FilterStok.semua:
        return widget.products;
    }
  }

  String _formatRupiah(dynamic angka) {
    final nilai = num.tryParse(angka?.toString() ?? '0') ?? 0;
    final bagian = nilai.toInt().toString().split('').reversed.toList();
    final hasil = <String>[];
    for (int i = 0; i < bagian.length; i++) {
      if (i != 0 && i % 3 == 0) hasil.add('.');
      hasil.add(bagian[i]);
    }
    return 'Rp${hasil.reversed.join()}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalRusak = totalUnitRusak;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Staf Gudang',
                    style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(text: 'Gudang '),
                    TextSpan(
                      text: 'pintar, ',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: 'keputusan lebih cepat'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Carousel promo
              _PromoCarousel(onMulaiSekarang: widget.onRefresh),

              const SizedBox(height: 18),

              // Banner notifikasi Barang Rusak Tersortir
              if (totalRusak > 0) ...[
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BarangRusakPage()),
                    );
                    widget.onRefresh();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tersortir $totalRusak unit barang rusak',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                        const Text(
                          'Kelola',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: Colors.red),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Filter pills (Semua, Aman, Menipis, Barang Rusak)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(
                      'Semua',
                      filter == _FilterStok.semua,
                      () => setState(() => filter = _FilterStok.semua),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Aman',
                      filter == _FilterStok.aman,
                      () => setState(() => filter = _FilterStok.aman),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Menipis',
                      filter == _FilterStok.menipis,
                      () => setState(() => filter = _FilterStok.menipis),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      'Barang Rusak',
                      filter == _FilterStok.rusak,
                      () => setState(() => filter = _FilterStok.rusak),
                      isDanger: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (produkTersaring.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      filter == _FilterStok.rusak
                          ? 'Tidak ada barang rusak tersortir.'
                          : 'Tidak ada produk.',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                )
              else
                ...produkTersaring.asMap().entries.map(
                  (e) => _kartuProduk(e.value, isLast: e.key == produkTersaring.length - 1),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: widget.onTambah,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool aktif, VoidCallback onTap, {bool isDanger = false}) {
    Color activeBg = isDanger ? Colors.red.shade600 : AppColors.success;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: aktif ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: aktif ? activeBg : (isDanger ? Colors.red.shade200 : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: aktif ? Colors.white : (isDanger ? Colors.red.shade700 : AppColors.textGrey),
          ),
        ),
      ),
    );
  }

  Widget _kartuProduk(Map item, {bool isLast = false}) {
    final menipis = _menipis(item);
    final stokRusak = _getInt(item['stok_rusak']);
    final gambar = item['gambar'];
    final kategori =
        (item['kategori'] != null && item['kategori'].toString().isNotEmpty)
            ? item['kategori'].toString()
            : null;
    final satuan =
        (item['satuan'] != null && item['satuan'].toString().isNotEmpty)
            ? item['satuan'].toString()
            : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProdukDetailPage(item: item)),
        );
        widget.onRefresh();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: stokRusak > 0 ? Colors.red.shade200 : AppColors.border,
            width: stokRusak > 0 ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: gambar != null
                  ? Image.network(
                      '${ApiConfig.baseUrl}$gambar',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholderThumb(),
                    )
                  : _placeholderThumb(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item['sku'] ?? '-'}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (kategori != null)
                        _tagKecil(
                          kategori,
                          AppColors.primarySoft,
                          AppColors.primaryDarkText,
                        ),
                      if (satuan != null)
                        _tagKecil(
                          satuan,
                          Colors.grey.shade100,
                          AppColors.textGrey,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatRupiah(item['harga']),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['stok_saat_ini'] ?? 0}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: menipis ? AppColors.dangerBg : AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    menipis ? 'Menipis' : 'Aman',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: menipis ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ),
                if (stokRusak > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$stokRusak Rusak',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagKecil(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.primarySoft,
      child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 22),
    );
  }
}

// ========================================================================
// CAROUSEL PROMO — geser otomatis tiap 4 detik
// ========================================================================

class _PromoCarousel extends StatefulWidget {
  final Future<void> Function() onMulaiSekarang;
  const _PromoCarousel({required this.onMulaiSekarang});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _halaman = 0;

  final List<Map<String, dynamic>> _slide = const [
    {
      'badge': 'Stokmu',
      'judul': 'Terpantau Otomatis\nStockin',
      'bg': AppColors.primarySoft,
      'icon': Icons.inventory_2,
      'iconColor': Color(0xFF93C5FD),
      'badgeColor': AppColors.success,
      'badgeBg': Color(0x2616A34A),
    },
    {
      'badge': 'Sortir Rusak',
      'judul': 'Pemisahan Barang\nRusak & Karantina',
      'bg': Color(0xFFFEE2E2),
      'icon': Icons.build_circle_outlined,
      'iconColor': Color(0xFFFCA5A5),
      'badgeColor': Color(0xFFDC2626),
      'badgeBg': Color(0x26DC2626),
    },
    {
      'badge': 'Scan Cepat',
      'judul': 'Catat Transaksi\nLewat Barcode',
      'bg': Color(0xFFE7F8EE),
      'icon': Icons.qr_code_scanner,
      'iconColor': Color(0xFF86EFAC),
      'badgeColor': AppColors.primaryDarkText,
      'badgeBg': Color(0x261E3A8A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_controller.hasClients) return;
      final berikutnya = (_halaman + 1) % _slide.length;
      _controller.animateToPage(
        berikutnya,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slide.length,
            onPageChanged: (i) => setState(() => _halaman = i),
            itemBuilder: (context, index) {
              final s = _slide[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: s['bg'] as Color,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: s['badgeBg'] as Color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s['badge'] as String,
                              style: TextStyle(
                                color: s['badgeColor'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['judul'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: widget.onMulaiSekarang,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Mulai Sekarang',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      s['icon'] as IconData,
                      size: 52,
                      color: s['iconColor'] as Color,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slide.length, (i) {
            final aktif = i == _halaman;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: aktif ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: aktif ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }
}