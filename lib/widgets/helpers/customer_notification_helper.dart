import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for sending customer notifications
/// All notifications are stored in Firestore collection: 'customer_notifications'
class CustomerNotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Base method to create notification
  static Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? orderId,
    String? productId,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      await _firestore.collection('customer_notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'orderId': orderId,
        'productId': productId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extraData,
      });
      print('✅ Notification sent to user $userId: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
      // Don't throw error - notification failure shouldn't break the main flow
    }
  }

  /// 1. Order Placed Notification
  static Future<void> sendOrderPlacedNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
  }) async {
    await _createNotification(
      userId: customerId,
      type: 'order_placed',
      title: '🎉 Order Placed Successfully',
      message: 'Your order #$orderNumber has been placed successfully. We\'ll notify you when it\'s ready.',
      orderId: orderId,
    );
  }

  /// 2. Order Ready Notification
  static Future<void> sendOrderReadyNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
  }) async {
    await _createNotification(
      userId: customerId,
      type: 'order_ready',
      title: '✅ Order Ready for Pickup',
      message: 'Great news! Your order #$orderNumber is ready and waiting for rider assignment.',
      orderId: orderId,
    );
  }

  /// 3. Rider Assigned Notification
  static Future<void> sendRiderAssignedNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    required String riderName,
  }) async {
    await _createNotification(
      userId: customerId,
      type: 'rider_assigned',
      title: '🏍️ Rider Assigned',
      message: '$riderName has been assigned to deliver your order #$orderNumber.',
      orderId: orderId,
      extraData: {'riderName': riderName},
    );
  }

  /// 4. Out for Delivery Notification
  static Future<void> sendOutForDeliveryNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    int? estimatedMinutes,
  }) async {
    final estimateText = estimatedMinutes != null
        ? ' Estimated delivery in $estimatedMinutes minutes.'
        : '';
    
    await _createNotification(
      userId: customerId,
      type: 'out_for_delivery',
      title: '🚚 Order Out for Delivery',
      message: 'Your order #$orderNumber is on its way!$estimateText',
      orderId: orderId,
      extraData: estimatedMinutes != null ? {'estimatedMinutes': estimatedMinutes} : null,
    );
  }

  /// 5. Order Delivered Notification
  static Future<void> sendOrderDeliveredNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
  }) async {
    await _createNotification(
      userId: customerId,
      type: 'order_delivered',
      title: '✨ Order Delivered',
      message: 'Your order #$orderNumber has been delivered successfully. Thank you for shopping with us!',
      orderId: orderId,
    );
  }

  /// 6. New Product Notification
  static Future<void> sendNewProductNotification({
    required String customerId,
    required String productName,
    required String productId,
  }) async {
    await _createNotification(
      userId: customerId,
      type: 'new_product',
      title: '🆕 New Product Available',
      message: 'Check out our new product: $productName',
      productId: productId,
      extraData: {'productName': productName},
    );
  }

  /// 7. Order Cancelled Notification
  static Future<void> sendOrderCancelledNotification({
    required String customerId,
    required String orderId,
    required String orderNumber,
    String? reason,
  }) async {
    final reasonText = reason != null ? ' Reason: $reason' : '';
    
    await _createNotification(
      userId: customerId,
      type: 'order_cancelled',
      title: '❌ Order Cancelled',
      message: 'Your order #$orderNumber has been cancelled.$reasonText',
      orderId: orderId,
      extraData: reason != null ? {'cancellationReason': reason} : null,
    );
  }

  /// 8. Price Drop Notification (Optional - for wishlist items)
  static Future<void> sendPriceDropNotification({
    required String customerId,
    required String productName,
    required String productId,
    required double oldPrice,
    required double newPrice,
  }) async {
    final discount = ((oldPrice - newPrice) / oldPrice * 100).toStringAsFixed(0);
    
    await _createNotification(
      userId: customerId,
      type: 'price_drop',
      title: '💰 Price Drop Alert',
      message: '$productName is now \$$newPrice (was \$$oldPrice). Save $discount%!',
      productId: productId,
      extraData: {
        'productName': productName,
        'oldPrice': oldPrice,
        'newPrice': newPrice,
      },
    );
  }

  /// 9. Back in Stock Notification (Optional)
  static Future<void> sendBackInStockNotification({
    required String customerId,
    required String productName,
    required String productId,
  }) async {
    await _createNotification(
      userId: customerId,
      type: 'back_in_stock',
      title: '📦 Back in Stock',
      message: 'Good news! $productName is back in stock. Order now before it\'s gone!',
      productId: productId,
      extraData: {'productName': productName},
    );
  }

  /// 10. Get Unread Count (for badge display)
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('customer_notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 11. Mark Single Notification as Read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('customer_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// 12. Mark All Notifications as Read
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final notifications = await _firestore
          .collection('customer_notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('✅ All notifications marked as read for user $userId');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// 13. Delete Notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('customer_notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// 14. Delete All Notifications for User
  static Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final notifications = await _firestore
          .collection('customer_notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ All notifications deleted for user $userId');
    } catch (e) {
      print('❌ Error deleting all notifications: $e');
    }
  }
}

/// Usage Examples:
/// 
/// // When order is placed:
/// await CustomerNotificationHelper.sendOrderPlacedNotification(
///   customerId: userId,
///   orderId: orderId,
///   orderNumber: orderNumber,
/// );
/// 
/// // When vendor marks ready:
/// await CustomerNotificationHelper.sendOrderReadyNotification(
///   customerId: userId,
///   orderId: orderId,
///   orderNumber: orderNumber,
/// );
/// 
/// // When admin assigns rider:
/// await CustomerNotificationHelper.sendRiderAssignedNotification(
///   customerId: userId,
///   orderId: orderId,
///   orderNumber: orderNumber,
///   riderName: riderName,
/// );
/// 
/// // When rider starts delivery:
/// await CustomerNotificationHelper.sendOutForDeliveryNotification(
///   customerId: userId,
///   orderId: orderId,
///   orderNumber: orderNumber,
///   estimatedMinutes: 30,
/// );
/// 
/// // When order is delivered:
/// await CustomerNotificationHelper.sendOrderDeliveredNotification(
///   customerId: userId,
///   orderId: orderId,
///   orderNumber: orderNumber,
/// );
/// 
/// // When new product is added:
/// await CustomerNotificationHelper.sendNewProductNotification(
///   customerId: userId,
///   productName: productName,
///   productId: productId,
/// );
/// 
/// // Get unread count for badge:
/// StreamBuilder<int>(
///   stream: CustomerNotificationHelper.getUnreadCount(userId),
///   builder: (context, snapshot) {
///     final count = snapshot.data ?? 0;
///     return Badge(count: count);
///   },
/// )