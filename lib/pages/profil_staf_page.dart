import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class ProfilStafPage extends StatefulWidget {
  const ProfilStafPage({super.key});

  @override
  State<ProfilStafPage> createState() => _ProfilStafPageState();
}

class _ProfilStafPageState extends State<ProfilStafPage> {
  final namaController = TextEditingController();
  final teleponController = TextEditingController();
  String email = '';

  final passwordLamaController = TextEditingController();
  final passwordBaruController = TextEditingController();
  final konfirmasiController = TextEditingController();

  bool loading = true;
  bool savingProfil = false;
  bool savingPassword = false;
  String pesanProfil = '';
  String suksesProfil = '';
  String pesanPassword = '';
  String suksesPassword = '';

  @override
  void initState() {
    super.initState();
    muatProfil();
  }

  Future<String?> ambilToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> muatProfil() async {
    setState(() => loading = true);
    try {
      final token = await ambilToken();
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/auth/profil'), headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        namaController.text = data['nama'] ?? '';
        teleponController.text = data['telepon'] ?? '';
        setState(() => email = data['email'] ?? '');
      }
    } catch (e) {
      // biarkan kosong jika gagal
    }
    setState(() => loading = false);
  }

  Future<void> simpanProfil() async {
    setState(() {
      savingProfil = true;
      pesanProfil = '';
      suksesProfil = '';
    });
    try {
      final token = await ambilToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profil'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'nama': namaController.text, 'telepon': teleponController.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('nama', namaController.text);
        setState(() => suksesProfil = 'Profil berhasil disimpan');
      } else {
        setState(() => pesanProfil = data['error'] ?? 'Gagal menyimpan profil');
      }
    } catch (e) {
      setState(() => pesanProfil = 'Tidak dapat terhubung ke server');
    }
    setState(() => savingProfil = false);
  }

  Future<void> simpanPassword() async {
    setState(() {
      pesanPassword = '';
      suksesPassword = '';
    });

    if (passwordLamaController.text.isEmpty || passwordBaruController.text.isEmpty || konfirmasiController.text.isEmpty) {
      setState(() => pesanPassword = 'Semua kolom wajib diisi');
      return;
    }
    if (passwordBaruController.text.length < 6) {
      setState(() => pesanPassword = 'Password baru minimal 6 karakter');
      return;
    }
    if (passwordBaruController.text != konfirmasiController.text) {
      setState(() => pesanPassword = 'Konfirmasi password tidak sama');
      return;
    }

    setState(() => savingPassword = true);
    try {
      final token = await ambilToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/ganti-password'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'password_lama': passwordLamaController.text, 'password_baru': passwordBaruController.text}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() => suksesPassword = 'Password berhasil diubah');
        passwordLamaController.clear();
        passwordBaruController.clear();
        konfirmasiController.clear();
      } else {
        setState(() => pesanPassword = data['error'] ?? 'Gagal mengubah password');
      }
    } catch (e) {
      setState(() => pesanPassword = 'Tidak dapat terhubung ke server');
    }
    setState(() => savingPassword = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Data Diri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Nama Lengkap', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: namaController, decoration: const InputDecoration(border: UnderlineInputBorder())),
                  const SizedBox(height: 14),
                  const Text('Email', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                    child: Text(email, style: TextStyle(color: Colors.grey.shade600)),
                  ),
                  const SizedBox(height: 14),
                  const Text('Nomor Telepon', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: teleponController, decoration: const InputDecoration(hintText: '08xx-xxxx-xxxx', border: UnderlineInputBorder())),
                  if (pesanProfil.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(pesanProfil, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                  if (suksesProfil.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(suksesProfil, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: savingProfil ? null : simpanProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(savingProfil ? 'Menyimpan...' : 'Simpan Perubahan'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('Ganti Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Password Lama', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: passwordLamaController, obscureText: true, decoration: const InputDecoration(border: UnderlineInputBorder())),
                  const SizedBox(height: 14),
                  const Text('Password Baru', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: passwordBaruController, obscureText: true, decoration: const InputDecoration(hintText: 'Minimal 6 karakter', border: UnderlineInputBorder())),
                  const SizedBox(height: 14),
                  const Text('Konfirmasi Password Baru', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  TextField(controller: konfirmasiController, obscureText: true, decoration: const InputDecoration(border: UnderlineInputBorder())),
                  if (pesanPassword.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(pesanPassword, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                  ],
                  if (suksesPassword.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(suksesPassword, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: savingPassword ? null : simpanPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(savingPassword ? 'Menyimpan...' : 'Ubah Password'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}