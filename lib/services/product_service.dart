import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ProductService {
  /// Mengambil semua produk dari server
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'));
      if (response.statusCode == 200) {
        final List decoded = jsonDecode(response.body);
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// Mencari SKU yang valid di daftar produk
  static Future<String?> cariProdukValid(String skuInput) async {
    try {
      final produk = await fetchProducts();
      final skuDicari = skuInput.trim().toUpperCase();

      for (final p in produk) {
        if ((p['sku'] ?? '').toString().toUpperCase() == skuDicari) {
          return p['sku'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mengambil detail satu produk berdasarkan SKU
  static Future<Map<String, dynamic>?> cariDetailProduk(String skuInput) async {
    try {
      final produk = await fetchProducts();
      final skuDicari = skuInput.trim().toUpperCase();

      for (final p in produk) {
        if ((p['sku'] ?? '').toString().toUpperCase() == skuDicari) {
          return p;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Mencatat transaksi stok umum (in, out, rusak, buang_rusak, pulih_rusak)
  static Future<Map<String, dynamic>> catatTransaksi({
    required String sku,
    required String tipe,
    required int jumlah,
    String? catatan,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sku': sku,
          'tipe': tipe,
          'jumlah': jumlah,
          'catatan': catatan,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Transaksi berhasil',
          'stok_baru': data['stok_baru'],
          'stok_rusak_baru': data['stok_rusak_baru'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Gagal memproses transaksi',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Gagal terhubung ke server: $e',
      };
    }
  }

  /// Fitur Khusus: Memisahkan barang rusak dari stok layak ke stok rusak
  static Future<Map<String, dynamic>> pisahkanBarangRusak({
    required String sku,
    required int jumlah,
    required String alasan,
    String? keterangan,
  }) async {
    final catatan = 'Pemisahan Rusak [$alasan]${(keterangan != null && keterangan.isNotEmpty) ? ' - $keterangan' : ''}';
    return catatTransaksi(
      sku: sku,
      tipe: 'rusak',
      jumlah: jumlah,
      catatan: catatan,
    );
  }

  /// Fitur Khusus: Buang atau Afkir barang rusak yang sudah tersortir
  static Future<Map<String, dynamic>> buangBarangRusak({
    required String sku,
    required int jumlah,
    String? keterangan,
  }) async {
    final catatan = 'Afkir/Buang Rusak${(keterangan != null && keterangan.isNotEmpty) ? ' - $keterangan' : ''}';
    return catatTransaksi(
      sku: sku,
      tipe: 'buang_rusak',
      jumlah: jumlah,
      catatan: catatan,
    );
  }

  /// Fitur Khusus: Pulihkan barang rusak yang sudah selesai diservis / diperbaiki
  static Future<Map<String, dynamic>> pulihkanBarangRusak({
    required String sku,
    required int jumlah,
    String? keterangan,
  }) async {
    final catatan = 'Pemulihan Rusak${(keterangan != null && keterangan.isNotEmpty) ? ' - $keterangan' : ''}';
    return catatTransaksi(
      sku: sku,
      tipe: 'pulih_rusak',
      jumlah: jumlah,
      catatan: catatan,
    );
  }
}
