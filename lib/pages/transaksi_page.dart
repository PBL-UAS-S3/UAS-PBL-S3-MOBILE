import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class TransaksiPage extends StatefulWidget {
  final String sku;
  const TransaksiPage({super.key, required this.sku});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  String tipe = 'in';
  final jumlahController = TextEditingController();
  String pesan = '';

  Future<void> kirimTransaksi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transactions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'sku': widget.sku, 'tipe': tipe, 'jumlah': int.tryParse(jumlahController.text) ?? 0}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Berhasil! Stok baru: ${data['stok_baru']}')));
        Navigator.pop(context);
      } else {
        setState(() => pesan = data['error'] ?? 'Gagal menyimpan transaksi');
      }
    } catch (e) {
      setState(() => pesan = 'Tidak dapat terhubung ke server (${ApiConfig.baseUrl}): $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SKU: ${widget.sku}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jenis Transaksi'),
            Row(
              children: [
                Expanded(child: RadioListTile(title: const Text('Masuk'), value: 'in', groupValue: tipe, onChanged: (v) => setState(() => tipe = v.toString()))),
                Expanded(child: RadioListTile(title: const Text('Keluar'), value: 'out', groupValue: tipe, onChanged: (v) => setState(() => tipe = v.toString()))),
              ],
            ),
            TextField(controller: jumlahController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah')),
            const SizedBox(height: 16),
            if (pesan.isNotEmpty) Text(pesan, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: kirimTransaksi, child: const Text('Simpan Transaksi')),
          ],
        ),
      ),
    );
  }
}