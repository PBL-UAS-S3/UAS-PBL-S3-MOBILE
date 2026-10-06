import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../theme/app_theme.dart';
import '../login_or_register_gate.dart';
import '../profil_staf_page.dart';
import '../riwayat_staf_page.dart';
import '../bantuan_page.dart';
import '../hubungi_kami_page.dart';
import '../ketentuan_page.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String nama = '';
  String email = '';

  String? namaGudang;
  String? alamatGudang;
  String? teleponGudang;
  double? latGudang;
  double? lonGudang;
  bool loadingAlamat = true;

  @override
  void initState() {
    super.initState();
    muatProfilRingkas();
    muatAlamatGudang();
  }

  Future<void> muatProfilRingkas() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => nama = prefs.getString('nama') ?? 'Staf');

    try {
      final token = prefs.getString('token');
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/profil'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => email = data['email'] ?? '');
      }
    } catch (e) {
      // biarkan kosong jika gagal
    }
  }

  Future<void> muatAlamatGudang() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/pengaturan'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          namaGudang = data['nama_gudang'];
          alamatGudang = data['alamat'];
          teleponGudang = data['telepon'];
          latGudang = data['latitude'] != null ? double.tryParse(data['latitude'].toString()) : null;
          lonGudang = data['longitude'] != null ? double.tryParse(data['longitude'].toString()) : null;
        });
      }
    } catch (e) {
      // biarkan kosong jika gagal
    }
    setState(() => loadingAlamat = false);
  }

  Future<void> bukaDiMaps() async {
    if (latGudang == null || lonGudang == null) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latGudang,$lonGudang');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String get inisial {
    if (nama.isEmpty) return '?';
    final kata = nama.trim().split(' ');
    if (kata.length == 1) return kata[0].substring(0, 1).toUpperCase();
    return (kata[0].substring(0, 1) + kata[1].substring(0, 1)).toUpperCase();
  }

  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar akun?'),
        content: const Text('Kamu perlu login lagi untuk mengakses aplikasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginOrRegisterGate()), (route) => false);
            },
            child: const Text('Keluar', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        const Text('Menu', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Profil & pengaturan akun', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        const SizedBox(height: 18),

        // Kartu profil — gradient oranye dengan pola dekoratif
        _KartuProfil(nama: nama, email: email, inisial: inisial),
        const SizedBox(height: 22),

        _labelSeksi('Gudang'),
        const SizedBox(height: 10),
        _KartuAlamatGudang(
          loading: loadingAlamat,
          namaGudang: namaGudang,
          alamatGudang: alamatGudang,
          teleponGudang: teleponGudang,
          adaKoordinat: latGudang != null && lonGudang != null,
          onBukaMaps: bukaDiMaps,
        ),
        const SizedBox(height: 22),

        _labelSeksi('Akun'),
        const SizedBox(height: 10),
        _menuRow(Icons.person_outline, const Color(0xFF2563EB), 'Profil Saya', 'Ubah nama, telepon, dan password', () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilStafPage()));
          muatProfilRingkas();
        }),
        _menuRow(Icons.history, const Color(0xFF7C3AED), 'Riwayat Transaksi', 'Lihat catatan transaksi gudang', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const RiwayatStafPage()));
        }),
        const SizedBox(height: 16),

        _labelSeksi('Bantuan'),
        const SizedBox(height: 10),
        _menuRow(Icons.help_outline, const Color(0xFF0D9488), 'Pusat Bantuan (FAQ)', 'Panduan dan solusi masalah umum', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const BantuanPage()));
        }),
        _menuRow(Icons.mail_outline, const Color(0xFF0D9488), 'Hubungi Kami', 'Laporkan kendala atau bug', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const HubungiKamiPage()));
        }),
        _menuRow(Icons.description_outlined, const Color(0xFF0D9488), 'Ketentuan & Kebijakan', 'Privasi dan syarat layanan', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const KetentuanPage()));
        }),
        const SizedBox(height: 16),

        _labelSeksi('Lainnya'),
        const SizedBox(height: 10),
        _menuRow(Icons.dns_outlined, AppColors.textGrey, 'Ubah URL Server', ApiConfig.baseUrl, () {
          showServerConfigDialog(context, onSaved: () => setState(() {}));
        }),
        const SizedBox(height: 18),

        GestureDetector(
          onTap: logout,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.danger.withOpacity(0.15)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: AppColors.danger, size: 18),
                SizedBox(width: 8),
                Text('Logout', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _labelSeksi(String label) {
    return Text(label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 0.6));
  }

  Widget _menuRow(IconData icon, Color warna, String label, String sub, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: warna.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: warna, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// KARTU PROFIL — gradient oranye + pola kardus dekoratif
// ========================================================================

class _KartuProfil extends StatelessWidget {
  final String nama;
  final String email;
  final String inisial;

  const _KartuProfil({required this.nama, required this.email, required this.inisial});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(Icons.inventory_2, size: 110, color: Colors.white.withOpacity(0.12)),
          ),
          Positioned(
            right: 40,
            bottom: -24,
            child: Icon(Icons.inventory_2, size: 60, color: Colors.white.withOpacity(0.10)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
                  ),
                  child: Center(
                    child: Text(inisial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nama.isEmpty ? 'Staf Gudang' : nama,
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Staf Gudang', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(email, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// KARTU ALAMAT GUDANG
// ========================================================================

class _KartuAlamatGudang extends StatelessWidget {
  final bool loading;
  final String? namaGudang;
  final String? alamatGudang;
  final String? teleponGudang;
  final bool adaKoordinat;
  final VoidCallback onBukaMaps;

  const _KartuAlamatGudang({
    required this.loading,
    required this.namaGudang,
    required this.alamatGudang,
    required this.teleponGudang,
    required this.adaKoordinat,
    required this.onBukaMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: loading
          ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.location_on, color: AppColors.primary, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        namaGudang != null && namaGudang!.isNotEmpty ? namaGudang! : 'Alamat Gudang',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  (alamatGudang != null && alamatGudang!.isNotEmpty) ? alamatGudang! : 'Alamat belum diatur oleh Manager.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, height: 1.4),
                ),
                if (teleponGudang != null && teleponGudang!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.call_outlined, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 5),
                      Text(teleponGudang!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    ],
                  ),
                ],
                if (adaKoordinat) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onBukaMaps,
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: const Text('Buka di Google Maps', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primarySoft,
                        foregroundColor: AppColors.primaryDarkText,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}