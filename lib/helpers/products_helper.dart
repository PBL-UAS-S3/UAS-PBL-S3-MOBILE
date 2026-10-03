import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

Future<List> fetchProductsFromServer() async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/products'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return [];
}