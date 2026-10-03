import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';

class HubungiKamiPage extends StatefulWidget {
  const HubungiKamiPage({super.key});

  @override
  State<HubungiKamiPage> createState() => _HubungiKamiPageState();
}

class _HubungiKamiPageState extends State<HubungiKamiPage> {
  final pesanController = TextEditingController();
  bool loading = false;
  String pesanError = '';
  String sukses = '';

  Future<void> kirim() async {
    setState(() {
      pesanError = '';
      sukses = '';
    });

    if (pesanController.text.trim().isEmpty) {
      setState(() => pesanError = 'Pesan tidak boleh kosong');
      return;
    }

    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/keluhan'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'pesan': pesanController.text}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        setState(() {
          sukses = data['message'] ?? 'Pesan berhasil dikirim';
          pesanController.clear();
        });
      } else {
        setState(() => pesanError = data['error'] ?? 'Gagal mengirim pesan');
      }
    } catch (e) {
      setState(() => pesanError = 'Tidak dapat terhubung ke server');
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Kami')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Laporkan kendala, bug, atau masukan untuk tim kami.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: pesanController,
              maxLines: 8,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Jelaskan kendala yang kamu alami...'),
            ),
            if (pesanError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(pesanError, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            if (sukses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(sukses, style: const TextStyle(color: AppColors.success, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: loading ? null : kirim,
                icon: const Icon(Icons.send, size: 18),
                label: Text(loading ? 'Mengirim...' : 'Kirim Pesan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}