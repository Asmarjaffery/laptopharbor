import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> products = [];
  bool isLoading = false;

  // Fetch all products
  void fetchProducts() {
    isLoading = true;
    notifyListeners();

    _productService.getProducts().listen((productList) {
      products = productList;
      isLoading = false;
      notifyListeners();
    });
  }

  // Filter products
  Future<void> filterProducts({String? category, String? brand}) async {
    isLoading = true;
    notifyListeners();

    products = await _productService.getFilteredProducts(
      category: category,
      brand: brand,
    );

    isLoading = false;
    notifyListeners();
  }
}
