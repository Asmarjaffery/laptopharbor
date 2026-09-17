import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ 1. NEW USER REGISTRATION
  static Future<void> notifyNewUserRegistration({
    required String userId,
    required String userName,
    required String userEmail,
    required String userRole,
  }) async {
    try {
      print('🔔 ===== CREATING NEW USER NOTIFICATION =====');
      print('🔔 User ID: $userId');
      print('🔔 User Name: $userName');
      print('🔔 User Email: $userEmail');
      print('🔔 User Role: $userRole');
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'new_user_registration',
        'title': '🎉 New User Registered',
        'message': '$userName ($userRole) just registered with email: $userEmail',
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userRole': userRole,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Notification document created with ID: ${docRef.id}');
      
      // Wait for server to process timestamp
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify the document was created
      final verifyDoc = await docRef.get();
      if (verifyDoc.exists) {
        final data = verifyDoc.data();
        print('✅ ===== NOTIFICATION VERIFIED =====');
        print('✅ Document ID: ${verifyDoc.id}');
        print('✅ Type: ${data?['type']}');
        print('✅ Title: ${data?['title']}');
        print('✅ Message: ${data?['message']}');
        print('✅ IsRead: ${data?['isRead']}');
        print('✅ CreatedAt: ${data?['createdAt']}');
        print('✅ CreatedAt Type: ${data?['createdAt']?.runtimeType}');
      } else {
        print('❌ ERROR: Notification document does not exist after creation!');
      }
      
    } catch (e, stackTrace) {
      print('❌ ===== ERROR CREATING NOTIFICATION =====');
      print('❌ Error: $e');
      print('❌ Stack Trace: $stackTrace');
      rethrow;
    }
  }

  /// ✅ 2. NEW ORDER CREATED
  static Future<void> notifyNewOrder({
    required String orderId,
    required String customerName,
    required String vendorName,
    required double totalAmount,
    String? vendorId,
    String? customerId,
  }) async {
    try {
      print('🔔 Creating notification for new order: $orderId');
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'new_order',
        'title': '🛒 New Order Received',
        'message': 'Order #${orderId.substring(0, 8).toUpperCase()} placed by $customerName from $vendorName. Amount: \$${totalAmount.toStringAsFixed(2)}',
        'orderId': orderId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'customerId': customerId,
        'customerName': customerName,
        'totalAmount': totalAmount,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ New order notification created: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating new order notification: $e');
    }
  }

  /// ✅ 3. PRODUCT UPDATED
  static Future<void> notifyProductUpdate({
    required String productId,
    required String productName,
    required String vendorName,
    required String changes,
    String? vendorId,
  }) async {
    try {
      print('🔔 Creating notification for product update: $productName');
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'product_update',
        'title': '📦 Product Updated',
        'message': '$vendorName updated "$productName". Changes: $changes',
        'productId': productId,
        'productName': productName,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'changes': changes,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Product update notification created: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating product update notification: $e');
    }
  }

  /// ✅ 4. NEW REVIEW SUBMITTED
  static Future<void> notifyNewReview({
    required String reviewId,
    required String userName,
    required String productName,
    required int rating,
    String? comment,
    String? userId,
    String? productId,
  }) async {
    try {
      print('🔔 Creating notification for new review: $productName');
      
      final stars = '⭐' * rating;
      final commentPreview = comment != null && comment.length > 50 
          ? '${comment.substring(0, 50)}...' 
          : comment ?? '';
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'new_review',
        'title': '⭐ New Review Submitted',
        'message': '$userName gave $stars ($rating/5) for "$productName".${commentPreview.isNotEmpty ? ' Comment: "$commentPreview"' : ''}',
        'reviewId': reviewId,
        'productId': productId,
        'productName': productName,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ New review notification created: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating new review notification: $e');
    }
  }

  /// ✅ 5. ORDER READY (VENDOR MARKS READY)
  static Future<void> notifyOrderReady({
    required String orderId,
    required String vendorName,
    required String customerName,
    String? vendorId,
    String? customerId,
  }) async {
    try {
      print('🔔 Creating notification for order ready: $orderId');
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'order_ready',
        'title': '✅ Order Ready for Pickup',
        'message': '$vendorName marked Order #${orderId.substring(0, 8).toUpperCase()} as ready. Customer: $customerName',
        'orderId': orderId,
        'vendorId': vendorId,
        'vendorName': vendorName,
        'customerId': customerId,
        'customerName': customerName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Order ready notification created: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating order ready notification: $e');
    }
  }

  /// ✅ 6. ORDER PICKED UP BY RIDER
  static Future<void> notifyOrderPickedUp({
    required String orderId,
    required String riderName,
    required String customerName,
    required String orderStatus,
    String? riderId,
    String? customerId,
  }) async {
    try {
      print('🔔 Creating notification for order picked up: $orderId');
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'order_received',
        'title': '🚚 Order Picked Up',
        'message': 'Rider $riderName picked up Order #${orderId.substring(0, 8).toUpperCase()}. Status: $orderStatus. Customer: $customerName',
        'orderId': orderId,
        'riderId': riderId,
        'riderName': riderName,
        'customerId': customerId,
        'customerName': customerName,
        'orderStatus': orderStatus,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Order picked up notification created: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating order picked up notification: $e');
    }
  }

  /// ✅ 7. ORDER DELIVERED (RIDER COMPLETES DELIVERY)
  static Future<void> notifyOrderDelivered({
    required String orderId,
    required String riderName,
    required String customerName,
    String? riderId,
    String? customerId,
  }) async {
    try {
      print('🔔 Creating notification for order delivered: $orderId');
      
      final docRef = await _firestore.collection('admin_notifications').add({
        'type': 'order_delivered',
        'title': '🎉 Order Delivered',
        'message': 'Rider $riderName successfully delivered Order #${orderId.substring(0, 8).toUpperCase()} to $customerName',
        'orderId': orderId,
        'riderId': riderId,
        'riderName': riderName,
        'customerId': customerId,
        'customerName': customerName,
        'orderStatus': 'Complete',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Order delivered notification created: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating order delivered notification: $e');
    }
  }

  /// ✅ UTILITY: Get unread notification count
  static Stream<int> getUnreadNotificationCount() {
    return _firestore
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// ✅ UTILITY: Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      print('🔔 Marking all notifications as read...');
      
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('admin_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      print('🔔 Found ${snapshot.docs.length} unread notifications');

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// ✅ UTILITY: Delete old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      print('🔔 Cleaning up old notifications...');
      
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final batch = _firestore.batch();
      
      final snapshot = await _firestore
          .collection('admin_notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      print('🔔 Found ${snapshot.docs.length} old notifications to delete');

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Old notifications cleaned up');
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }
}