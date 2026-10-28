import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class StatusGudang {
  final String status; // belum | menunggu | aktif
  final String? namaGudang;
  final String? error;

  const StatusGudang({required this.status, this.namaGudang, this.error});

  bool get gagal => error != null;
  bool get aktif => status == 'aktif';
}

class AksiGudang {
  final bool ok;
  final String pesan;

  const AksiGudang(this.ok, this.pesan);
}

class GudangService {
  static Future<Map<String, String>> _header() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic>) return d;
    } catch (_) {}
    return {};
  }

  static Future<StatusGudang> ambilStatus() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/gudang/status'),
        headers: await _header(),
      );
      final data = _decode(res.body);

      if (res.statusCode == 200) {
        final gudang = data['gudang'];
        return StatusGudang(
          status: (data['status'] ?? 'belum').toString(),
          namaGudang: gudang is Map ? gudang['nama_gudang']?.toString() : null,
        );
      }
      return StatusGudang(
        status: 'belum',
        error: (data['error'] ?? 'Gagal memuat status gudang').toString(),
      );
    } catch (e) {
      return StatusGudang(
        status: 'belum',
        error: 'Gagal terhubung ke server (${ApiConfig.baseUrl})',
      );
    }
  }

  static Future<AksiGudang> _kirim(String path, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$path'),
        headers: await _header(),
        body: jsonEncode(body),
      );
      final data = _decode(res.body);
      if (res.statusCode == 200) {
        return AksiGudang(true, (data['message'] ?? 'Berhasil').toString());
      }
      return AksiGudang(
        false,
        (data['error'] ?? 'Terjadi kesalahan (kode ${res.statusCode})').toString(),
      );
    } catch (e) {
      return AksiGudang(false, 'Gagal terhubung ke server (${ApiConfig.baseUrl})');
    }
  }

  static Future<AksiGudang> gabung(String kodeGudang) =>
      _kirim('/gudang/gabung', {'kode_gudang': kodeGudang});

  // dipakai untuk membatalkan permintaan maupun keluar dari gudang
  static Future<AksiGudang> keluar() => _kirim('/gudang/keluar', {});
}