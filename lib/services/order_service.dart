import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Order place karne ke liye
  Future<String> placeOrder(OrderModel order) async {
    try {
      // Order ko Firestore mein save karo
      final docRef = await _db.collection('orders').add(order.toMap());
      return docRef.id; // Order ID return karo
    } catch (e) {
      print('Error placing order: $e');
      throw e;
    }
  }

  // Customer ke orders fetch karne ke liye
  Stream<List<OrderModel>> getCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Admin ke liye all orders
  Stream<List<OrderModel>> getAllOrders() {
    return _db
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Vendor ke orders (vendorId se filter)
  Stream<List<OrderModel>> getVendorOrders(String vendorId) {
    return _db
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Rider ke orders (riderId se filter)
  Stream<List<OrderModel>> getRiderOrders(String riderId) {
    return _db
        .collection('orders')
        .where('riderId', isEqualTo: riderId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Specific order fetch karne ke liye
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _db.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching order: $e');
      return null;
    }
  }

  // Order status update karne ke liye
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'orderStatus': newStatus,
        'status': newStatus,
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw e;
    }
  }

  // Rider assign karne ke liye
  Future<void> assignRider(String orderId, String riderId, String riderName) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'riderName': riderName,
        'orderStatus': 'Assigned',
        'status': 'Assigned',
      });
    } catch (e) {
      print('Error assigning rider: $e');
      throw e;
    }
  }

  // Order delete karne ke liye (Admin use)
  Future<void> deleteOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).delete();
    } catch (e) {
      print('Error deleting order: $e');
      throw e;
    }
  }

  // Order ko complete mark karne ke liye
  Future<void> completeOrder(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'orderStatus': 'Complete',
        'status': 'Complete',
      });
    } catch (e) {
      print('Error completing order: $e');
      throw e;
    }
  }

  // Status ke hisab se orders filter karne ke liye
  Stream<List<OrderModel>> getOrdersByStatus(String status) {
    return _db
        .collection('orders')
        .where('orderStatus', isEqualTo: status)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Pending orders (Ready status wale)
  Stream<List<OrderModel>> getReadyOrders() {
    return _db
        .collection('orders')
        .where('orderStatus', isEqualTo: 'Ready')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Out for delivery orders
  Stream<List<OrderModel>> getOutForDeliveryOrders() {
    return _db
        .collection('orders')
        .where('orderStatus', isEqualTo: 'Out for Delivery')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return OrderModel.fromFirestore(doc);
          }).toList();
        });
  }

  // Order update karne ke liye (full update)
  Future<void> updateOrder(String orderId, OrderModel order) async {
    try {
      await _db.collection('orders').doc(orderId).update(order.toMap());
    } catch (e) {
      print('Error updating order: $e');
      throw e;
    }
  }

  // Statistics ke liye - Total orders count
  Future<int> getTotalOrdersCount() async {
    try {
      final snapshot = await _db.collection('orders').get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting orders count: $e');
      return 0;
    }
  }

  // Statistics ke liye - Status wise count
  Future<Map<String, int>> getOrdersCountByStatus() async {
    try {
      final snapshot = await _db.collection('orders').get();
      Map<String, int> statusCount = {
        'Pending': 0,
        'Ready': 0,
        'Assigned': 0,
        'Out for Delivery': 0,
        'Complete': 0,
      };

      for (var doc in snapshot.docs) {
        final status = doc.data()['orderStatus'] ?? 'Pending';
        if (statusCount.containsKey(status)) {
          statusCount[status] = (statusCount[status] ?? 0) + 1;
        }
      }

      return statusCount;
    } catch (e) {
      print('Error getting status count: $e');
      return {};
    }
  }

  // Revenue calculation (Complete orders ki total)
  Future<double> getTotalRevenue() async {
    try {
      final snapshot = await _db
          .collection('orders')
          .where('orderStatus', isEqualTo: 'Complete')
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['totalAmount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating revenue: $e');
      return 0;
    }
  }
}

