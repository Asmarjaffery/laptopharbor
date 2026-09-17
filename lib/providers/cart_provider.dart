import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<Product, int> _items = {};

  Map<Product, int> get items => _items;

  // Add product to cart
  void addToCart(Product product) {
    if (_items.containsKey(product)) {
      _items[product] = _items[product]! + 1;
    } else {
      _items[product] = 1;
    }
    notifyListeners();
  }

  // Remove product from cart
  void removeFromCart(Product product) {
    if (_items.containsKey(product)) {
      _items.remove(product);
      notifyListeners();
    }
  }

  // Update quantity
  void updateQuantity(Product product, int quantity) {
    if (_items.containsKey(product)) {
      _items[product] = quantity;
      notifyListeners();
    }
  }

  // Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Total price
  double get totalPrice {
    double total = 0;
    _items.forEach((product, quantity) {
      total += product.price * quantity;
    });
    return total;
  }
}
