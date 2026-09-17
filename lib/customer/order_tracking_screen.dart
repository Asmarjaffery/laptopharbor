import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/models/order_model.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  String? _productName;
  List<Map<String, dynamic>>? _enrichedProducts;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      final name = await widget.order.getFirstProductName();
      final products = await widget.order.getProductsWithNames();
      
      if (mounted) {
        setState(() {
          _productName = name;
          _enrichedProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading product details: $e');
      if (mounted) {
        setState(() {
          _productName = 'Order #${widget.order.id?.substring(0, 8).toUpperCase() ?? ""}';
          _enrichedProducts = widget.order.products;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.lightGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Track Order',
          style: AppStyles.headingStyle.copyWith(fontSize: 20),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.order.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          final updatedOrder = OrderModel.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildProductHeader(_isLoading ? 'Loading...' : (_productName ?? 'Your Order')),
                const SizedBox(height: 16),
                _buildStatusCard(updatedOrder),
                const SizedBox(height: 24),
                _buildCompactTimeline(updatedOrder.status),
                const SizedBox(height: 24),
                if (_enrichedProducts != null && _enrichedProducts!.isNotEmpty)
                  _buildProductsList(_enrichedProducts!)
                else if (updatedOrder.products != null && updatedOrder.products!.isNotEmpty)
                  _buildProductsList(updatedOrder.products!),
                const SizedBox(height: 24),
                _buildOrderDetails(updatedOrder),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Shows the main product name at the top
  Widget _buildProductHeader(String productName) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3), width: 1.5),
      ),
      child: Text(
        productName,
        style: AppStyles.headingStyle.copyWith(
          fontSize: 18,
          color: AppColors.richGold,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusCard(OrderModel order) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            order.getStatusColor().withOpacity(0.15),
            order.getStatusColor().withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: order.getStatusColor().withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: order.getStatusColor().withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: order.getStatusColor().withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: order.getStatusColor().withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              order.getStatusIcon(),
              color: order.getStatusColor(),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            order.getStatusTitle(),
            style: AppStyles.headingStyle.copyWith(
              color: order.getStatusColor(),
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order.getStatusMessage(),
            style: AppStyles.bodyStyle.copyWith(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (order.riderName != null &&
              (order.status == 'Assigned' || order.status == 'Out for Delivery')) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.richGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delivery_dining, color: AppColors.richGold, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Rider: ${order.riderName}',
                    style: AppStyles.bodyStyle.copyWith(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductsList(List<Map<String, dynamic>> products) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.shopping_bag_outlined, 'Products'),
          const SizedBox(height: 16),
          ...products.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            
            // Handle missing name field with multiple fallbacks
            final name = product['name'] ?? 
                        product['productName'] ?? 
                        'Product #${index + 1}';
            final quantity = product['quantity'] ?? 1;
            final price = (product['price'] ?? 0.0).toDouble();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$name x$quantity',
                      style: AppStyles.bodyStyle.copyWith(
                        fontSize: 14,
                        color: AppColors.lightGold,
                      ),
                    ),
                  ),
                  Text(
                    '\$${(price * quantity).toStringAsFixed(2)}',
                    style: AppStyles.bodyStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightGold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.receipt_long, 'Order Information'),
          const SizedBox(height: 16),
          _buildInfoRow('Order ID', '#${order.id?.substring(0, 10).toUpperCase() ?? "N/A"}'),
          _buildInfoRow('Date', _formatDate(order.orderDate)),
          _buildInfoRow('Payment', order.paymentMethod),
          _buildInfoRow('Items', '${order.itemCount} items'),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildSectionHeader(Icons.person_outline, 'Customer Details'),
          const SizedBox(height: 16),
          _buildInfoRow('Name', order.customerName),
          _buildInfoRow('Phone', order.customerPhone),
          _buildInfoRow('Email', order.customerEmail),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildSectionHeader(Icons.local_shipping_outlined, 'Shipping Address'),
          const SizedBox(height: 16),
          _buildInfoRow('Address', order.shippingAddress),
          _buildInfoRow('City', order.city),
          _buildInfoRow('ZIP Code', order.zipCode),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildSectionHeader(Icons.receipt, 'Order Summary'),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', order.subtotal),
          const SizedBox(height: 10),
          _buildSummaryRow('Shipping', order.shippingCost),
          const SizedBox(height: 16),
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.richGold.withOpacity(0.2),
                  AppColors.richGold.withOpacity(0.6),
                  AppColors.richGold.withOpacity(0.2),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: AppStyles.subHeadingStyle.copyWith(
                  fontSize: 16,
                  color: AppColors.richGold,
                ),
              ),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: AppStyles.cardValueStyle.copyWith(
                  fontSize: 22,
                  color: AppColors.richGold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.richGold.withOpacity(0.2),
                AppColors.richGold.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.richGold, size: 20),
        ),
        const SizedBox(width: 12),
        Text(title, style: AppStyles.subHeadingStyle.copyWith(fontSize: 16)),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppStyles.smallTextStyle.copyWith(
                fontSize: 13,
                color: AppColors.softGold.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppStyles.bodyStyle.copyWith(
                fontSize: 13,
                color: AppColors.lightGold,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppStyles.bodyStyle.copyWith(fontSize: 14)),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: AppStyles.bodyStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.lightGold,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.richGold.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactTimeline(String orderStatus) {
    final steps = [
      {'status': 'Pending', 'title': 'Placed', 'icon': Icons.receipt_long},
      {'status': 'Ready', 'title': 'Ready', 'icon': Icons.inventory_2},
      {'status': 'Assigned', 'title': 'Assigned', 'icon': Icons.assignment},
      {'status': 'Out for Delivery', 'title': 'Shipping', 'icon': Icons.local_shipping},
      {'status': 'Complete', 'title': 'Delivered', 'icon': Icons.check_circle},
    ];

    int currentIndex = steps.indexWhere((s) => s['status'] == orderStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.timeline, 'Order Timeline'),
          const SizedBox(height: 24),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: stepIndex < currentIndex
                            ? [AppColors.richGold, AppColors.richGold]
                            : [
                                AppColors.softGold.withOpacity(0.2),
                                AppColors.softGold.withOpacity(0.2),
                              ],
                      ),
                    ),
                  ),
                );
              } else {
                final stepIndex = index ~/ 2;
                final step = steps[stepIndex];
                final isCompleted = stepIndex < currentIndex;
                final isActive = stepIndex == currentIndex;

                return Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive
                            ? AppColors.richGold
                            : AppColors.deepBlack,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive || isCompleted
                              ? AppColors.richGold
                              : AppColors.softGold.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: isActive || isCompleted
                            ? [
                                BoxShadow(
                                  color: AppColors.richGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        color: isCompleted || isActive
                            ? AppColors.deepBlack
                            : AppColors.softGold.withOpacity(0.5),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        step['title'] as String,
                        style: AppStyles.smallTextStyle.copyWith(
                          color: isActive || isCompleted
                              ? AppColors.lightGold
                              : AppColors.softGold.withOpacity(0.5),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}