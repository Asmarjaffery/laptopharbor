import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a test notification
  static Future<void> createTestNotification(String userId) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      
      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'title': 'Test Notification',
        'message': 'This is a test notification to verify everything works!',
        'vendorName': 'Test Vendor',
        'productId': null,
        'productImage': null,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      print('✅ Test notification created successfully!');
    } catch (e) {
      print('❌ Error creating test notification: $e');
    }
  }

  // Create a notification when product is approved
  static Future<void> notifyProductApproval({
    required String vendorId,
    required String productName,
    required String productId,
    String? productImage,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      
      await docRef.set({
        'id': docRef.id,
        'userId': vendorId,
        'title': 'Product Approved ✅',
        'message': 'Your product "$productName" has been approved and is now live!',
        'vendorName': 'Admin',
        'productId': productId,
        'productImage': productImage,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      print('✅ Product approval notification sent!');
    } catch (e) {
      print('❌ Error sending approval notification: $e');
    }
  }

  // Create a notification when product is rejected
  static Future<void> notifyProductRejection({
    required String vendorId,
    required String productName,
    required String reason,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      
      await docRef.set({
        'id': docRef.id,
        'userId': vendorId,
        'title': 'Product Rejected ❌',
        'message': 'Your product "$productName" was rejected. Reason: $reason',
        'vendorName': 'Admin',
        'productId': null,
        'productImage': null,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      print('✅ Product rejection notification sent!');
    } catch (e) {
      print('❌ Error sending rejection notification: $e');
    }
  }

  // Create a notification for new order
  static Future<void> notifyNewOrder({
    required String vendorId,
    required String orderId,
    required String customerName,
    required double orderAmount,
  }) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      
      await docRef.set({
        'id': docRef.id,
        'userId': vendorId,
        'title': 'New Order Received! 🎉',
        'message': 'You received a new order from $customerName for Rs. ${orderAmount.toStringAsFixed(2)}',
        'vendorName': customerName,
        'productId': orderId,
        'productImage': null,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      
      print('✅ New order notification sent!');
    } catch (e) {
      print('❌ Error sending order notification: $e');
    }
  }

  // Bulk create notifications for all admins
  static Future<void> notifyAllAdmins({
    required String title,
    required String message,
  }) async {
    try {
      // Get all admin users
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      final batch = _firestore.batch();

      for (var adminDoc in adminsSnapshot.docs) {
        final docRef = _firestore.collection('notifications').doc();
        batch.set(docRef, {
          'id': docRef.id,
          'userId': adminDoc.id,
          'title': title,
          'message': message,
          'vendorName': 'System',
          'productId': null,
          'productImage': null,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }

      await batch.commit();
      print('✅ Notifications sent to ${adminsSnapshot.docs.length} admins!');
    } catch (e) {
      print('❌ Error notifying admins: $e');
    }
  }

  // Delete old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Cleaned up ${oldNotifications.docs.length} old notifications!');
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }
}

// Usage examples:
// 
// 1. Create test notification:
// await NotificationHelper.createTestNotification(currentUserId);
//
// 2. Notify product approval:
// await NotificationHelper.notifyProductApproval(
//   vendorId: vendorId,
//   productName: 'MacBook Pro',
//   productId: productId,
//   productImage: imageUrl,
// );
//
// 3. Notify product rejection:
// await NotificationHelper.notifyProductRejection(
//   vendorId: vendorId,
//   productName: 'MacBook Pro',
//   reason: 'Invalid specifications',
// );