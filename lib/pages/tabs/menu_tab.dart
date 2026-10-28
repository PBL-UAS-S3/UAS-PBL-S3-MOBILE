import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/api_config.dart';
import '../../services/gudang_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_or_register_gate.dart';
import '../gudang/gudang_saya_page.dart';
import '../info/bantuan_page.dart';
import '../info/hubungi_kami_page.dart';
import '../info/ketentuan_page.dart';
import '../products/barang_rusak_page.dart';
import '../profile/profil_staf_page.dart';
import '../transactions/riwayat_staf_page.dart';
import '../products/barang_rusak_page.dart';

class _Entri {
  final IconData ikon;
  final String judul;
  final String sub;
  final VoidCallback? onTap;
  final Color? warna;
  final String? lencana;
  final Color? warnaLencana;
  final Color? latarLencana;
  final bool panah;

  const _Entri({
    required this.ikon,
    required this.judul,
    this.sub = '',
    this.onTap,
    this.warna,
    this.lencana,
    this.warnaLencana,
    this.latarLencana,
    this.panah = true,
  });
}

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  final cariController = TextEditingController();
  String kata = '';

  String nama = '';
  String email = '';

  StatusGudang? statusGudang;

  String? namaGudang;
  String? alamatGudang;
  double? latGudang;
  double? lonGudang;

  @override
  void initState() {
    super.initState();
    muatProfilRingkas();
    muatStatusGudang();
    muatAlamatGudang();
  }

  @override
  void dispose() {
    cariController.dispose();
    super.dispose();
  }

  Future<void> muatProfilRingkas() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => nama = prefs.getString('nama') ?? 'Staf');

    try {
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profil'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() => email = data['email'] ?? '');
      }
    } catch (e) {
      // biarkan kosong jika gagal
    }
  }

  Future<void> muatStatusGudang() async {
    final s = await GudangService.ambilStatus();
    if (!mounted) return;
    setState(() => statusGudang = s);
  }

  Future<void> muatAlamatGudang() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/pengaturan'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          namaGudang = data['nama_gudang'];
          alamatGudang = data['alamat'];
          latGudang = data['latitude'] != null
              ? double.tryParse(data['latitude'].toString())
              : null;
          lonGudang = data['longitude'] != null
              ? double.tryParse(data['longitude'].toString())
              : null;
        });
      }
    } catch (e) {
      // biarkan kosong jika gagal
    }
  }

  Future<void> bukaDiMaps() async {
    if (latGudang == null || lonGudang == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latGudang,$lonGudang');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> bukaGudangSaya() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GudangSayaPage()),
    );
    muatStatusGudang();
    muatAlamatGudang();
  }

  Future<void> bukaProfil() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilStafPage()),
    );
    muatProfilRingkas();
  }

  void buka(Widget halaman) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => halaman));
  }

  String get inisial {
    if (nama.isEmpty) return '?';
    final kataNama = nama.trim().split(' ');
    if (kataNama.length == 1) return kataNama[0].substring(0, 1).toUpperCase();
    return (kataNama[0].substring(0, 1) + kataNama[1].substring(0, 1))
        .toUpperCase();
  }

  Future<void> logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar akun?'),
        content: const Text('Kamu perlu login lagi untuk mengakses aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoginOrRegisterGate()),
                (route) => false,
              );
            },
            child: const Text(
              'Keluar',
              style: TextStyle(
                  color: AppColors.danger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<List<_Entri>> _susunGrup() {
    final s = statusGudang;
    final aktif = s != null && s.aktif;
    final adaKoordinat = latGudang != null && lonGudang != null;
    final punyaAlamat = alamatGudang != null && alamatGudang!.isNotEmpty;

    String subGudang;
    String? lencana;
    Color? warnaLencana;
    Color? latarLencana;

    if (s == null) {
      subGudang = 'Memuat...';
    } else if (s.gagal) {
      subGudang = 'Status gudang tidak bisa dimuat';
    } else if (s.status == 'aktif') {
      subGudang = (s.namaGudang != null && s.namaGudang!.isNotEmpty)
          ? s.namaGudang!
          : 'Tergabung';
    } else if (s.status == 'menunggu') {
      subGudang = 'Menunggu persetujuan Manager';
      lencana = 'MENUNGGU';
      warnaLencana = AppColors.warning;
      latarLencana = AppColors.warningBg;
    } else {
      subGudang = 'Masukkan kode gudang dari Manager';
      lencana = 'GABUNG';
      warnaLencana = Colors.white;
      latarLencana = const Color(0xFFE11D48);
    }

    return [
      [
        _Entri(
          ikon: Icons.warehouse_outlined,
          judul: 'Gudang Saya',
          sub: subGudang,
          onTap: bukaGudangSaya,
          lencana: lencana,
          warnaLencana: warnaLencana,
          latarLencana: latarLencana,
        ),
        if (aktif)
          _Entri(
            ikon: Icons.location_on_outlined,
            judul: 'Alamat Gudang',
            sub: punyaAlamat ? alamatGudang! : 'Alamat belum diatur oleh Manager',
            onTap: adaKoordinat ? bukaDiMaps : null,
            panah: adaKoordinat,
          ),    
      ],
      [
        _Entri(
          ikon: Icons.person_outline,
          judul: 'Profil Saya',
          onTap: bukaProfil,
        ),
        _Entri(
          ikon: Icons.history,
          judul: 'Riwayat Transaksi',
          onTap: () => buka(const RiwayatStafPage()),
        ),
      ],
      [
        _Entri(
          ikon: Icons.help_outline,
          judul: 'Pusat Bantuan',
          onTap: () => buka(const BantuanPage()),
        ),
        _Entri(
          ikon: Icons.mail_outline,
          judul: 'Hubungi Kami',
          onTap: () => buka(const HubungiKamiPage()),
        ),
        _Entri(
          ikon: Icons.description_outlined,
          judul: 'Ketentuan & Kebijakan',
          onTap: () => buka(const KetentuanPage()),
        ),
      ],
      [
        _Entri(
          ikon: Icons.dns_outlined,
          judul: 'Ubah URL Server',
          sub: ApiConfig.baseUrl,
          onTap: () {
            showServerConfigDialog(context, onSaved: () => setState(() {}));
          },
        ),
      ],
      [
        _Entri(
          ikon: Icons.logout,
          judul: 'Keluar',
          onTap: logout,
          warna: AppColors.danger,
          panah: false,
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final q = kata.trim().toLowerCase();
    var grup = _susunGrup();

    if (q.isNotEmpty) {
      final cocok = grup
          .expand((g) => g)
          .where((e) =>
              e.judul.toLowerCase().contains(q) ||
              e.sub.toLowerCase().contains(q))
          .toList();
      grup = cocok.isEmpty ? [] : [cocok];
    }

    return ColoredBox(
      color: AppColors.bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Text(
              'Menu',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Kolom cari menu
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: _bayangan,
            ),
            child: TextField(
              controller: cariController,
              onChanged: (v) => setState(() => kata = v),
              style: const TextStyle(fontSize: 15.5, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Cari menu',
                hintStyle:
                    const TextStyle(color: AppColors.textGrey, fontSize: 15.5),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textGrey, size: 22),
                suffixIcon: kata.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.textGrey),
                        onPressed: () {
                          cariController.clear();
                          setState(() => kata = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          if (q.isEmpty) _kartuProfil(),

          if (grup.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Tidak ada menu yang cocok.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                ),
              ),
            )
          else
            for (final g in grup) _kartu(g),
        ],
      ),
    );
  }

  static final List<BoxShadow> _bayangan = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 3),
    ),
  ];

  Widget _kartuProfil() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _bayangan,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: bukaProfil,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE2E8F0),
                    child: Text(
                      inisial,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama.isEmpty ? 'Staf Gudang' : nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.textGrey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Satu kartu berisi beberapa baris, sudut sangat bulat, divider menjorok
  Widget _kartu(List<_Entri> baris) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: _bayangan,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              for (int i = 0; i < baris.length; i++) ...[
                _baris(baris[i]),
                if (i != baris.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 60,
                    endIndent: 18,
                    color: AppColors.border,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _baris(_Entri e) {
    final warna = e.warna ?? AppColors.textDark;

    return InkWell(
      onTap: e.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Icon(e.ikon, size: 24, color: warna),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.judul,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                      color: warna,
                    ),
                  ),
                  if (e.sub.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        e.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (e.lencana != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: e.latarLencana ?? const Color(0xFFE11D48),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  e.lencana!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: e.warnaLencana ?? Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (e.panah && e.onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}