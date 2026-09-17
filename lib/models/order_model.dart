import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String? id;
  final String productId;
  final String customerId;
  final String status;
  final double price;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String shippingAddress;
  final String city;
  final String zipCode;
  final String paymentMethod;
  final int itemCount;
  final double subtotal;
  final double shippingCost;
  final double totalAmount;
  final DateTime orderDate;
  final String? vendorId;
  final String? riderId;
  final String? riderName;
  final List<Map<String, dynamic>>? products;

  OrderModel({
    this.id,
    required this.productId,
    required this.customerId,
    required this.status,
    required this.price,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.shippingAddress,
    required this.city,
    required this.zipCode,
    required this.paymentMethod,
    required this.itemCount,
    required this.subtotal,
    required this.shippingCost,
    required this.totalAmount,
    required this.orderDate,
    this.vendorId,
    this.riderId,
    this.riderName,
    this.products,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return OrderModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      customerId: data['userId'] ?? data['customerId'] ?? '',
      status: data['orderStatus'] ?? 'Pending',
      price: (data['price'] ?? 0).toDouble(),
      customerName: data['customerName'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      shippingAddress: data['shippingAddress'] ?? '',
      city: data['city'] ?? '',
      zipCode: data['zipCode'] ?? '',
      paymentMethod: data['paymentMethod'] ?? 'COD',
      itemCount: data['itemCount'] ?? 1,
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      orderDate: (data['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vendorId: data['vendorId'],
      riderId: data['riderId'],
      riderName: data['riderName'],
      products: data['products'] != null 
          ? List<Map<String, dynamic>>.from(data['products'])
          : null,
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      productId: map['productId'] ?? '',
      customerId: map['userId'] ?? map['customerId'] ?? '',
      status: map['orderStatus'] ?? map['status'] ?? 'Pending',
      price: (map['price'] ?? 0).toDouble(),
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      city: map['city'] ?? '',
      zipCode: map['zipCode'] ?? '',
      paymentMethod: map['paymentMethod'] ?? 'COD',
      itemCount: map['itemCount'] ?? 1,
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      shippingCost: (map['shippingCost'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      orderDate: map['orderDate'] is DateTime 
          ? map['orderDate'] 
          : (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vendorId: map['vendorId'],
      riderId: map['riderId'],
      riderName: map['riderName'],
      products: map['products'] != null 
          ? List<Map<String, dynamic>>.from(map['products'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'userId': customerId,
      'customerId': customerId,
      'orderStatus': status,
      'status': status,
      'price': price,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'city': city,
      'zipCode': zipCode,
      'paymentMethod': paymentMethod,
      'itemCount': itemCount,
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'totalAmount': totalAmount,
      'orderDate': Timestamp.fromDate(orderDate),
      'vendorId': vendorId,
      'riderId': riderId,
      'riderName': riderName,
      'products': products,
    };
  }

  // Helper method to fetch product name from Firestore
  Future<String> getFirstProductName() async {
    try {
      if (products != null && products!.isNotEmpty) {
        // First check if name already exists in products array
        final firstName = products!.first['name'] ?? products!.first['productName'];
        if (firstName != null && firstName.toString().isNotEmpty) {
          return firstName.toString();
        }
        
        // If name doesn't exist, fetch from products collection
        final productId = products!.first['productId'];
        if (productId != null) {
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(productId.toString())
              .get();
          
          if (productDoc.exists) {
            final data = productDoc.data();
            return data?['name'] ?? 'Order #${id?.substring(0, 8).toUpperCase() ?? ""}';
          }
        }
      }
      
      // Fallback: try fetching single product if productId exists
      if (productId.isNotEmpty) {
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final data = productDoc.data();
          return data?['name'] ?? 'Order #${id?.substring(0, 8).toUpperCase() ?? ""}';
        }
      }
      
      return 'Order #${id?.substring(0, 8).toUpperCase() ?? ""}';
    } catch (e) {
      print('Error fetching product name: $e');
      return 'Order #${id?.substring(0, 8).toUpperCase() ?? ""}';
    }
  }

  // Helper method to enrich products with names from Firestore
  Future<List<Map<String, dynamic>>> getProductsWithNames() async {
    if (products == null || products!.isEmpty) {
      return [];
    }

    List<Map<String, dynamic>> enrichedProducts = [];

    for (var product in products!) {
      Map<String, dynamic> enrichedProduct = Map.from(product);
      
      // If name doesn't exist, fetch it
      if (enrichedProduct['name'] == null || enrichedProduct['name'].toString().isEmpty) {
        final productId = product['productId'];
        if (productId != null) {
          try {
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(productId.toString())
                .get();
            
            if (productDoc.exists) {
              final data = productDoc.data();
              enrichedProduct['name'] = data?['name'] ?? 'Unknown Product';
            } else {
              enrichedProduct['name'] = 'Product #${productId.toString().substring(0, 8)}';
            }
          } catch (e) {
            print('Error fetching product $productId: $e');
            enrichedProduct['name'] = 'Unknown Product';
          }
        } else {
          enrichedProduct['name'] = 'Unknown Product';
        }
      }
      
      enrichedProducts.add(enrichedProduct);
    }

    return enrichedProducts;
  }

  Color getStatusColor() {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFF9800);
      case 'Ready':
        return const Color(0xFF2196F3);
      case 'Assigned':
        return const Color(0xFF9C27B0);
      case 'Out for Delivery':
        return const Color(0xFFFFEB3B);
      case 'Complete':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status) {
      case 'Pending':
        return Icons.schedule;
      case 'Ready':
        return Icons.inventory_2;
      case 'Assigned':
        return Icons.assignment;
      case 'Out for Delivery':
        return Icons.local_shipping;
      case 'Complete':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String getStatusTitle() {
    switch (status) {
      case 'Assigned':
        return 'Rider Assigned';
      default:
        return status;
    }
  }

  String getStatusMessage() {
    switch (status) {
      case 'Pending':
        return 'Waiting for vendor to prepare your order';
      case 'Ready':
        return 'Order is ready, waiting for rider assignment';
      case 'Assigned':
        return 'Rider assigned and will pick up your order soon';
      case 'Out for Delivery':
        return 'Your order is on the way';
      case 'Complete':
        return 'Order delivered successfully';
      default:
        return 'Processing your order';
    }
  }
}