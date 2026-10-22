import '../services/product_service.dart';

Future<List> fetchProductsFromServer() async {
  return ProductService.fetchProducts();
}