import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  /// Mendapatkan default URL sesuai platform (Web -> localhost, Emulator/Android -> 10.0.2.2)
  static String get defaultUrl => kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';

  static String baseUrl = defaultUrl;

  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('server_url') ?? defaultUrl;
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
            Text(
              'Masukkan IP/URL Server Backend (Default platform: ${ApiConfig.defaultUrl}):',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: ApiConfig.defaultUrl,
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