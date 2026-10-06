import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../produk_detail_page.dart';

class SearchTab extends StatefulWidget {
  final List products;
  final VoidCallback onScanTap;

  const SearchTab({super.key, required this.products, required this.onScanTap});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final queryController = TextEditingController();
  String query = '';

  bool _menipis(Map item) {
    final stok = item['stok_saat_ini'] ?? 0;
    final min = item['stok_minimum'] ?? 0;
    return stok <= min;
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
    final hasil = query.isEmpty
        ? []
        : widget.products.where((p) {
            final nama = (p['nama'] ?? '').toString().toLowerCase();
            final sku = (p['sku'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return nama.contains(q) || sku.contains(q);
          }).toList();

    final daftarKategori = widget.products
        .map((p) => (p['kategori'] ?? '').toString())
        .where((k) => k.isNotEmpty)
        .toSet()
        .take(6)
        .toList();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Search', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Cari produk berdasarkan nama atau SKU', style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5)),
              const SizedBox(height: 16),
              TextField(
                controller: queryController,
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Search items or SKU...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            queryController.clear();
                            setState(() => query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),

              Expanded(
                child: query.isEmpty
                    ? _tampilanKosong(daftarKategori)
                    : hasil.isEmpty
                        ? _tidakDitemukan()
                        : _daftarHasil(hasil),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            heroTag: 'scan-search',
            backgroundColor: AppColors.primary,
            onPressed: widget.onScanTap,
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tampilan sebelum mengetik: kategori cepat + produk terbaru
  // ---------------------------------------------------------------------
  Widget _tampilanKosong(List<String> daftarKategori) {
    final produkTerbaru = widget.products.take(6).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        // Ajakan scan
        GestureDetector(
          onTap: widget.onScanTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Scan barcode produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                      SizedBox(height: 2),
                      Text('Lebih cepat dari ketik manual', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        if (daftarKategori.isNotEmpty) ...[
          const Text('Cari Cepat per Kategori', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: daftarKategori.map((k) {
              return GestureDetector(
                onTap: () {
                  queryController.text = k;
                  setState(() => query = k);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Text(k, style: const TextStyle(color: AppColors.primaryDarkText, fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        if (produkTerbaru.isNotEmpty) ...[
          const Text('Produk Terbaru', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark)),
          const SizedBox(height: 10),
          ...produkTerbaru.map((item) => _kartuProduk(item)),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('Belum ada produk di gudang.', style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tidakDitemukan() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.search_off, size: 32, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 14),
          Text('Tidak ditemukan untuk "$query"', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Coba kata kunci lain atau scan barcode', style: TextStyle(color: Colors.grey.shade400, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _daftarHasil(List hasil) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: hasil.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _kartuProduk(hasil[index]),
    );
  }

  Widget _kartuProduk(Map item) {
    final menipis = _menipis(item);
    final gambar = item['gambar'];
    final kategori = (item['kategori'] != null && item['kategori'].toString().isNotEmpty) ? item['kategori'].toString() : null;
    final satuan = (item['satuan'] != null && item['satuan'].toString().isNotEmpty) ? item['satuan'].toString() : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProdukDetailPage(item: item))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
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
                      errorBuilder: (context, error, stackTrace) => _placeholderThumb(),
                    )
                  : _placeholderThumb(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('SKU: ${item['sku'] ?? '-'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  if (kategori != null || satuan != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (kategori != null) _tagKecil(kategori, AppColors.primarySoft, AppColors.primaryDarkText),
                        if (satuan != null) _tagKecil(satuan, Colors.grey.shade100, AppColors.textGrey),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(_formatRupiah(item['harga']), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item['stok_saat_ini'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: menipis ? AppColors.dangerBg : AppColors.successBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    menipis ? 'Menipis' : 'Aman',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: menipis ? AppColors.danger : AppColors.success),
                  ),
                ),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
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