import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/widgets/helpers/customer_notification_helper.dart';
import '../../constants/colors.dart';


class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({Key? key}) : super(key: key);

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _markReady(String orderId) async {
    print('========================================');
    print('🔥 BUTTON PRESSED! Order ID: $orderId');
    print('========================================');

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Mark as Ready',
          style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Is this order prepared and ready for rider pickup?',
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

    print('Dialog result: $confirmed');

    if (confirmed != true) {
      print('User cancelled');
      return;
    }

    try {
      print('Step 1: Fetching order...');
      
      // Get order
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        print('ERROR: Order not found');
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      print('Step 2: Order fetched');
      print('Customer: ${orderData['customerName']}');
      
      // Get vendor info
      final user = FirebaseAuth.instance.currentUser;
      String vendorName = 'Unknown Vendor';
      
      if (user != null) {
        print('Step 3: Fetching vendor info...');
        final vendorDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (vendorDoc.exists) {
          final vendorData = vendorDoc.data() as Map<String, dynamic>;
          vendorName = vendorData['name'] ?? 
                      vendorData['businessName'] ?? 
                      vendorData['displayName'] ?? 
                      'Unknown Vendor';
          print('Vendor name: $vendorName');
        }
      }

      print('Step 4: Updating order status...');
      
      // Update order
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'orderStatus': 'Ready',
            'readyAt': FieldValue.serverTimestamp(),
            'assignedToRider': false,
          });

      print('Step 5: Creating admin notification...');

      // Create admin notification
      await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
            'type': 'order_ready',
            'title': '✅ Order Ready for Pickup',
            'message': '$vendorName marked Order #${orderId.substring(0, 8).toUpperCase()} as ready. Customer: ${orderData['customerName'] ?? 'Unknown'}',
            'orderId': orderId,
            'vendorId': user?.uid,
            'vendorName': vendorName,
            'customerId': orderData['customerId'],
            'customerName': orderData['customerName'],
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

      print('Step 6: Sending customer notification...');

      // 🆕 SEND NOTIFICATION TO CUSTOMER
      await CustomerNotificationHelper.sendOrderReadyNotification(
        customerId: orderData['customerId'] ?? orderData['userId'] ?? '',
        orderId: orderId,
        orderNumber: orderId.substring(0, 8).toUpperCase(),
      );

      print('✅ SUCCESS! All notifications created!');
      print('========================================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Order marked as ready & customer notified'),
            backgroundColor: AppColors.richGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'Vendor Orders',
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
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Ready'),
            Tab(text: 'In Transit'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(user!.uid, ['Pending']),
          _buildOrdersList(user.uid, ['Ready']),
          _buildOrdersList(user.uid, ['Assigned', 'Out for Delivery']),
          _buildOrdersList(user.uid, ['Complete']),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String vendorId, List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .where('orderStatus', whereIn: statuses)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: AppColors.richGold.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${statuses.first.toLowerCase()} orders',
                  style: TextStyle(
                    color: AppColors.lightGold.withOpacity(0.6),
                    fontSize: 16,
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
            return _buildOrderCard(orderId, data);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final orderStatus = data['orderStatus'] ?? 'Unknown';
    
    final customerName = (data['customerName'] ?? 'N/A').toString();
    final customerPhone = (data['customerPhone'] ?? 'N/A').toString();
    final shippingAddress = (data['shippingAddress'] ?? 'N/A').toString();
    final city = (data['city'] ?? 'N/A').toString();
    final totalAmount = (data['totalAmount'] ?? 0).toString();
    final itemCount = (data['itemCount'] ?? 0).toString();
    final riderName = data['riderName']?.toString() ?? 'Not assigned';

    final isCompleted = orderStatus == 'Complete';
    final isPending = orderStatus == 'Pending';
    final isReady = orderStatus == 'Ready';
    final isInTransit = orderStatus == 'Assigned' || orderStatus == 'Out for Delivery';

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
        boxShadow: isCompleted
            ? []
            : [
                BoxShadow(
                  color: AppColors.richGold.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                        '$itemCount items • \$$totalAmount',
                        style: TextStyle(
                          color: AppColors.softGold.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      const SizedBox(width: 6),
                      Text(
                        orderStatus,
                        style: TextStyle(
                          color: _getStatusColor(orderStatus),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customer Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.person_outline, 'Customer', customerName),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.phone_outlined, 'Phone', customerPhone),
                const SizedBox(height: 10),
                _buildDetailRow(Icons.location_on_outlined, 'Delivery to', '$shippingAddress, $city'),
                
                if (isInTransit) ...[
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.delivery_dining, 'Rider', riderName),
                ],

                // Mark as Ready Button
                if (isPending) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2A2A2A), height: 1),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        print('🔥🔥🔥 InkWell tapped!');
                        _markReady(orderId);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.richGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2, size: 20, color: AppColors.deepBlack),
                            const SizedBox(width: 8),
                            Text(
                              'Mark as Ready',
                              style: TextStyle(
                                color: AppColors.deepBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                if (isReady) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.softGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: AppColors.softGold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Waiting for admin to assign rider',
                            style: TextStyle(
                              color: AppColors.softGold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isInTransit) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.softGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.softGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          color: AppColors.softGold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            orderStatus == 'Assigned' 
                                ? 'Rider assigned, waiting for pickup'
                                : 'Order is out for delivery',
                            style: TextStyle(
                              color: AppColors.softGold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (isCompleted) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.richGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.richGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.richGold,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order delivered successfully',
                                style: TextStyle(
                                  color: AppColors.richGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Delivered by: $riderName',
                                style: TextStyle(
                                  color: AppColors.softGold.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFB8A046);
      case 'Ready':
        return const Color(0xFFD4AF37);
      case 'Assigned':
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
}