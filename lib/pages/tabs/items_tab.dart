import 'package:flutter/material.dart';
import '../products/barang_rusak_page.dart';
import '../../services/gudang_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_stok.dart';
import '../../widgets/baris_produk.dart';
import '../../widgets/tekan_skala.dart';
import '../gudang/gudang_saya_page.dart';
import '../products/produk_detail_page.dart';

enum _FilterStok { semua, aman, menipis, habis, rusak }

class ItemsTab extends StatefulWidget {
  final List products;
  final bool loading;
  final Future<void> Function() onRefresh;

  // Tidak dipakai lagi di tab ini, dibiarkan opsional supaya MainShell tidak error
  final VoidCallback? onScanTap;

  const ItemsTab({
    super.key,
    required this.products,
    required this.loading,
    required this.onRefresh,
    this.onScanTap,
  });

  @override
  State<ItemsTab> createState() => _ItemsTabState();
}

class _ItemsTabState extends State<ItemsTab> {
  _FilterStok filter = _FilterStok.semua;
  StatusGudang? _statusGudang;

  @override
  void initState() {
    super.initState();
    _muatStatus();
  }

  Future<void> _muatStatus() async {
    final s = await GudangService.ambilStatus();
    if (!mounted) return;
    setState(() => _statusGudang = s);
  }

  Future<void> _segarkan() async {
    await widget.onRefresh();
    await _muatStatus();
  }

  bool get _perluGabung {
    final s = _statusGudang;
    return s != null && !s.gagal && !s.aktif;
  }

  bool _cocok(dynamic p, _FilterStok f) {
    switch (f) {
      case _FilterStok.aman:
        return hitungStatusStok(p) == StatusStok.aman;
      case _FilterStok.menipis:
        return hitungStatusStok(p) == StatusStok.menipis;
      case _FilterStok.habis:
        return hitungStatusStok(p) == StatusStok.habis;
      case _FilterStok.rusak:
        return stokRusakDari(p) > 0;
      case _FilterStok.semua:
        return true;
    }
  }

  int _jumlah(_FilterStok f) =>
      widget.products.where((p) => _cocok(p, f)).length;

  List get produkTersaring =>
      widget.products.where((p) => _cocok(p, filter)).toList();

  int get totalUnitLayak {
    int total = 0;
    for (final p in widget.products) {
      if (p is Map) {
        total += int.tryParse(p['stok_saat_ini']?.toString() ?? '0') ?? 0;
      }
    }
    return total;
  }

  String get _pesanKosong {
    switch (filter) {
      case _FilterStok.rusak:
        return 'Tidak ada barang rusak tersortir.';
      case _FilterStok.habis:
        return 'Tidak ada produk yang habis.';
      case _FilterStok.menipis:
        return 'Tidak ada produk yang menipis.';
      case _FilterStok.aman:
        return 'Tidak ada produk berstatus aman.';
      case _FilterStok.semua:
        return 'Belum ada produk di gudang ini.';
    }
  }

  String _namaFilter(_FilterStok f) {
    switch (f) {
      case _FilterStok.aman:
        return 'Aman';
      case _FilterStok.menipis:
        return 'Menipis';
      case _FilterStok.habis:
        return 'Habis';
      case _FilterStok.rusak:
        return 'Rusak';
      case _FilterStok.semua:
        return 'Semua';
    }
  }

  Color _warnaFilter(_FilterStok f) {
    switch (f) {
      case _FilterStok.aman:
        return tampilanAman.warnaTeks;
      case _FilterStok.menipis:
        return tampilanMenipis.warnaTeks;
      case _FilterStok.habis:
        return tampilanHabis.warnaTeks;
      case _FilterStok.rusak:
        return tampilanRusak.warnaTeks;
      case _FilterStok.semua:
        return AppColors.textDark;
    }
  }

  Future<void> _pilihFilter(_FilterStok f) async {
    // Rusak tidak memfilter daftar, tapi membuka halaman karantina & tersortir
    if (f == _FilterStok.rusak) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarangRusakPage()),
      );
      widget.onRefresh();
      return;
    }
    setState(() => filter = filter == f ? _FilterStok.semua : f);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading && widget.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ColoredBox(
      color: AppColors.bg,
      child: RefreshIndicator(
        onRefresh: _segarkan,
        child: _perluGabung ? _tampilanBelumGabung() : _daftarBarang(),
      ),
    );
  }

  // Staf belum bergabung atau masih menunggu persetujuan
  Widget _tampilanBelumGabung() {
    final menunggu = _statusGudang!.status == 'menunggu';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 110),
      children: [
        Center(
          child: Icon(
            menunggu ? Icons.hourglass_top_rounded : Icons.warehouse_outlined,
            size: 52,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          menunggu ? 'Menunggu persetujuan' : 'Belum bergabung ke gudang',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          menunggu
              ? 'Permintaanmu sedang ditinjau Manager. Tarik layar ke bawah untuk memeriksa status terbaru.'
              : 'Masukkan kode gudang dari Manager. Setelah disetujui, daftar barang akan muncul di sini.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textGrey,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TekanSkala(
            child: ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GudangSayaPage()),
                );
                if (mounted) _segarkan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Buka Gudang Saya',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _daftarBarang() {
    final tersaring = produkTersaring;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Barang',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.products.length} produk · $totalUnitLayak unit tersedia',
                style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
        ),

        _kartuStatus(),
        _penandaFilter(tersaring.length),
        const SizedBox(height: 14),

        if (tersaring.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: Text(
                _pesanKosong,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 13.5),
              ),
            ),
          )
        else
          DaftarProduk(
            produk: tersaring,
            onTap: (item) async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProdukDetailPage(item: item),
                ),
              );
              widget.onRefresh();
            },
          ),
      ],
    );
  }

  // ======================================================================
  // KARTU STATUS: angka besar + bar komposisi + empat status yang bisa diketuk
  // ======================================================================

  Widget _kartuStatus() {
    final total = widget.products.length;
    final aman = _jumlah(_FilterStok.aman);
    final menipis = _jumlah(_FilterStok.menipis);
    final habis = _jumlah(_FilterStok.habis);
    final rusak = _jumlah(_FilterStok.rusak);
    final perlu = menipis + habis;

    String besar;
    String keterangan;
    Color warnaBesar;

    if (total == 0) {
      besar = '0';
      keterangan = ' produk di gudang';
      warnaBesar = AppColors.textGrey;
    } else if (perlu == 0) {
      besar = '$total';
      keterangan = ' produk, semuanya aman';
      warnaBesar = tampilanAman.warnaTeks;
    } else {
      besar = '$aman';
      keterangan = ' dari $total produk aman';
      warnaBesar = aman == 0 ? tampilanHabis.warnaTeks : tampilanAman.warnaTeks;
    }

    int? fokus;
    if (filter == _FilterStok.aman) fokus = 0;
    if (filter == _FilterStok.menipis) fokus = 1;
    if (filter == _FilterStok.habis) fokus = 2;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KONDISI STOK',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                besar,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -1,
                  color: warnaBesar,
                ),
              ),
              Flexible(
                child: Text(
                  keterangan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BarKomposisi(
            key: ValueKey('$aman-$menipis-$habis'),
            aman: aman,
            menipis: menipis,
            habis: habis,
            fokus: fokus,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _itemStatus(_FilterStok.aman, aman)),
              Expanded(child: _itemStatus(_FilterStok.menipis, menipis)),
              Expanded(child: _itemStatus(_FilterStok.habis, habis)),
              Container(width: 1, height: 34, color: AppColors.border),
              Expanded(child: _itemStatus(_FilterStok.rusak, rusak)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemStatus(_FilterStok nilai, int jumlah) {
    final aktif = filter == nilai;
    final warna = _warnaFilter(nilai);

    return TekanSkala(
      skala: 0.94,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pilihFilter(nilai),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: aktif ? warna.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _namaFilter(nilai),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: aktif ? FontWeight.w700 : FontWeight.w500,
                      color: aktif ? warna : AppColors.textGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '$jumlah',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: jumlah == 0 && !aktif ? AppColors.textGrey : warna,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Penanda kecil saat filter aktif
  Widget _penandaFilter(int jumlahHasil) {
    if (filter == _FilterStok.semua) return const SizedBox.shrink();

    final warna = _warnaFilter(filter);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: warna.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  'Menampilkan ${_namaFilter(filter)} · $jumlahHasil produk',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: warna,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => filter = _FilterStok.semua),
            child: const Text(
              'Tampilkan semua',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// BAR KOMPOSISI: segmen aman / menipis / habis, terisi dengan animasi
// ========================================================================

class _BarKomposisi extends StatelessWidget {
  final int aman;
  final int menipis;
  final int habis;
  final int? fokus; // 0 aman, 1 menipis, 2 habis, null = semua terang

  const _BarKomposisi({
    super.key,
    required this.aman,
    required this.menipis,
    required this.habis,
    this.fokus,
  });

  @override
  Widget build(BuildContext context) {
    const tinggi = 12.0;
    const celah = 3.0;

    final total = aman + menipis + habis;
    final warna = [
      tampilanAman.warnaTeks,
      tampilanMenipis.warnaTeks,
      tampilanHabis.warnaTeks,
    ];
    final nilai = [aman, menipis, habis];

    final ada = <int>[
      for (int i = 0; i < 3; i++)
        if (nilai[i] > 0) i,
    ];

    return SizedBox(
      height: tinggi,
      child: Stack(
        children: [
          // jalur dasar
          Container(
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(tinggi / 2),
            ),
          ),
          if (total > 0)
            LayoutBuilder(
              builder: (context, c) {
                final lebarTersedia = c.maxWidth - celah * (ada.length - 1);

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 850),
                  curve: Curves.easeOutCubic,
                  builder: (context, p, _) {
                    final anak = <Widget>[];
                    for (int k = 0; k < ada.length; k++) {
                      final i = ada[k];
                      anak.add(
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: (fokus == null || fokus == i) ? 1 : 0.22,
                          child: Container(
                            width: lebarTersedia * nilai[i] / total * p,
                            height: tinggi,
                            decoration: BoxDecoration(
                              color: warna[i],
                              borderRadius: BorderRadius.circular(tinggi / 2),
                            ),
                          ),
                        ),
                      );
                      if (k != ada.length - 1) {
                        anak.add(SizedBox(width: celah * p));
                      }
                    }
                    return Row(children: anak);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}