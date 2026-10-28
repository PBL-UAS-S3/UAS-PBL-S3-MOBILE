import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/baris_produk.dart';
import '../products/produk_detail_page.dart';

class SearchTab extends StatefulWidget {
  final List products;
  final VoidCallback onScanTap;
  final VoidCallback? onInputManualTap;

  const SearchTab({
    super.key,
    required this.products,
    required this.onScanTap,
    this.onInputManualTap,
  });

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final queryController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  void _bukaDetail(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProdukDetailPage(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final hasil = q.isEmpty
        ? []
        : widget.products.where((p) {
            final nama = (p['nama'] ?? '').toString().toLowerCase();
            final sku = (p['sku'] ?? '').toString().toLowerCase();
            final kategori = (p['kategori'] ?? '').toString().toLowerCase();
            return nama.contains(q) || sku.contains(q) || kategori.contains(q);
          }).toList();

    return ColoredBox(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 14),
            child: Text(
              'Cari',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: queryController,
              onChanged: (v) => setState(() => query = v),
              style: const TextStyle(fontSize: 15, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Cari nama, SKU, atau kategori',
                hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textGrey),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                        onPressed: () {
                          queryController.clear();
                          setState(() => query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (q.isEmpty) ..._tampilanAwal() else ..._tampilanHasil(hasil),
        ],
      ),
    );
  }

  List<Widget> _tampilanAwal() {
    final daftarKategori = widget.products
        .map((p) => (p['kategori'] ?? '').toString())
        .where((k) => k.isNotEmpty)
        .toSet()
        .take(8)
        .toList();
    final produkTerbaru = widget.products.take(6).toList();

    return [
      // Aksi cepat
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
            _barisAksi(
              Icons.qr_code_scanner,
              'Scan barcode',
              'Arahkan kamera ke barcode SKU',
              widget.onScanTap,
            ),
            if (widget.onInputManualTap != null) ...[
              Divider(height: 1, indent: 54, color: AppColors.border),
              _barisAksi(
                Icons.keyboard_outlined,
                'Input SKU manual',
                'Ketik SKU untuk mencatat transaksi',
                widget.onInputManualTap!,
              ),
            ],
          ],
        ),
      ),

      if (daftarKategori.isNotEmpty) ...[
        _judulSeksi('Kategori'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: daftarKategori.map((k) {
              return GestureDetector(
                onTap: () {
                  queryController.text = k;
                  setState(() => query = k);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    k,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],

      _judulSeksi('Produk terbaru'),
      if (produkTerbaru.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              'Belum ada produk di gudang.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
            ),
          ),
        )
      else
        DaftarProduk(produk: produkTerbaru, onTap: _bukaDetail),
    ];
  }

  List<Widget> _tampilanHasil(List hasil) {
    if (hasil.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 44, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Tidak ada hasil untuk "$query"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Coba kata kunci lain atau scan barcode.',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          '${hasil.length} hasil',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
        ),
      ),
      DaftarProduk(produk: hasil, onTap: _bukaDetail),
    ];
  }

  Widget _judulSeksi(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _barisAksi(IconData ikon, String judul, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(ikon, size: 22, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}