import 'package:flutter/material.dart';

class BantuanPage extends StatelessWidget {
  const BantuanPage({super.key});

  static const List<Map<String, String>> faq = [
    {'q': 'Bagaimana cara mencatat barang masuk/keluar?', 'a': 'Buka tab Items, tekan tombol "+", lalu pilih Scan Barcode atau Input Manual, masukkan jumlah dan jenis transaksi (masuk/keluar), lalu simpan.'},
    {'q': 'Kenapa SKU saya dibilang tidak ditemukan?', 'a': 'Pastikan SKU yang di-scan/ketik sudah terdaftar di Master Data oleh Manager. Coba refresh daftar produk di tab Items dengan menarik layar ke bawah.'},
    {'q': 'Apakah saya bisa mengedit atau menghapus produk?', 'a': 'Tidak. Mengubah atau menghapus data produk hanya bisa dilakukan Manager lewat web dashboard.'},
    {'q': 'Lupa password, bagaimana solusinya?', 'a': 'Fitur reset password mandiri untuk akun Staf belum tersedia. Hubungi Manager gudang kamu untuk dibantu reset.'},
    {'q': 'Kenapa aplikasi mobile ini tidak bisa menambah produk baru?', 'a': 'Karena aplikasi mobile memang khusus untuk pencatatan transaksi oleh Staf. Penambahan produk baru dilakukan Manager lewat web dashboard.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Bantuan')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: faq.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = faq[index];
          return Container(
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(item['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(item['a']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))],
            ),
          );
        },
      ),
    );
  }
}