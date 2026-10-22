import '../services/product_service.dart';

Future<String?> cariProdukValid(String skuInput) async {
  return ProductService.cariProdukValid(skuInput);
}