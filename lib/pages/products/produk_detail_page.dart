import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/status_stok.dart';
import '../../widgets/baris_produk.dart';
import '../transactions/transaksi_page.dart';
import 'pisah_barang_rusak_dialog.dart';

class ProdukDetailPage extends StatefulWidget {
  final Map item;
  const ProdukDetailPage({super.key, required this.item});

  @override
  State<ProdukDetailPage> createState() => _ProdukDetailPageState();
}

class _ProdukDetailPageState extends State<ProdukDetailPage> {
  late Map currentItem;

  @override
  void initState() {
    super.initState();
    currentItem = Map.from(widget.item);
  }

  int get _stokLayak => ambilInt(currentItem['stok_saat_ini']);
  int get _stokRusak => ambilInt(currentItem['stok_rusak']);
  int get _stokMinimum => ambilInt(currentItem['stok_minimum']);
  int get _totalFisik => _stokLayak + _stokRusak;

  StatusStok get _status => hitungStatusStok(currentItem);

  String get _labelStatus {
    switch (_status) {
      case StatusStok.habis:
        return 'Stok habis';
      case StatusStok.menipis:
        return 'Stok menipis';
      case StatusStok.aman:
        return 'Stok aman';
    }
  }

  Future<void> _refreshDetail() async {
    final sku = currentItem['sku']?.toString() ?? '';
    final fresh = await ProductService.cariDetailProduk(sku);
    if (fresh != null && mounted) {
      setState(() => currentItem = fresh);
    }
  }

  String _teks(dynamic nilai) {
    final t = nilai?.toString() ?? '';
    return t.isEmpty ? '-' : t;
  }

  @override
  Widget build(BuildContext context) {
    final gambar = currentItem['gambar'];
    final hargaPerUnit = num.tryParse(currentItem['harga']?.toString() ?? '0') ?? 0;
    final tampil = tampilanStatus(_status);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: const Text(
          'Detail produk',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDetail,
            tooltip: 'Segarkan',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Foto penuh lebar
          Container(
            height: 240,
            width: double.infinity,
            color: Colors.grey.shade100,
            child: gambar != null
                ? Image.network(
                    '${ApiConfig.baseUrl}$gambar',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => _placeholderBesar(),
                  )
                : _placeholderBesar(),
          ),

          // Nama, SKU, status
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentItem['nama']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'SKU ${currentItem['sku'] ?? '-'}',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tampil.warnaTeks,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _labelStatus,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tampil.warnaTeks,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),

          // Angka stok
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _kolomStok('Stok layak', '$_stokLayak', AppColors.textDark),
                  VerticalDivider(width: 1, color: AppColors.border),
                  _kolomStok(
                    'Rusak',
                    '$_stokRusak',
                    _stokRusak > 0 ? tampilanRusak.warnaTeks : AppColors.textDark,
                  ),
                  VerticalDivider(width: 1, color: AppColors.border),
                  _kolomStok('Minimum', '$_stokMinimum', AppColors.textGrey),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.border),

          // Aksi
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final res = await PisahBarangRusakDialog.show(
                        context,
                        item: currentItem,
                        onSuccess: _refreshDetail,
                      );
                      if (res == true) _refreshDetail();
                    },
                    icon: const Icon(Icons.call_split, size: 18),
                    label: const Text(
                      'Pisahkan rusak',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: tampilanRusak.warnaTeks,
                      side: BorderSide(color: tampilanRusak.warnaTeks.withOpacity(0.5)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final sku = currentItem['sku']?.toString() ?? '';
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TransaksiPage(sku: sku)),
                      );
                      _refreshDetail();
                    },
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text(
                      'Transaksi stok',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informasi
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 22, 16, 8),
            child: Text(
              'INFORMASI',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textGrey,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                _barisInfo('Kategori', _teks(currentItem['kategori'])),
                _barisInfo('Satuan', _teks(currentItem['satuan'])),
                _barisInfo('Harga per unit', formatRp(hargaPerUnit)),
                _barisInfo('Total fisik', '$_totalFisik unit'),
                _barisInfo(
                  'Nilai stok layak',
                  formatRp(hargaPerUnit * _stokLayak),
                  terakhir: _stokRusak == 0,
                ),
                if (_stokRusak > 0)
                  _barisInfo(
                    'Estimasi kerugian rusak',
                    formatRp(hargaPerUnit * _stokRusak),
                    warnaNilai: tampilanRusak.warnaTeks,
                    terakhir: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderBesar() {
    return Center(
      child: Icon(Icons.inventory_2_outlined, color: Colors.grey.shade400, size: 56),
    );
  }

  Widget _kolomStok(String label, String nilai, Color warna) {
    return Expanded(
      child: Column(
        children: [
          Text(
            nilai,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: warna),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _barisInfo(
    String label,
    String nilai, {
    Color? warnaNilai,
    bool terakhir = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
                ),
              ),
              Text(
                nilai,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: warnaNilai ?? AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        if (!terakhir) Divider(height: 1, indent: 16, color: AppColors.border),
      ],
    );
  }
}