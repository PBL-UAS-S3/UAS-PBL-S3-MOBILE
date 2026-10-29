import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_stok.dart';
import 'pisah_barang_rusak_dialog.dart';
import 'produk_detail_page.dart';

enum UrutanRusak { terbanyak, namaAZ, hargaTertinggi }

class BarangRusakPage extends StatefulWidget {
  const BarangRusakPage({super.key});

  @override
  State<BarangRusakPage> createState() => _BarangRusakPageState();
}

class _BarangRusakPageState extends State<BarangRusakPage> {
  List<Map<String, dynamic>> products = [];
  bool loading = true;
  String query = '';
  UrutanRusak urutan = UrutanRusak.terbanyak;

  @override
  void initState() {
    super.initState();
    muatData();
  }

  Future<void> muatData() async {
    setState(() => loading = true);
    final data = await ProductService.fetchProducts();
    if (!mounted) return;
    setState(() {
      products = data;
      loading = false;
    });
  }

  int _getInt(dynamic val) {
    if (val is int) return val;
    return int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  num _getNum(dynamic val) {
    if (val is num) return val;
    return num.tryParse(val?.toString() ?? '0') ?? 0;
  }

  String _formatRupiah(dynamic angka) {
    final nilai = _getNum(angka);
    final bagian = nilai.toInt().toString().split('').reversed.toList();
    final hasil = <String>[];
    for (int i = 0; i < bagian.length; i++) {
      if (i != 0 && i % 3 == 0) hasil.add('.');
      hasil.add(bagian[i]);
    }
    return 'Rp${hasil.reversed.join()}';
  }

  List<Map<String, dynamic>> get barangRusakTersortir {
    // Hanya barang yang memiliki stok_rusak > 0
    final list = products.where((p) {
      final rusak = _getInt(p['stok_rusak']);
      if (rusak <= 0) return false;

      if (query.trim().isEmpty) return true;
      final q = query.toLowerCase();
      final nama = (p['nama'] ?? '').toString().toLowerCase();
      final sku = (p['sku'] ?? '').toString().toLowerCase();
      return nama.contains(q) || sku.contains(q);
    }).toList();

    list.sort((a, b) {
      switch (urutan) {
        case UrutanRusak.terbanyak:
          return _getInt(b['stok_rusak']).compareTo(_getInt(a['stok_rusak']));
        case UrutanRusak.namaAZ:
          return (a['nama'] ?? '').toString().compareTo((b['nama'] ?? '').toString());
        case UrutanRusak.hargaTertinggi:
          final rugiB = _getInt(b['stok_rusak']) * _getNum(b['harga']);
          final rugiA = _getInt(a['stok_rusak']) * _getNum(a['harga']);
          return rugiB.compareTo(rugiA);
      }
    });

    return list;
  }

  int get totalUnitRusak {
    int total = 0;
    for (final p in products) {
      total += _getInt(p['stok_rusak']);
    }
    return total;
  }

  num get totalEstimasiRugi {
    num total = 0;
    for (final p in products) {
      total += _getInt(p['stok_rusak']) * _getNum(p['harga']);
    }
    return total;
  }

  void _tampilkanDialogAksi(Map<String, dynamic> item) {
    final sku = item['sku']?.toString() ?? '';
    final nama = item['nama']?.toString() ?? '';
    final stokRusak = _getInt(item['stok_rusak']);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text('SKU: $sku • Stok Rusak: $stokRusak unit', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const Divider(height: 24),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFFFECEC), child: Icon(Icons.delete_outline, color: Colors.red)),
                  title: const Text('Buang / Afkir (Retur Supplier)'),
                  subtitle: const Text('Keluarkan barang rusak yang tidak dapat dipakai'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _dialogKonfirmasiTindakan(item, tipe: 'buang');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.restore_from_trash_outlined, color: Colors.green)),
                  title: const Text('Pulihkan ke Stok Layak'),
                  subtitle: const Text('Kembalikan barang yang sudah selesai diservis/diperbaiki'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _dialogKonfirmasiTindakan(item, tipe: 'pulih');
                  },
                ),
                ListTile(
                  leading: CircleAvatar(backgroundColor: tampilanRusak.latar, child: Icon(Icons.info_outline, color: tampilanRusak.warnaTeks)),
                  title: const Text('Lihat Detail Produk'),
                  subtitle: const Text('Buka halaman informasi lengkap produk ini'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProdukDetailPage(item: item)),
                    ).then((_) => muatData());
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dialogKonfirmasiTindakan(Map<String, dynamic> item, {required String tipe}) {
    final maxJumlah = _getInt(item['stok_rusak']);
    final controller = TextEditingController(text: '$maxJumlah');
    final catatanController = TextEditingController();

    final isBuang = tipe == 'buang';
    final judul = isBuang ? 'Afkir / Buang Barang Rusak' : 'Pulihkan ke Stok Layak';
    final subjudul = isBuang
        ? 'Barang rusak akan dikeluarkan secara permanen dari gudang.'
        : 'Barang rusak akan dikembalikan menjadi stok layak pakai.';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(judul, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subjudul, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah Unit (Maks: $maxJumlah)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catatanController,
                decoration: InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isBuang ? tampilanHabis.warnaTeks : tampilanAman.warnaTeks,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final jml = int.tryParse(controller.text) ?? 0;
                if (jml <= 0 || jml > maxJumlah) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Jumlah tidak valid')),
                  );
                  return;
                }
                Navigator.pop(ctx);

                final sku = item['sku']?.toString() ?? '';
                final res = isBuang
                    ? await ProductService.buangBarangRusak(sku: sku, jumlah: jml, keterangan: catatanController.text)
                    : await ProductService.pulihkanBarangRusak(sku: sku, jumlah: jml, keterangan: catatanController.text);

                if (!mounted) return;
                if (res['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: isBuang ? tampilanHabis.warnaTeks : tampilanAman.warnaTeks,
                      content: Text(res['message'] ?? 'Berhasil diproses!'),
                    ),
                  );
                  muatData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(res['error'] ?? 'Gagal memproses')),
                  );
                }
              },
              child: Text(isBuang ? 'Afkir / Buang' : 'Pulihkan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = barangRusakTersortir;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Barang Rusak Tersortir', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: muatData,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: muatData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Kartu Ringkasan Barang Rusak
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tampilanRusak.warnaTeks,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: tampilanRusak.warnaTeks.withOpacity(0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                              ),
                              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Area Karantina & Sortir',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                  ),
                                  Text(
                                    'Barang rusak menunggu tindakan',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Unit Rusak', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalUnitRusak Unit',
                                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 40, color: Colors.white24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Jenis Barang', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${products.where((p) => _getInt(p['stok_rusak']) > 0).length} SKU',
                                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.monetization_on_outlined, color: Colors.white60, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Estimasi Kerugian: ${_formatRupiah(totalEstimasiRugi)}',
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search & Sort Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => query = v),
                          decoration: InputDecoration(
                            hintText: 'Cari barang rusak...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      PopupMenuButton<UrutanRusak>(
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.sort, color: AppColors.textDark),
                        ),
                        initialValue: urutan,
                        onSelected: (u) => setState(() => urutan = u),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: UrutanRusak.terbanyak,
                            child: Text('Stok Rusak Terbanyak'),
                          ),
                          const PopupMenuItem(
                            value: UrutanRusak.namaAZ,
                            child: Text('Nama Produk (A-Z)'),
                          ),
                          const PopupMenuItem(
                            value: UrutanRusak.hargaTertinggi,
                            child: Text('Nilai Kerugian Tertinggi'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // List Item
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: tampilanAman.latar,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.check_circle_outline, size: 54, color: tampilanAman.warnaTeks),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Gudang Aman & Rapi!',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              query.isEmpty
                                  ? 'Tidak ada barang rusak yang terdaftar di sistem.'
                                  : 'Tidak ditemukan barang rusak untuk pencarian "$query".',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...list.map((item) => _kartuBarangRusak(item)),
                ],
              ),
            ),
    );
  }

  Widget _kartuBarangRusak(Map<String, dynamic> item) {
    final gambar = item['gambar'];
    final stokRusak = _getInt(item['stok_rusak']);
    final stokLayak = _getInt(item['stok_saat_ini']);
    final harga = _getNum(item['harga']);
    final totalRugi = stokRusak * harga;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Strip aksen oranye di kiri
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [tampilanRusak.warnaTeks, tampilanRusak.garis],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: gambar != null
                                ? Image.network(
                                    '${ApiConfig.baseUrl}$gambar',
                                    width: 68,
                                    height: 68,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _placeholderThumb(),
                                  )
                                : _placeholderThumb(),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['nama'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.textDark,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'SKU: ${item['sku'] ?? '-'}',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Estimasi Kerugian: ${_formatRupiah(totalRugi)}',
                                  style: TextStyle(
                                    color: tampilanRusak.warnaTeks,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          LencanaStatus(
                            tampilanRusak,
                            label: '$stokRusak Rusak',
                            ukuranFont: 12,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 1,
                        color: Colors.grey.shade100,
                      ),
                      const SizedBox(height: 10),
                      // Chip stok layak
                      Align(
                        alignment: Alignment.centerLeft,
                        child: LencanaStatus(
                          tampilanAman,
                          label: 'Layak: $stokLayak ${item['satuan'] ?? 'unit'}',
                          ukuranFont: 11.5,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tombol aksi
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                PisahBarangRusakDialog.show(
                                  context,
                                  item: item,
                                  onSuccess: muatData,
                                );
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Sortir Lagi',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: tampilanRusak.warnaTeks,
                                side: BorderSide(color: tampilanRusak.garis, width: 1.4),
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _tampilkanDialogAksi(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tampilanRusak.warnaTeks,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Tindakan',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: tampilanRusak.latar,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.build_circle_outlined, color: tampilanRusak.garis, size: 28),
    );
  }
}