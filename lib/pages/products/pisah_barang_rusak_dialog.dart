import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';

class PisahBarangRusakDialog extends StatefulWidget {
  final Map item;
  final VoidCallback? onSuccess;

  const PisahBarangRusakDialog({
    super.key,
    required this.item,
    this.onSuccess,
  });

  static Future<bool?> show(BuildContext context, {required Map item, VoidCallback? onSuccess}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PisahBarangRusakDialog(item: item, onSuccess: onSuccess),
    );
  }

  @override
  State<PisahBarangRusakDialog> createState() => _PisahBarangRusakDialogState();
}

class _PisahBarangRusakDialogState extends State<PisahBarangRusakDialog> {
  final jumlahController = TextEditingController();
  final alasanController = TextEditingController();
  final catatanController = TextEditingController();

  bool loading = false;
  String pesanError = '';

  @override
  void dispose() {
    jumlahController.dispose();
    alasanController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  int get stokLayak {
    final s = widget.item['stok_saat_ini'];
    return s is int ? s : int.tryParse(s?.toString() ?? '0') ?? 0;
  }

  int get stokRusak {
    final s = widget.item['stok_rusak'];
    return s is int ? s : int.tryParse(s?.toString() ?? '0') ?? 0;
  }

  Future<void> submitPemisahan() async {
    final jumlah = int.tryParse(jumlahController.text.trim()) ?? 0;
    if (jumlah <= 0) {
      setState(() => pesanError = 'Jumlah barang rusak minimal 1');
      return;
    }

    if (jumlah > stokLayak) {
      setState(() => pesanError = 'Jumlah melebihi stok layak saat ini ($stokLayak)');
      return;
    }

    final alasan = alasanController.text.trim();
    if (alasan.isEmpty) {
      setState(() => pesanError = 'Alasan kerusakan wajib diisi');
      return;
    }

    setState(() {
      loading = true;
      pesanError = '';
    });

    final sku = widget.item['sku']?.toString() ?? '';
    final res = await ProductService.pisahkanBarangRusak(
      sku: sku,
      jumlah: jumlah,
      alasan: alasan,
      keterangan: catatanController.text.trim(),
    );

    if (!mounted) return;
    setState(() => loading = false);

    if (res['success'] == true) {
      if (widget.onSuccess != null) widget.onSuccess!();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryDark,
          content: Text(
            'Berhasil memisahkan $jumlah unit ke Barang Rusak!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    } else {
      setState(() => pesanError = res['error'] ?? 'Gagal memisahkan barang rusak');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboardHeight + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.build_circle_outlined, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemisahan Barang Rusak',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        'Sortir barang cacat/rusak dari stok layak',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Info ringkasan barang
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['nama'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${widget.item['sku'] ?? '-'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Layak: $stokLayak',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                      ),
                      Text(
                        'Rusak: $stokRusak',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'Jumlah Barang Rusak yang Dipisahkan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Contoh: 5 (Maksimal: $stokLayak)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixText: widget.item['satuan'] ?? 'Unit',
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Alasan Kerusakan / Kondisi',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: alasanController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis kenapa barang ini rusak',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Catatan Tambahan (Opsional)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: catatanController,
              decoration: InputDecoration(
                hintText: 'Misal: Ditemukan saat pengecekan rak C-02',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            if (pesanError.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pesanError,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loading ? null : submitPemisahan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.call_split, size: 20),
                label: Text(
                  loading ? 'Memproses...' : 'Pisahkan ke Barang Rusak',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}