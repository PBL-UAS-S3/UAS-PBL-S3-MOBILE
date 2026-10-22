import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
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

  int get _stokLayak {
    final val = currentItem['stok_saat_ini'];
    return val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  int get _stokRusak {
    final val = currentItem['stok_rusak'];
    return val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  int get _stokMinimum {
    final val = currentItem['stok_minimum'];
    return val is int ? val : int.tryParse(val?.toString() ?? '0') ?? 0;
  }

  int get _totalFisik => _stokLayak + _stokRusak;

  bool get _menipis => _stokLayak <= _stokMinimum;

  bool get _perluDipantau => !_menipis && _stokLayak <= (_stokMinimum * 1.5);

  String get _statusLabel {
    if (_menipis) return 'Stok Menipis';
    if (_perluDipantau) return 'Perlu Dipantau';
    return 'Aman';
  }

  Color get _statusColor {
    if (_menipis) return AppColors.danger;
    if (_perluDipantau) return AppColors.warning;
    return AppColors.success;
  }

  Color get _statusBg {
    if (_menipis) return AppColors.dangerBg;
    if (_perluDipantau) return AppColors.warningBg;
    return AppColors.successBg;
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

  Future<void> _refreshDetail() async {
    final sku = currentItem['sku']?.toString() ?? '';
    final fresh = await ProductService.cariDetailProduk(sku);
    if (fresh != null && mounted) {
      setState(() => currentItem = fresh);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gambar = currentItem['gambar'];
    final hargaPerUnit = num.tryParse(currentItem['harga']?.toString() ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Detail Produk', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDetail,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.grey.shade100,
                  child: gambar != null
                      ? Image.network(
                          '${ApiConfig.baseUrl}$gambar',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _placeholderBesar(),
                        )
                      : _placeholderBesar(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  currentItem['nama'] ?? '-',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'SKU: ${currentItem['sku'] ?? '-'}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 20),

          // Kartu ringkasan stok (Layak, Rusak, Minimum)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stok Layak', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '$_stokLayak',
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Stok Rusak Tersortir', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '$_stokRusak',
                            style: TextStyle(
                              color: _stokRusak > 0 ? const Color(0xFFFCA5A5) : Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Fisik: $_totalFisik unit',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Batas Min: $_stokMinimum unit',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Aksi Cepat: Pisahkan Barang Rusak & Catat Transaksi
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await PisahBarangRusakDialog.show(
                      context,
                      item: currentItem,
                      onSuccess: _refreshDetail,
                    );
                    if (res == true) _refreshDetail();
                  },
                  icon: const Icon(Icons.call_split, size: 18),
                  label: const Text('Pisahkan Rusak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  label: const Text('Transaksi Stok', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('Informasi Produk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          _baris(Icons.category_outlined, 'Kategori',
              (currentItem['kategori'] != null && currentItem['kategori'].toString().isNotEmpty) ? currentItem['kategori'] : '-'),
          _baris(Icons.straighten_outlined, 'Satuan',
              (currentItem['satuan'] != null && currentItem['satuan'].toString().isNotEmpty) ? currentItem['satuan'] : '-'),
          _baris(Icons.sell_outlined, 'Harga per Unit', _formatRupiah(hargaPerUnit)),
          _baris(
            Icons.account_balance_wallet_outlined,
            'Total Nilai Stok Layak',
            _formatRupiah(hargaPerUnit * _stokLayak),
          ),
          if (_stokRusak > 0)
            _baris(
              Icons.warning_amber_outlined,
              'Estimasi Kerugian Stok Rusak',
              _formatRupiah(hargaPerUnit * _stokRusak),
              warnaNilai: Colors.red.shade700,
            ),
        ],
      ),
    );
  }

  Widget _placeholderBesar() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.primarySoft,
      child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 56),
    );
  }

  Widget _baris(IconData icon, String label, String value, {Color? warnaNilai}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: warnaNilai ?? AppColors.textDark,
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
