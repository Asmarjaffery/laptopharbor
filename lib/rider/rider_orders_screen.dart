import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';

// ✅ TRY DIFFERENT IMPORT PATHS - Use the one that matches your project structure
// Option 1: If helper is in lib/helpers/
// import '../helpers/admin_notification_helper.dart';

// Option 2: If helper is in lib/widgets/helpers/
import 'package:mobileapp/widgets/helpers/admin_notification_helper.dart';

// Option 3: Absolute import (most reliable)
// import 'package:mobileapp/helpers/admin_notification_helper.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});

  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startDelivery(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'orderStatus': 'Out for Delivery',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Delivery started!'),
            backgroundColor: AppColors.richGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  Future<void> _confirmDelivery(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Delivery',
          style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Have you successfully delivered this order to the customer?',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        print('🔍 Step 1: Fetching order data for: $orderId');
        
        // Get order details first
        final orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .get();
        
        if (!orderDoc.exists) {
          print('❌ Order document does not exist!');
          throw Exception('Order not found');
        }
        
        final orderData = orderDoc.data();
        print('✅ Step 2: Order data fetched successfully');
        print('   - Customer: ${orderData?['customerName']}');
        print('   - Rider: ${orderData?['riderName']}');

        // Update order status
        print('🔍 Step 3: Updating order status to Complete...');
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'orderStatus': 'Complete',
          'deliveredAt': FieldValue.serverTimestamp(),
        });
        print('✅ Step 4: Order status updated successfully');

        // ✅ CREATE ADMIN NOTIFICATION DIRECTLY (BACKUP METHOD)
        print('🔍 Step 5: Creating admin notification...');
        try {
          await FirebaseFirestore.instance.collection('admin_notifications').add({
            'type': 'order_delivered',
            'title': '🎉 Order Delivered',
            'message': 'Rider ${orderData?['riderName'] ?? 'Unknown Rider'} successfully delivered Order #${orderId.substring(0, 8).toUpperCase()} to ${orderData?['customerName'] ?? 'Unknown Customer'}',
            'orderId': orderId,
            'riderId': orderData?['riderId'],
            'riderName': orderData?['riderName'] ?? 'Unknown Rider',
            'customerId': orderData?['userId'],
            'customerName': orderData?['customerName'] ?? 'Unknown Customer',
            'orderStatus': 'Complete',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('✅ Step 6: Admin notification created successfully!');
        } catch (notifError) {
          print('❌ Error creating admin notification: $notifError');
          // Don't throw - order was already marked complete
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🎉 Order delivered successfully!'),
              backgroundColor: AppColors.richGold,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e, stackTrace) {
        print('❌ ERROR in _confirmDelivery: $e');
        print('📍 Stack trace: $stackTrace');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red[900],
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderId = FirebaseAuth.instance.currentUser?.uid;
    
    if (riderId == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: Text(
            'Please login as rider',
            style: TextStyle(color: AppColors.lightGold),
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
          'My Deliveries',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.lightGold),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.softGold.withOpacity(0.5),
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Active Deliveries'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrders(riderId),
          _buildCompletedOrders(riderId),
        ],
      ),
    );
  }

  Widget _buildActiveOrders(String riderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('orderStatus', whereIn: ['Out for Delivery', 'Assigned'])
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
                Icon(Icons.error, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
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
                  Icons.delivery_dining,
                  size: 80,
                  color: AppColors.richGold.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No active deliveries',
                  style: TextStyle(
                    color: AppColors.lightGold.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'New orders will appear here',
                  style: TextStyle(
                    color: AppColors.softGold.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            return _buildOrderCard(orderId, data, false);
          },
        );
      },
    );
  }

  Widget _buildCompletedOrders(String riderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('orderStatus', isEqualTo: 'Complete')
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
                Icon(Icons.error, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading completed orders',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.red.shade300, fontSize: 12),
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
                  Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.richGold.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No completed deliveries',
                  style: TextStyle(
                    color: AppColors.lightGold.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivered orders will appear here',
                  style: TextStyle(
                    color: AppColors.softGold.withOpacity(0.4),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;
        orders.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          final aTime = aData['deliveredAt'] as Timestamp?;
          final bTime = bData['deliveredAt'] as Timestamp?;
          
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          } else if (aTime != null) {
            return -1;
          } else if (bTime != null) {
            return 1;
          }
          
          final aOrderTime = aData['orderDate'] as Timestamp?;
          final bOrderTime = bData['orderDate'] as Timestamp?;
          
          if (aOrderTime != null && bOrderTime != null) {
            return bOrderTime.compareTo(aOrderTime);
          }
          
          return 0;
        });
        
        return RefreshIndicator(
          color: AppColors.richGold,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final data = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              return _buildOrderCard(orderId, data, true);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data, bool isCompleted) {
    final orderStatus = data['orderStatus'] ?? 'Unknown';
    
    final customerName = (data['customerName'] ?? 'N/A').toString();
    final customerPhone = (data['customerPhone'] ?? 'N/A').toString();
    final shippingAddress = (data['shippingAddress'] ?? 'N/A').toString();
    final city = (data['city'] ?? 'N/A').toString();
    
    final totalAmount = data['totalAmount'] ?? 0;
    final totalAmountStr = totalAmount is num 
        ? '\$${totalAmount.toStringAsFixed(2)}' 
        : '\$$totalAmount';

    String? deliveryDate;
    if (isCompleted && data['deliveredAt'] != null) {
      final timestamp = data['deliveredAt'] as Timestamp;
      final date = timestamp.toDate();
      deliveryDate = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted 
              ? AppColors.richGold.withOpacity(0.2)
              : AppColors.richGold.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isCompleted 
                ? Colors.transparent
                : AppColors.richGold.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.richGold.withOpacity(0.1)
                  : AppColors.richGold.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // ✅ FIXED: Use Expanded to prevent overflow
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 8).toUpperCase()}',
                            style: TextStyle(
                              color: AppColors.lightGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: $totalAmountStr',
                            style: TextStyle(
                              color: AppColors.softGold.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8), // ✅ Add spacing
                    // ✅ FIXED: Flexible status badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(orderStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(orderStatus),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(orderStatus),
                              color: _getStatusColor(orderStatus),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getStatusLabel(orderStatus),
                                style: TextStyle(
                                  color: _getStatusColor(orderStatus),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (deliveryDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.softGold.withOpacity(0.6),
                      ),
                      const SizedBox(width: 6),
                      Expanded( // ✅ FIXED: Prevent overflow
                        child: Text(
                          'Delivered: $deliveryDate',
                          style: TextStyle(
                            color: AppColors.softGold.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.person_outline, 'Customer', customerName),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.location_on_outlined, 'Address', '$shippingAddress, $city'),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.phone_outlined, 'Phone', customerPhone),
                
                if (!isCompleted) ...[
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFF2A2A2A), height: 1),
                  const SizedBox(height: 16),
                  
                  if (orderStatus == 'Assigned')
                    _buildActionButton(
                      label: 'Start Delivery',
                      icon: Icons.play_arrow,
                      onPressed: () => _startDelivery(orderId),
                    )
                  else if (orderStatus == 'Out for Delivery')
                    _buildActionButton(
                      label: 'Mark as Delivered',
                      icon: Icons.check_circle_outline,
                      onPressed: () => _confirmDelivery(orderId),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.richGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.richGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.softGold.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.softGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: AppColors.deepBlack,
          elevation: 4,
          shadowColor: AppColors.richGold.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Assigned':
        return const Color(0xFFD4AF37);
      case 'Out for Delivery':
        return const Color(0xFFC9B037);
      case 'Complete':
        return AppColors.richGold;
      default:
        return AppColors.softGold;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Assigned':
        return 'Assigned';
      case 'Out for Delivery':
        return 'In Transit';
      case 'Complete':
        return 'Delivered';
      default:
        return status;
    }
  }
}