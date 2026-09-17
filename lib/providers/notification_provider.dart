// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/notification_model.dart';

// class NotificationProvider extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   List<NotificationModel> _notifications = [];
//   bool _isLoading = false;

//   List<NotificationModel> get notifications => _notifications;
//   bool get isLoading => _isLoading;
//   int get unreadCount => _notifications.where((n) => !n.isRead).length;

//   // Stream for real-time updates with EXTENSIVE DEBUGGING
//   Stream<List<NotificationModel>> getNotificationsStream(String userId) {
//     print('🔍 [NotificationProvider] getNotificationsStream called');
//     print('👤 [NotificationProvider] userId: "$userId"');
    
//     if (userId.isEmpty) {
//       print('❌ [NotificationProvider] userId is EMPTY - returning empty stream');
//       return Stream.value([]);
//     }

//     print('📡 [NotificationProvider] Setting up Firestore stream...');
    
//     return _firestore
//         .collection('notifications')
//         .where('userId', isEqualTo: userId)
//         .orderBy('timestamp', descending: true)
//         .limit(100)
//         .snapshots()
//         .map((snapshot) {
//       print('📥 [NotificationProvider] Snapshot received!');
//       print('📊 [NotificationProvider] Number of documents: ${snapshot.docs.length}');
      
//       if (snapshot.docs.isEmpty) {
//         print('⚠️ [NotificationProvider] No documents found for userId: $userId');
//         print('💡 [NotificationProvider] Check Firestore Console to verify:');
//         print('   1. Collection "notifications" exists');
//         print('   2. Documents have userId field matching: $userId');
//         print('   3. Firestore rules allow reading');
//       }

//       final notifications = snapshot.docs.map((doc) {
//         try {
//           final data = doc.data();
//           print('📄 [NotificationProvider] Processing doc: ${doc.id}');
//           print('   Data: $data');
          
//           return NotificationModel.fromJson({
//             ...data,
//             'id': doc.id,
//           });
//         } catch (e) {
//           print('❌ [NotificationProvider] Error parsing notification ${doc.id}: $e');
//           return null;
//         }
//       }).whereType<NotificationModel>().toList();

//       print('✅ [NotificationProvider] Successfully parsed ${notifications.length} notifications');
      
//       _notifications = notifications;
//       Future.microtask(() => notifyListeners());
      
//       return notifications;
//     }).handleError((error) {
//       print('❌ [NotificationProvider] Stream error: $error');
//       if (error.toString().contains('permission-denied')) {
//         print('🔒 [NotificationProvider] PERMISSION DENIED!');
//         print('   Check Firestore rules - notifications may not be readable');
//       }
//       return <NotificationModel>[];
//     });
//   }

//   Future<void> markAsRead(String notificationId) async {
//     print('📖 [NotificationProvider] Marking notification as read: $notificationId');
//     try {
//       await _firestore
//           .collection('notifications')
//           .doc(notificationId)
//           .update({'isRead': true});

//       final index = _notifications.indexWhere((n) => n.id == notificationId);
//       if (index != -1) {
//         _notifications[index] = _notifications[index].copyWith(isRead: true);
//         notifyListeners();
//         print('✅ [NotificationProvider] Notification marked as read');
//       }
//     } catch (e) {
//       print('❌ [NotificationProvider] Error marking notification as read: $e');
//     }
//   }

//   Future<void> markAllAsRead(String userId) async {
//     print('📖 [NotificationProvider] Marking all notifications as read for: $userId');
//     if (userId.isEmpty) return;

//     try {
//       final batch = _firestore.batch();
//       final unreadNotifications = _notifications.where((n) => !n.isRead).toList();

//       print('   Found ${unreadNotifications.length} unread notifications');

//       if (unreadNotifications.isEmpty) return;

//       for (var n in unreadNotifications) {
//         batch.update(
//           _firestore.collection('notifications').doc(n.id),
//           {'isRead': true},
//         );
//       }
//       await batch.commit();

//       _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
//       notifyListeners();
//       print('✅ [NotificationProvider] All notifications marked as read');
//     } catch (e) {
//       print('❌ [NotificationProvider] Error marking all as read: $e');
//     }
//   }

//   Future<void> deleteNotification(String notificationId) async {
//     print('🗑️ [NotificationProvider] Deleting notification: $notificationId');
//     try {
//       await _firestore.collection('notifications').doc(notificationId).delete();
//       _notifications.removeWhere((n) => n.id == notificationId);
//       notifyListeners();
//       print('✅ [NotificationProvider] Notification deleted');
//     } catch (e) {
//       print('❌ [NotificationProvider] Error deleting notification: $e');
//     }
//   }
// }