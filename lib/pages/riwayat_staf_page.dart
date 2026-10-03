import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class RiwayatStafPage extends StatefulWidget {
  const RiwayatStafPage({super.key});

  @override
  State<RiwayatStafPage> createState() => _RiwayatStafPageState();
}

class _RiwayatStafPageState extends State<RiwayatStafPage> {
  List riwayat = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  Future<void> fetchRiwayat() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/transactions/recent'));
      if (response.statusCode == 200) {
        setState(() => riwayat = jsonDecode(response.body));
      }
    } catch (e) {
      // biarkan riwayat kosong
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : riwayat.isEmpty
              ? Center(child: Text('Belum ada transaksi.', style: TextStyle(color: Colors.grey.shade400)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: riwayat.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = riwayat[index];
                    final masuk = t['tipe'] == 'in';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(masuk ? Icons.arrow_downward : Icons.arrow_upward, color: masuk ? Colors.green : Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${t['nama_staf'] ?? '-'} • ${t['jumlah'] ?? 0} unit', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}