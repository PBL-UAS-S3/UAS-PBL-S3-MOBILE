import 'package:flutter/material.dart';

class KetentuanPage extends StatefulWidget {
  const KetentuanPage({super.key});

  @override
  State<KetentuanPage> createState() => _KetentuanPageState();
}

class _KetentuanPageState extends State<KetentuanPage> {
  bool tabPrivasi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ketentuan & Kebijakan')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: ChoiceChip(label: const Text('Kebijakan Privasi'), selected: tabPrivasi, onSelected: (v) => setState(() => tabPrivasi = true))),
                const SizedBox(width: 8),
                Expanded(child: ChoiceChip(label: const Text('Syarat Ketentuan'), selected: !tabPrivasi, onSelected: (v) => setState(() => tabPrivasi = false))),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  tabPrivasi
                      ? '1. Data yang Dikumpulkan.\nStockin menyimpan data akun (nama, email, nomor telepon), data produk, dan riwayat transaksi gudang yang kamu masukkan ke dalam sistem.\n\n'
                        '2. Penggunaan Data.\nData digunakan untuk menjalankan fitur aplikasi, termasuk analisis AI Insight untuk rekomendasi restock. Data tidak dibagikan ke pihak ketiga di luar kebutuhan sistem (seperti Gemini API untuk analisis AI).\n\n'
                        '3. Keamanan Data.\nPassword disimpan dalam bentuk terenkripsi (hash), dan akses ke data dibatasi berdasarkan peran (Manager/Staf).\n\n'
                        '4. Perubahan Kebijakan.\nKebijakan ini dapat berubah sewaktu-waktu sesuai kebutuhan pengembangan aplikasi.'
                      : '1. Penggunaan Layanan.\nAplikasi ini disediakan untuk membantu pengelolaan inventori gudang. Akun Manager bertanggung jawab atas keakuratan data yang dimasukkan.\n\n'
                        '2. Peran Pengguna.\nAkun Manager hanya dapat diakses lewat web, dan akun Staf Gudang hanya dapat diakses lewat aplikasi mobile.\n\n'
                        '3. Rekomendasi AI.\nRekomendasi restock dari AI bersifat saran berdasarkan data historis, keputusan akhir pembelian tetap berada di tangan Manager.\n\n'
                        '4. Batasan Tanggung Jawab.\nPengembang tidak bertanggung jawab atas kerugian yang timbul dari kesalahan input data oleh pengguna.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}