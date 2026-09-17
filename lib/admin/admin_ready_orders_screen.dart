import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';
import '../constants/colors.dart';

class AdminReadyOrdersScreen extends StatelessWidget {
  const AdminReadyOrdersScreen({super.key});

  Future<String> _getVendorName(String vendorId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(vendorId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        return data?['name'] ?? data?['businessName'] ?? 'Unknown Vendor';
      }
      return 'Unknown Vendor';
    } catch (e) {
      return 'Unknown Vendor';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'Ready Orders',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('orderStatus', isEqualTo: 'Ready')
            .where('assignedToRider', isEqualTo: false)
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
                    Icons.inventory_2,
                    size: 80,
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Ready Orders',
                    style: TextStyle(
                      color: AppColors.lightGold.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Orders will appear here when vendors mark them as ready',
                    style: TextStyle(
                      color: AppColors.softGold.withOpacity(0.4),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
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
              final vendorId = data['vendorId'] as String?;
              
              final customerName = (data['customerName'] ?? 'N/A').toString();
              final customerEmail = (data['customerEmail'] ?? 'N/A').toString();
              final customerPhone = (data['customerPhone'] ?? 'N/A').toString();
              final shippingAddress = (data['shippingAddress'] ?? 'N/A').toString();
              final city = (data['city'] ?? 'N/A').toString();
              final zipCode = (data['zipCode'] ?? 'N/A').toString();
              final totalAmount = (data['totalAmount'] ?? 0).toString();
              final itemCount = (data['itemCount'] ?? 0).toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with Vendor Name
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.15),
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
                                // Fetch and display vendor name
                                if (vendorId != null)
                                  FutureBuilder<String>(
                                    future: _getVendorName(vendorId),
                                    builder: (context, vendorSnapshot) {
                                      return Text(
                                        'Vendor: ${vendorSnapshot.data ?? "Loading..."}',
                                        style: TextStyle(
                                          color: AppColors.softGold.withOpacity(0.7),
                                          fontSize: 11,
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Text(
                                    '$itemCount items',
                                    style: TextStyle(
                                      color: AppColors.softGold.withOpacity(0.7),
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: const Color(0xFFD4AF37),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Ready',
                                  style: TextStyle(
                                    color: const Color(0xFFD4AF37),
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

                    // Order Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.person_outline, 'Customer', customerName),
                          const SizedBox(height: 10),
                          _buildDetailRow(Icons.email_outlined, 'Email', customerEmail),
                          const SizedBox(height: 10),
                          _buildDetailRow(Icons.phone_outlined, 'Phone', customerPhone),
                          const SizedBox(height: 10),
                          _buildDetailRow(Icons.location_on_outlined, 'Address', '$shippingAddress, $city'),
                          const SizedBox(height: 10),
                          _buildDetailRow(Icons.pin_drop_outlined, 'ZIP Code', zipCode),
                          const SizedBox(height: 10),
                          _buildDetailRow(Icons.payments_outlined, 'Total', 'PKR $totalAmount'),
                          
                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFF2A2A2A), height: 1),
                          const SizedBox(height: 16),
                          
                          // Assign Rider Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.assignRider,
                                  arguments: orderId,
                                );
                              },
                              icon: const Icon(Icons.delivery_dining, size: 20),
                              label: const Text(
                                'Assign Rider',
                                style: TextStyle(
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
          child: Icon(icon, size: 16, color: AppColors.richGold),
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
}