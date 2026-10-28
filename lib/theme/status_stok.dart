import 'package:flutter/material.dart';

/// Status stok layak sebuah produk.
enum StatusStok { habis, menipis, aman }

/// Label dan warna untuk satu jenis status.
/// Semua halaman memakai file ini supaya warnanya selalu sama.
class TampilanStatus {
  final String label;
  final Color warnaTeks;
  final Color latar;
  final Color garis;

  const TampilanStatus(this.label, this.warnaTeks, this.latar, this.garis);
}

const TampilanStatus tampilanHabis = TampilanStatus(
  'Habis',
  Color(0xFFB91C1C),
  Color(0xFFFEE2E2),
  Color(0xFFFCA5A5),
);

const TampilanStatus tampilanMenipis = TampilanStatus(
  'Menipis',
  Color(0xFFB45309),
  Color(0xFFFEF3C7),
  Color(0xFFFCD34D),
);

const TampilanStatus tampilanAman = TampilanStatus(
  'Aman',
  Color(0xFF15803D),
  Color(0xFFDCFCE7),
  Color(0xFF86EFAC),
);

const TampilanStatus tampilanRusak = TampilanStatus(
  'Rusak',
  Color(0xFF6D28D9),
  Color(0xFFEDE9FE),
  Color(0xFFC4B5FD),
);

int ambilInt(dynamic nilai) {
  if (nilai is int) return nilai;
  return int.tryParse(nilai?.toString() ?? '0') ?? 0;
}

/// Habis: stok layak 0. Menipis: stok layak <= batas minimum. Selain itu Aman.
StatusStok hitungStatusStok(Map item) {
  final stok = ambilInt(item['stok_saat_ini']);
  final minimum = ambilInt(item['stok_minimum']);
  if (stok <= 0) return StatusStok.habis;
  if (stok <= minimum) return StatusStok.menipis;
  return StatusStok.aman;
}

TampilanStatus tampilanStatus(StatusStok status) {
  switch (status) {
    case StatusStok.habis:
      return tampilanHabis;
    case StatusStok.menipis:
      return tampilanMenipis;
    case StatusStok.aman:
      return tampilanAman;
  }
}

/// Jumlah unit barang rusak (kolom stok_rusak, 0 kalau belum ada)
int stokRusakDari(Map item) => ambilInt(item['stok_rusak']);

/// Lencana kecil berwarna untuk status (Aman, Menipis, Habis, Rusak)
class LencanaStatus extends StatelessWidget {
  final TampilanStatus tampilan;
  final String? label;
  final double ukuranFont;
  final EdgeInsets padding;

  const LencanaStatus(
    this.tampilan, {
    super.key,
    this.label,
    this.ukuranFont = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tampilan.latar,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label ?? tampilan.label,
        style: TextStyle(
          fontSize: ukuranFont,
          fontWeight: FontWeight.w700,
          color: tampilan.warnaTeks,
        ),
      ),
    );
  }
}