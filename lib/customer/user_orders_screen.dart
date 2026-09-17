import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/models/order_model.dart';
import 'package:mobileapp/routes/app_routes.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({Key? key}) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return const Color(0xFFFF9800);
      case 'Ready':
        return const Color(0xFF2196F3);
      case 'Assigned':
        return const Color(0xFF9C27B0);
      case 'Out for Delivery':
        return const Color(0xFFFFEB3B);
      case 'Complete':
        return const Color(0xFF4CAF50);
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

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: AppColors.richGold.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Please login to view orders',
                style: AppStyles.subHeadingStyle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to track your orders',
                style: AppStyles.bodyStyle,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.lightGold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('My Orders', style: AppStyles.headingStyle.copyWith(fontSize: 20)),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.richGold),
                  const SizedBox(height: 16),
                  Text('Loading orders...', style: AppStyles.bodyStyle),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Orders',
                      style: AppStyles.subHeadingStyle.copyWith(
                        color: Colors.red,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later',
                      style: AppStyles.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.richGold.withOpacity(0.2),
                          AppColors.richGold.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 80,
                      color: AppColors.richGold.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Orders Yet',
                    style: AppStyles.headingStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Start shopping to see your orders here',
                      style: AppStyles.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.shopping_cart, color: AppColors.deepBlack),
                    label: Text('Start Shopping', style: AppStyles.buttonTextStyle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort orders by date (most recent first)
          List<QueryDocumentSnapshot> orders = snapshot.data!.docs;
          orders.sort((a, b) {
            Timestamp? aTimestamp = (a.data() as Map<String, dynamic>)['orderDate'];
            Timestamp? bTimestamp = (b.data() as Map<String, dynamic>)['orderDate'];
            if (aTimestamp == null || bTimestamp == null) return 0;
            return bTimestamp.compareTo(aTimestamp);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var orderDoc = orders[index];
              
              // Create OrderModel from Firestore document
              final order = OrderModel.fromFirestore(orderDoc);

              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTracking(context, order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id?.substring(0, 8).toUpperCase() ?? "N/A"}',
                            style: AppStyles.cardTitleStyle.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: AppColors.softGold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(order.orderDate),
                                style: AppStyles.smallTextStyle,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.richGold.withOpacity(0.1),
                        AppColors.richGold.withOpacity(0.3),
                        AppColors.richGold.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Order Details Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Items',
                        value: '${order.itemCount}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.softGold.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.payment,
                        label: 'Payment',
                        value: order.paymentMethod,
                        valueSize: 13,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.softGold.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        icon: Icons.attach_money,
                        label: 'Total',
                        value: '\$${order.totalAmount.toStringAsFixed(2)}',
                        valueColor: AppColors.richGold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Track Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _navigateToTracking(context, order),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.richGold, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppColors.richGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Track Order',
                          style: AppStyles.outlinedButtonTextStyle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(status).withOpacity(0.2),
            _getStatusColor(status).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(status),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            size: 14,
            color: _getStatusColor(status),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: AppStyles.smallTextStyle.copyWith(
              color: _getStatusColor(status),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    double? valueSize,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.softGold.withOpacity(0.6),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppStyles.smallTextStyle.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppStyles.cardValueStyle.copyWith(
            fontSize: valueSize ?? 14,
            color: valueColor ?? AppColors.lightGold,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _navigateToTracking(BuildContext context, OrderModel order) {
    Navigator.pushNamed(
      context,
      AppRoutes.orderTracking,
      arguments: order,
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}