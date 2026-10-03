import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

Future<String?> cariProdukValid(String skuInput) async {
  try {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'));
    if (response.statusCode == 200) {
      final List produk = jsonDecode(response.body);
      final skuDicari = skuInput.trim().toUpperCase();

      for (final p in produk) {
        if (p['sku'].toString().toUpperCase() == skuDicari) {
          return p['sku'];
        }
      }
    }
  } catch (e) {
    // Return null jika ada kendala jaringan
  }
  return null;
}