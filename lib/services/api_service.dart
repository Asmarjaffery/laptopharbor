import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product_detail.dart';

class ApiService {
  // Update this with your actual API URL
  static const String baseUrl = 'YOUR_API_BASE_URL'; // e.g., 'http://192.168.1.100:3000/api'
  
  // If you're using authentication, store token here
  static String? authToken;

  // Fetch single product details
  static Future<ProductDetail> fetchProductDetail(String productId) async {
    final url = Uri.parse('$baseUrl/products/$productId');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different response formats
        // Some APIs return: { "product": {...} }
        // Some APIs return: { "data": {...} }
        // Some APIs return the product directly: {...}
        
        Map<String, dynamic> productData;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('product')) {
            productData = data['product'];
          } else if (data.containsKey('data')) {
            productData = data['data'];
          } else {
            productData = data;
          }
        } else {
          throw Exception('Invalid response format');
        }
        
        return ProductDetail.fromJson(productData);
      } else if (response.statusCode == 404) {
        throw Exception('Product not found');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to load product: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product: $e');
      throw Exception('Error fetching product: $e');
    }
  }

  // Optional: Fetch all products (if needed)
  static Future<List<ProductDetail>> fetchAllProducts() async {
    final url = Uri.parse('$baseUrl/products');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        List<dynamic> productsJson;
        if (data is List) {
          productsJson = data;
        } else if (data['products'] != null) {
          productsJson = data['products'];
        } else if (data['data'] != null) {
          productsJson = data['data'];
        } else {
          throw Exception('Invalid response format');
        }
        
        return productsJson
            .map((json) => ProductDetail.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }
}