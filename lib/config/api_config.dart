import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String baseUrl = 'http://localhost:3000';

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('server_url') ?? 'http://localhost:3000';
  }

  static Future<void> setBaseUrl(String newUrl) async {
    String formatted = newUrl.trim();
    if (formatted.isNotEmpty) {
      if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
        formatted = 'http://$formatted';
      }
      if (formatted.endsWith('/')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
      baseUrl = formatted;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('server_url', baseUrl);
    }
  }
}

void showServerConfigDialog(BuildContext context, {VoidCallback? onSaved}) {
  final controller = TextEditingController(text: ApiConfig.baseUrl);
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Pengaturan URL Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan IP/URL Server Backend (contoh: http://localhost:3000 atau http://10.0.2.2:3000):',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'http://localhost:3000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiConfig.setBaseUrl(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('URL Server disimpan: ${ApiConfig.baseUrl}')),
                );
              }
              if (onSaved != null) onSaved();
            },
            child: const Text('Simpan'),
          ),
        ],
      );
    },
  );
}