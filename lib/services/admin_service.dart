// import 'package:cloud_firestore/cloud_firestore.dart';

// class AdminService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;

//   // ===== Users =====
//   Future<int> getTotalVendors() async {
//     final snapshot =
//         await _db.collection('users').where('role', isEqualTo: 'vendor').get();
//     return snapshot.size;
//   }

//   Future<int> getTotalCustomers() async {
//     final snapshot =
//         await _db.collection('users').where('role', isEqualTo: 'customer').get();
//     return snapshot.size;
//   }

//   Future<int> getTotalRiders() async {
//     final snapshot =
//         await _db.collection('users').where('role', isEqualTo: 'rider').get();
//     return snapshot.size;
//   }

//   // ===== Orders =====
//   Future<int> getTotalOrders({String? status}) async {
//     Query collection = _db.collection('orders');
//     if (status != null) collection = collection.where('orderStatus', isEqualTo: status);
//     final snapshot = await collection.get();
//     return snapshot.size;
//   }

//   Future<double> getTotalSales() async {
//     final snapshot = await _db
//         .collection('orders')
//         .where('orderStatus', isEqualTo: 'Complete')
//         .get();
//     double total = 0.0;
//     for (var doc in snapshot.docs) {
//       total += (doc.data()['totalAmount'] ?? 0).toDouble();
//     }
//     return total;
//   }

//   // ===== Products =====
//   Future<int> getTotalProducts({bool? isApproved}) async {
//     Query collection = _db.collection('products');
//     if (isApproved != null) collection = collection.where('isApproved', isEqualTo: isApproved);
//     final snapshot = await collection.get();
//     return snapshot.size;
//   }

//   // ===== Reviews =====
//   Future<int> getTotalReviews() async {
//     final snapshot = await _db.collection('reviews').get();
//     return snapshot.size;
//   }

//   // ===== Messages =====
//   Future<int> getTotalMessages() async {
//     final snapshot = await _db.collection('messages').get();
//     return snapshot.size;
//   }
// }
