import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';

class RiwayatStafPage extends StatefulWidget {
  const RiwayatStafPage({super.key});

  @override
  State<RiwayatStafPage> createState() => _RiwayatStafPageState();
}

class _RiwayatStafPageState extends State<RiwayatStafPage> {
  List riwayat = [];
  bool loading = true;
  String filterTipe = 'all';

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/transactions/recent'));
      if (response.statusCode == 200) {
        setState(() => riwayat = jsonDecode(response.body));
      }
    } catch (_) {}
    setState(() => loading = false);
  }

  List get riwayatTersaring {
    if (filterTipe == 'all') return riwayat;
    return riwayat.where((t) => (t['tipe'] ?? '') == filterTipe).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRiwayat,
            tooltip: 'Segarkan',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _filterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _filterChip('Masuk', 'in'),
                const SizedBox(width: 8),
                _filterChip('Keluar', 'out'),
                const SizedBox(width: 8),
                _filterChip('Barang Rusak', 'rusak'),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : riwayatTersaring.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada transaksi.',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchRiwayat,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: riwayatTersaring.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final t = riwayatTersaring[index];
                            final tipe = t['tipe']?.toString() ?? '';
                            final catatan = t['catatan']?.toString();

                            Color warna;
                            IconData ikon;
                            String labelTipe;

                            switch (tipe) {
                              case 'in':
                                warna = AppColors.success;
                                ikon = Icons.arrow_downward;
                                labelTipe = 'Masuk';
                                break;
                              case 'out':
                                warna = const Color(0xFF2563EB);
                                ikon = Icons.arrow_upward;
                                labelTipe = 'Keluar';
                                break;
                              case 'rusak':
                                warna = Colors.red.shade700;
                                ikon = Icons.build_circle_outlined;
                                labelTipe = 'Pemisahan Rusak';
                                break;
                              case 'buang_rusak':
                                warna = Colors.red.shade900;
                                ikon = Icons.delete_outline;
                                labelTipe = 'Afkir Rusak';
                                break;
                              case 'pulih_rusak':
                                warna = Colors.teal;
                                ikon = Icons.restore_from_trash_outlined;
                                labelTipe = 'Pemulihan Rusak';
                                break;
                              default:
                                warna = AppColors.textGrey;
                                ikon = Icons.swap_horiz;
                                labelTipe = tipe;
                            }

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: warna.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(ikon, color: warna, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['nama'] ?? '-',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${t['sku'] ?? '-'} • Oleh: ${t['nama_staf'] ?? '-'}',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                                        ),
                                        if (catatan != null && catatan.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              catatan,
                                              style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${t['jumlah'] ?? 0} unit',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: warna.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          labelTipe,
                                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: warna),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final aktif = filterTipe == value;
    return GestureDetector(
      onTap: () => setState(() => filterTipe = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: aktif ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: aktif ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: aktif ? Colors.white : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}
