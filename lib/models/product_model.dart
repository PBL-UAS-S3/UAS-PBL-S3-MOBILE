class ProductModel {
  final int id;
  final String sku;
  final String nama;
  final String? kategori;
  final String? satuan;
  final num harga;
  final String? gambar;
  final int stokSaatIni; // Stok layak pakai
  final int stokRusak; // Stok rusak yang sudah tersortir
  final int stokMinimum;

  const ProductModel({
    required this.id,
    required this.sku,
    required this.nama,
    this.kategori,
    this.satuan,
    this.harga = 0,
    this.gambar,
    this.stokSaatIni = 0,
    this.stokRusak = 0,
    this.stokMinimum = 0,
  });

  int get totalStokFisik => stokSaatIni + stokRusak;

  bool get isMenipis => stokSaatIni <= stokMinimum;

  bool get isPerluDipantau => !isMenipis && stokSaatIni <= (stokMinimum * 1.5);

  bool get hasBarangRusak => stokRusak > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      sku: json['sku']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      kategori: json['kategori']?.toString(),
      satuan: json['satuan']?.toString(),
      harga: num.tryParse(json['harga']?.toString() ?? '0') ?? 0,
      gambar: json['gambar']?.toString(),
      stokSaatIni: json['stok_saat_ini'] is int
          ? json['stok_saat_ini']
          : int.tryParse(json['stok_saat_ini']?.toString() ?? '0') ?? 0,
      stokRusak: json['stok_rusak'] is int
          ? json['stok_rusak']
          : int.tryParse(json['stok_rusak']?.toString() ?? '0') ?? 0,
      stokMinimum: json['stok_minimum'] is int
          ? json['stok_minimum']
          : int.tryParse(json['stok_minimum']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sku': sku,
      'nama': nama,
      'kategori': kategori,
      'satuan': satuan,
      'harga': harga,
      'gambar': gambar,
      'stok_saat_ini': stokSaatIni,
      'stok_rusak': stokRusak,
      'stok_minimum': stokMinimum,
    };
  }
}
