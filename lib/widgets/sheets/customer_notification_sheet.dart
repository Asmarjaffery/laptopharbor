import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/constants/colors.dart';
import 'package:timeago/timeago.dart' as timeago;

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          title: Text('Notifications', style: TextStyle(color: AppColors.lightGold)),
          iconTheme: IconThemeData(color: AppColors.lightGold),
        ),
        body: Center(
          child: Text(
            'Please log in to view notifications',
            style: TextStyle(color: AppColors.softGold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.lightGold),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: AppColors.richGold),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customer_notifications')
            .where('userId', isEqualTo: currentUser!.uid)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: AppColors.softGold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: AppColors.softGold.withOpacity(0.6), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 100,
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No Notifications Yet',
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when there\'s something new',
                    style: TextStyle(
                      color: AppColors.softGold.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          // Sort notifications by createdAt in code (temporary solution)
          notifications.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final notificationId = doc.id;

              return _buildNotificationCard(
                notificationId: notificationId,
                type: data['type'] ?? 'info',
                title: data['title'] ?? 'Notification',
                message: data['message'] ?? '',
                timestamp: data['createdAt'] as Timestamp?,
                isRead: data['isRead'] ?? false,
                orderId: data['orderId'],
                productId: data['productId'],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard({
    required String notificationId,
    required String type,
    required String title,
    required String message,
    required Timestamp? timestamp,
    required bool isRead,
    String? orderId,
    String? productId,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead 
            ? AppColors.cardBlack.withOpacity(0.5) 
            : AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRead 
              ? AppColors.richGold.withOpacity(0.1)
              : AppColors.richGold.withOpacity(0.4),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: isRead ? [] : [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleNotificationTap(
            notificationId: notificationId,
            type: type,
            orderId: orderId,
            productId: productId,
            isRead: isRead,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getIconColor(type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(type),
                    color: _getIconColor(type),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: AppColors.lightGold,
                                fontSize: 15,
                                fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.richGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        message,
                        style: TextStyle(
                          color: AppColors.softGold.withOpacity(isRead ? 0.5 : 0.8),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (timestamp != null) ...[
                        SizedBox(height: 8),
                        Text(
                          timeago.format(timestamp.toDate()),
                          style: TextStyle(
                            color: AppColors.softGold.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'order_placed':
        return Icons.shopping_bag;
      case 'order_ready':
        return Icons.inventory_2;
      case 'rider_assigned':
        return Icons.delivery_dining;
      case 'out_for_delivery':
        return Icons.local_shipping;
      case 'order_delivered':
        return Icons.check_circle;
      case 'new_product':
        return Icons.new_releases;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'order_placed':
        return Color(0xFFB8A046);
      case 'order_ready':
        return AppColors.richGold;
      case 'rider_assigned':
        return Color(0xFFC9B037);
      case 'out_for_delivery':
        return Color(0xFFD4AF37);
      case 'order_delivered':
        return Colors.green[400]!;
      case 'new_product':
        return Colors.blue[400]!;
      default:
        return AppColors.softGold;
    }
  }

  Future<void> _handleNotificationTap({
    required String notificationId,
    required String type,
    String? orderId,
    String? productId,
    required bool isRead,
  }) async {
    // Mark as read if not already
    if (!isRead) {
      await FirebaseFirestore.instance
          .collection('customer_notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }

    // Navigate based on type
    if (orderId != null && mounted) {
      // Navigate to order tracking with just orderId
      Navigator.pushNamed(
        context,
        '/order_tracking',
        arguments: orderId, // Pass just the orderId string
      );
    } else if (productId != null && mounted) {
      // Navigate to product details (implement if needed)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening product details...'),
          backgroundColor: AppColors.richGold,
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      final notifications = await FirebaseFirestore.instance
          .collection('customer_notifications')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: AppColors.richGold,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }
}