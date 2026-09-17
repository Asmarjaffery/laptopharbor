import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();
  List<OrderModel> orders = [];  // ✓ Order → OrderModel
  bool isLoading = false;

  // Fetch orders for a customer
  void fetchCustomerOrders(String customerId) {
    isLoading = true;
    notifyListeners();

    _service.getCustomerOrders(customerId).listen((data) {
      orders = data;
      isLoading = false;
      notifyListeners();
    });
  }

  // Fetch all orders for admin/vendor
  void fetchAllOrders() {
    isLoading = true;
    notifyListeners();

    _service.getAllOrders().listen((data) {
      orders = data;
      isLoading = false;
      notifyListeners();
    });
  }

  // Place an order
  Future<void> placeOrder(OrderModel order) async {  // ✓ Order → OrderModel
    await _service.placeOrder(order);
  }
}