import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';

class TransaksiPage extends StatefulWidget {
  final String sku;
  final String tipeAwal;

  const TransaksiPage({
    super.key,
    required this.sku,
    this.tipeAwal = 'in',
  });

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  late String tipe;
  final jumlahController = TextEditingController();
  final catatanController = TextEditingController();
  String pesan = '';
  bool loading = false;
  Map<String, dynamic>? detailProduk;

  @override
  void initState() {
    super.initState();
    tipe = widget.tipeAwal;
    _muatDetail();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> _muatDetail() async {
    final res = await ProductService.cariDetailProduk(widget.sku);
    if (mounted && res != null) {
      setState(() => detailProduk = res);
    }
  }

  Future<void> kirimTransaksi() async {
    final jml = int.tryParse(jumlahController.text.trim()) ?? 0;
    if (jml <= 0) {
      setState(() => pesan = 'Jumlah harus lebih besar dari 0');
      return;
    }

    setState(() {
      loading = true;
      pesan = '';
    });

    final res = await ProductService.catatTransaksi(
      sku: widget.sku,
      tipe: tipe,
      jumlah: jml,
      catatan: catatanController.text.trim().isNotEmpty ? catatanController.text.trim() : null,
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (res['success'] == true) {
      final info = tipe == 'rusak'
          ? 'Berhasil! Dipisahkan ke Barang Rusak.'
          : 'Berhasil! Stok baru: ${res['stok_baru']}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.primaryDark, content: Text(info)),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => pesan = res['error'] ?? 'Gagal menyimpan transaksi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stokLayak = detailProduk?['stok_saat_ini'] ?? '-';
    final stokRusak = detailProduk?['stok_rusak'] ?? '0';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('SKU: ${widget.sku}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info produk ringkas
            if (detailProduk != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.inventory_2, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detailProduk!['nama'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text('Stok Layak: $stokLayak • Stok Rusak: $stokRusak',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text('Jenis Transaksi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),

            // Pilihan tipe: Masuk, Keluar, Pisah Barang Rusak
            Row(
              children: [
                _tipeCard('in', 'Masuk', Icons.arrow_downward, Colors.green),
                const SizedBox(width: 8),
                _tipeCard('out', 'Keluar', Icons.arrow_upward, Colors.blue),
                const SizedBox(width: 8),
                _tipeCard('rusak', 'Barang Rusak', Icons.build_circle_outlined, Colors.red),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              tipe == 'rusak' ? 'Jumlah yang Dipisahkan ke Rusak' : 'Jumlah Unit',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan jumlah unit',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Catatan / Keterangan (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: catatanController,
              decoration: InputDecoration(
                hintText: tipe == 'rusak' ? 'Contoh: Kemasan robek saat bongkar muat' : 'Catatan transaksi...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 20),

            if (pesan.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.dangerBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(pesan, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : kirimTransaksi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: tipe == 'rusak' ? Colors.red.shade600 : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        tipe == 'rusak' ? 'Simpan Pemisahan Barang Rusak' : 'Simpan Transaksi',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipeCard(String val, String label, IconData icon, Color color) {
    final selected = tipe == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tipe = val),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : Colors.grey.shade500, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: selected ? color : Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
