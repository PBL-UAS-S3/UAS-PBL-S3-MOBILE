import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../theme/status_stok.dart';

String formatRp(dynamic angka) {
  final nilai = num.tryParse(angka?.toString() ?? '0') ?? 0;
  final bagian = nilai.toInt().toString().split('').reversed.toList();
  final hasil = <String>[];
  for (int i = 0; i < bagian.length; i++) {
    if (i != 0 && i % 3 == 0) hasil.add('.');
    hasil.add(bagian[i]);
  }
  return 'Rp${hasil.reversed.join()}';
}

String namaStatusStok(StatusStok s) {
  switch (s) {
    case StatusStok.habis:
      return 'Habis';
    case StatusStok.menipis:
      return 'Menipis';
    default:
      return 'Aman';
  }
}

/// Satu baris produk: thumbnail, nama, info, stok di kanan
class BarisProduk extends StatelessWidget {
  final Map item;
  final VoidCallback onTap;

  const BarisProduk({super.key, required this.item, required this.onTap});

  Widget _placeholder() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey.shade100,
      child: Icon(Icons.inventory_2_outlined,
          color: Colors.grey.shade400, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = hitungStatusStok(item);
    final tampil = tampilanStatus(status);
    final stokRusak = stokRusakDari(item);
    final gambar = item['gambar'];
    final kategori =
        (item['kategori'] != null && item['kategori'].toString().isNotEmpty)
            ? item['kategori'].toString()
            : null;
    final satuan =
        (item['satuan'] != null && item['satuan'].toString().isNotEmpty)
            ? item['satuan'].toString()
            : null;
    final info = [
      item['sku']?.toString() ?? '-',
      if (kategori != null) kategori,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: gambar != null
                  ? Image.network(
                      '${ApiConfig.baseUrl}$gambar',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nama']?.toString() ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatRp(item['harga']),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['stok_saat_ini'] ?? 0}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: status == StatusStok.aman
                        ? AppColors.textDark
                        : tampil.warnaTeks,
                  ),
                ),
                if (satuan != null)
                  Text(
                    satuan,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textGrey),
                  ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tampil.warnaTeks,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      namaStatusStok(status),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tampil.warnaTeks,
                      ),
                    ),
                  ],
                ),
                if (stokRusak > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '$stokRusak rusak',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tampilanRusak.warnaTeks,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Kumpulan baris produk: putih, melebar penuh, dipisah garis tipis
class DaftarProduk extends StatelessWidget {
  final List produk;
  final void Function(Map item) onTap;

  const DaftarProduk({super.key, required this.produk, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          for (int i = 0; i < produk.length; i++) ...[
            BarisProduk(
              item: produk[i] as Map,
              onTap: () => onTap(produk[i] as Map),
            ),
            if (i != produk.length - 1)
              Divider(height: 1, indent: 76, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}