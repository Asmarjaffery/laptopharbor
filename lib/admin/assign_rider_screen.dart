import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/widgets/helpers/customer_notification_helper.dart';
import '../constants/colors.dart';

class AssignRiderScreen extends StatefulWidget {
  final String orderId;

  const AssignRiderScreen({super.key, required this.orderId});

  @override
  State<AssignRiderScreen> createState() => _AssignRiderScreenState();
}

class _AssignRiderScreenState extends State<AssignRiderScreen> {
  String? selectedRiderId;
  String? selectedRiderName;
  bool isAssigning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'Assign Rider',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: Column(
        children: [
          // Order Info
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .doc(widget.orderId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data == null) {
                return const SizedBox.shrink();
              }

              final customerName = (data['customerName'] ?? 'N/A').toString();
              final customerPhone = (data['customerPhone'] ?? 'N/A').toString();
              final shippingAddress = (data['shippingAddress'] ?? 'N/A').toString();
              final city = (data['city'] ?? 'N/A').toString();
              final totalAmount = (data['totalAmount'] ?? 0).toString();

              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: AppColors.richGold,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Order #${widget.orderId.substring(0, 8).toUpperCase()}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.lightGold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoRow('Customer', customerName),
                          _buildInfoRow('Phone', customerPhone),
                          _buildInfoRow('Address', shippingAddress),
                          _buildInfoRow('City', city),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.richGold.withOpacity(0.2),
                                ),
                              ),
                            ),
                            child: _buildInfoRow('Total Amount', 'PKR $totalAmount', isAmount: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Section Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: AppColors.richGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Select Available Rider',
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Available Riders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'rider')
                  .where('isAvailable', isEqualTo: true)
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
                          Icons.delivery_dining,
                          size: 80,
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No available riders',
                          style: TextStyle(
                            color: AppColors.lightGold.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All riders are currently busy',
                          style: TextStyle(
                            color: AppColors.softGold.withOpacity(0.4),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final riders = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: riders.length,
                  itemBuilder: (context, index) {
                    final riderData = riders[index].data() as Map<String, dynamic>;
                    final riderId = riders[index].id;
                    final riderName = (riderData['name'] ?? 'Rider').toString();
                    final vehicleType = (riderData['vehicleType'] ?? 'Vehicle').toString();
                    final vehicleNumber = (riderData['vehicleNumber'] ?? 'N/A').toString();
                    final riderPhone = (riderData['phone'] ?? 'No phone').toString();

                    final isSelected = selectedRiderId == riderId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.richGold.withOpacity(0.15)
                            : AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.richGold
                              : AppColors.richGold.withOpacity(0.2),
                          width: isSelected ? 2 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.richGold.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            selectedRiderId = riderId;
                            selectedRiderName = riderName;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.richGold
                                      : AppColors.richGold.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.delivery_dining,
                                  color: isSelected
                                      ? AppColors.deepBlack
                                      : AppColors.richGold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      riderName,
                                      style: TextStyle(
                                        color: AppColors.lightGold,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$vehicleType - $vehicleNumber',
                                      style: TextStyle(
                                        color: AppColors.softGold.withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      riderPhone,
                                      style: TextStyle(
                                        color: AppColors.softGold.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.richGold,
                                  size: 28,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Assign Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.deepBlack,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: (selectedRiderId == null || isAssigning)
                    ? null
                    : _assignRider,
                icon: isAssigning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.deepBlack,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.check_circle, size: 24),
                label: Text(
                  isAssigning ? 'Assigning...' : 'Confirm Assignment',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  disabledBackgroundColor: Colors.grey.shade800,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: 5,
                  shadowColor: AppColors.richGold.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.softGold.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isAmount ? AppColors.richGold : AppColors.lightGold,
                fontSize: isAmount ? 16 : 13,
                fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Single _assignRider function with notification
  Future<void> _assignRider() async {
    if (selectedRiderId == null || selectedRiderName == null) return;

    setState(() => isAssigning = true);

    try {
      // Get order data first for customer ID
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      final orderData = orderDoc.data();
      if (orderData == null) {
        throw Exception('Order not found');
      }

      // Update order with rider assignment
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'riderId': selectedRiderId,
        'riderName': selectedRiderName,
        'assignedAt': FieldValue.serverTimestamp(),
        'orderStatus': 'Assigned',
        'assignedToRider': true,
      });

      // 🆕 SEND NOTIFICATION TO CUSTOMER
      await CustomerNotificationHelper.sendRiderAssignedNotification(
        customerId: orderData['userId'] ?? '',
        orderId: widget.orderId,
        orderNumber: widget.orderId.substring(0, 8).toUpperCase(),
        riderName: selectedRiderName!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.deepBlack),
                const SizedBox(width: 12),
                const Text('Rider assigned successfully!'),
              ],
            ),
            backgroundColor: AppColors.richGold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red[900],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAssigning = false);
    }
  }
}