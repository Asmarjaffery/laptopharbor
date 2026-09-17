// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================
  // 1. SEND NOTIFICATION TO SPECIFIC USER
  // ============================================
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notification = NotificationModel(
        userId: userId,
        title: title,
        message: message,
        type: type,
        createdAt: DateTime.now(),
        data: data,
      );

      await _db.collection('notifications').add(notification.toMap());
      print('✅ Notification sent to user: $userId');
    } catch (e) {
      print('❌ Error sending notification: $e');
      rethrow;
    }
  }

  // ============================================
  // 2. SEND NOTIFICATION TO ALL CUSTOMERS
  // ============================================
  Future<void> sendToAllUsers({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all customers
      final usersSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('⚠️ No customers found to send notifications');
        return;
      }

      // Batch write for better performance
      final batch = _db.batch();
      int count = 0;

      for (var userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          userId: userDoc.id,
          title: title,
          message: message,
          type: type,
          createdAt: DateTime.now(),
          data: data,
        );

        final notifRef = _db.collection('notifications').doc();
        batch.set(notifRef, notification.toMap());
        count++;

        // Firestore batch limit is 500, commit and create new batch if needed
        if (count % 500 == 0) {
          await batch.commit();
          print('✅ Batch committed: $count notifications');
        }
      }

      // Commit remaining notifications
      await batch.commit();
      print('✅ Sent $count notifications to all customers');
    } catch (e) {
      print('❌ Error sending bulk notification: $e');
      rethrow;
    }
  }

  // ============================================
  // 3. SEND TO SPECIFIC ROLE (VENDOR/RIDER/ADMIN)
  // ============================================
  Future<void> sendToRole({
    required String role, // 'vendor', 'rider', 'admin'
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final usersSnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        print('⚠️ No users with role $role found');
        return;
      }

      final batch = _db.batch();
      int count = 0;

      for (var userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          userId: userDoc.id,
          title: title,
          message: message,
          type: type,
          createdAt: DateTime.now(),
          data: data,
        );

        final notifRef = _db.collection('notifications').doc();
        batch.set(notifRef, notification.toMap());
        count++;

        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      await batch.commit();
      print('✅ Sent $count notifications to $role users');
    } catch (e) {
      print('❌ Error sending notification to role: $e');
      rethrow;
    }
  }

  // ============================================
  // 4. GET USER NOTIFICATIONS (STREAM)
  // ============================================
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to recent 50 notifications
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  // ============================================
  // 5. GET UNREAD COUNT (STREAM)
  // ============================================
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================
  // 6. MARK SINGLE NOTIFICATION AS READ
  // ============================================
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      rethrow;
    }
  }

  // ============================================
  // 7. MARK ALL NOTIFICATIONS AS READ
  // ============================================
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No unread notifications to mark');
        return;
      }

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      print('✅ Marked ${snapshot.docs.length} notifications as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
      rethrow;
    }
  }

  // ============================================
  // 8. DELETE SINGLE NOTIFICATION
  // ============================================
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.collection('notifications').doc(notificationId).delete();
      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
      rethrow;
    }
  }

  // ============================================
  // 9. DELETE ALL USER NOTIFICATIONS
  // ============================================
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final snapshot = await _db
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No notifications to delete');
        return;
      }

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('✅ Deleted ${snapshot.docs.length} notifications');
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
      rethrow;
    }
  }

  // ============================================
  // 10. DELETE OLD NOTIFICATIONS (CLEANUP)
  // ============================================
  Future<void> deleteOldNotifications({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final snapshot = await _db
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      if (snapshot.docs.isEmpty) {
        print('ℹ️ No old notifications to delete');
        return;
      }

      final batch = _db.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;

        if (count % 500 == 0) {
          await batch.commit();
        }
      }

      await batch.commit();
      print('✅ Deleted $count old notifications (older than $daysOld days)');
    } catch (e) {
      print('❌ Error deleting old notifications: $e');
      rethrow;
    }
  }

  // ============================================
  // 11. ORDER STATUS UPDATE NOTIFICATION
  // ============================================
  Future<void> sendOrderStatusNotification({
    required String customerId,
    required String orderId,
    required String status,
    String? riderName,
  }) async {
    String title;
    String message;
    String emoji;

    switch (status.toLowerCase()) {
      case 'pending':
        emoji = '⏳';
        title = 'Order Received';
        message = 'Your order #${orderId.substring(0, 8)} has been received and is being processed.';
        break;
      case 'confirmed':
        emoji = '✅';
        title = 'Order Confirmed';
        message = 'Your order #${orderId.substring(0, 8)} has been confirmed!';
        break;
      case 'preparing':
        emoji = '👨‍🍳';
        title = 'Order Being Prepared';
        message = 'Your order #${orderId.substring(0, 8)} is being prepared by the vendor.';
        break;
      case 'ready for pickup':
        emoji = '📦';
        title = 'Order Ready';
        message = 'Your order #${orderId.substring(0, 8)} is ready for pickup!';
        break;
      case 'out for delivery':
        emoji = '🚚';
        title = 'Out for Delivery';
        message = riderName != null
            ? 'Your order #${orderId.substring(0, 8)} is on the way! Rider $riderName will deliver soon.'
            : 'Your order #${orderId.substring(0, 8)} is out for delivery!';
        break;
      case 'delivered':
      case 'complete':
        emoji = '🎉';
        title = 'Order Delivered';
        message = 'Your order #${orderId.substring(0, 8)} has been delivered successfully!';
        break;
      case 'cancelled':
        emoji = '❌';
        title = 'Order Cancelled';
        message = 'Your order #${orderId.substring(0, 8)} has been cancelled.';
        break;
      default:
        emoji = '📱';
        title = 'Order Update';
        message = 'Your order #${orderId.substring(0, 8)} status: $status';
    }

    await sendNotification(
      userId: customerId,
      title: '$emoji $title',
      message: message,
      type: 'order_update',
      data: {
        'orderId': orderId,
        'status': status,
        'riderName': riderName,
      },
    );
  }

  // ============================================
  // 12. NEW PRODUCT NOTIFICATION
  // ============================================
  Future<void> sendNewProductNotification({
    required String productId,
    required String productName,
    required String category,
    String? imageUrl,
  }) async {
    await sendToAllUsers(
      title: '🎉 New Product Available!',
      message: 'Check out $productName in $category category!',
      type: 'new_product',
      data: {
        'productId': productId,
        'productName': productName,
        'category': category,
        'imageUrl': imageUrl,
      },
    );
  }

  // ============================================
  // 13. RIDER ASSIGNMENT NOTIFICATION
  // ============================================
  Future<void> sendRiderAssignmentNotification({
    required String riderId,
    required String orderId,
    required String pickupAddress,
    required String deliveryAddress,
  }) async {
    await sendNotification(
      userId: riderId,
      title: '🚴 New Delivery Assignment',
      message: 'You have been assigned order #${orderId.substring(0, 8)}',
      type: 'rider_assignment',
      data: {
        'orderId': orderId,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
      },
    );
  }

  // ============================================
  // 14. VENDOR ORDER NOTIFICATION
  // ============================================
  Future<void> sendVendorOrderNotification({
    required String vendorId,
    required String orderId,
    required int itemCount,
    required double totalAmount,
  }) async {
    await sendNotification(
      userId: vendorId,
      title: '🛍️ New Order Received',
      message: 'You have a new order with $itemCount items worth Rs. ${totalAmount.toStringAsFixed(0)}',
      type: 'vendor_order',
      data: {
        'orderId': orderId,
        'itemCount': itemCount,
        'totalAmount': totalAmount,
      },
    );
  }

  // ============================================
  // 15. PAYMENT CONFIRMATION NOTIFICATION
  // ============================================
  Future<void> sendPaymentConfirmation({
    required String userId,
    required String orderId,
    required double amount,
    required String paymentMethod,
  }) async {
    await sendNotification(
      userId: userId,
      title: '💰 Payment Confirmed',
      message: 'Your payment of Rs. ${amount.toStringAsFixed(0)} via $paymentMethod has been confirmed.',
      type: 'payment',
      data: {
        'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod,
      },
    );
  }
}

// ============================================
// USAGE EXAMPLES IN COMMENTS
// ============================================

/*
// 1. Send notification when product is approved (Admin Panel)
final notificationService = NotificationService();
await notificationService.sendNewProductNotification(
  productId: product.id!,
  productName: product.name,
  category: product.category,
  imageUrl: product.images.first,
);

// 2. Send notification when order status changes
await notificationService.sendOrderStatusNotification(
  customerId: order.customerId,
  orderId: order.id!,
  status: 'Out for Delivery',
  riderName: riderName,
);

// 3. Notify rider when assigned to order
await notificationService.sendRiderAssignmentNotification(
  riderId: riderId,
  orderId: order.id!,
  pickupAddress: order.vendorAddress,
  deliveryAddress: order.deliveryAddress,
);

// 4. Notify vendor when they receive new order
await notificationService.sendVendorOrderNotification(
  vendorId: vendorId,
  orderId: order.id!,
  itemCount: order.items.length,
  totalAmount: order.totalAmount,
);

// 5. Mark notification as read
await notificationService.markAsRead(notificationId);

// 6. Delete old notifications (run periodically)
await notificationService.deleteOldNotifications(daysOld: 30);
*/