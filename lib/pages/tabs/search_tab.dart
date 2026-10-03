import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

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

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Search', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: queryController,
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Search items or SKU...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              if (query.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Enter text or scan to start your search.', style: TextStyle(color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                )
              else if (hasil.isEmpty)
                Expanded(child: Center(child: Text('Tidak ditemukan.', style: TextStyle(color: Colors.grey.shade400))))
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: hasil.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = hasil[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('SKU: ${item['sku'] ?? '-'}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('${item['stok_saat_ini'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
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
}