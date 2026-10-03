import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class ProdukDetailPage extends StatelessWidget {
  final Map item;
  const ProdukDetailPage({super.key, required this.item});

  bool get _menipis {
    final stok = item['stok_saat_ini'] ?? 0;
    final min = item['stok_minimum'] ?? 0;
    return stok <= min;
  }

  bool get _perluDipantau {
    final stok = item['stok_saat_ini'] ?? 0;
    final min = item['stok_minimum'] ?? 0;
    return !_menipis && stok <= min * 1.5;
  }

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

  @override
  Widget build(BuildContext context) {
    final gambar = item['gambar'];

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text('Detail Produk', style: TextStyle(color: AppColors.textDark)),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1, // Membikin wadah berbentuk kotak (1:1)
                child: Container(
                  color: Colors.grey.shade100, // Background netral untuk area gambar
                  child: gambar != null
                      ? Image.network(
                          '${ApiConfig.baseUrl}$gambar',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain, // Menampilkan seluruh foto tanpa terpotong
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
                  item['nama'] ?? '-',
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
          Text('SKU: ${item['sku'] ?? '-'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontFamily: 'monospace')),
          const SizedBox(height: 20),

          // Kartu ringkasan stok
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stok Saat Ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${item['stok_saat_ini'] ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white24),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stok Minimum', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('${item['stok_minimum'] ?? 0}',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Informasi Produk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 10),

          _baris(Icons.category_outlined, 'Kategori', (item['kategori'] != null && item['kategori'].toString().isNotEmpty) ? item['kategori'] : '-'),
          _baris(Icons.straighten_outlined, 'Satuan', (item['satuan'] != null && item['satuan'].toString().isNotEmpty) ? item['satuan'] : '-'),
          _baris(Icons.sell_outlined, 'Harga per Unit', _formatRupiah(item['harga'])),
          _baris(Icons.account_balance_wallet_outlined, 'Total Nilai Stok',
              _formatRupiah((num.tryParse(item['harga']?.toString() ?? '0') ?? 0) * (num.tryParse(item['stok_saat_ini']?.toString() ?? '0') ?? 0))),
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

  Widget _baris(IconData icon, String label, String value) {
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
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}