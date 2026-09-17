import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class AdminOrderManagerScreen extends StatefulWidget {
  const AdminOrderManagerScreen({super.key});

  @override
  State<AdminOrderManagerScreen> createState() =>
      _AdminOrderManagerScreenState();
}

class _AdminOrderManagerScreenState extends State<AdminOrderManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showStats = false;

  // Cache for vendor names
  Map<String, String> _vendorNameCache = {};

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

  Future<String> _getVendorName(String? vendorId, String? vendorName) async {
    // If vendorName already exists, return it
    if (vendorName != null && vendorName.isNotEmpty && vendorName != 'Unknown Vendor') {
      return vendorName;
    }

    // If no vendorId, return unknown
    if (vendorId == null || vendorId.isEmpty) {
      return 'Unknown Vendor';
    }

    // Check cache first
    if (_vendorNameCache.containsKey(vendorId)) {
      return _vendorNameCache[vendorId]!;
    }

    // Fetch from Firestore
    try {
      final vendorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(vendorId)
          .get();

      if (vendorDoc.exists) {
        final data = vendorDoc.data() as Map<String, dynamic>;
        final name = data['shopName'] ?? data['name'] ?? 'Unknown Vendor';
        _vendorNameCache[vendorId] = name;
        return name;
      }
    } catch (e) {
      print('Error fetching vendor name: $e');
    }

    return 'Unknown Vendor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'All Orders',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showStats ? Icons.list : Icons.analytics,
              color: AppColors.richGold,
            ),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
          ),
        ],
        bottom: _showStats
            ? null
            : TabBar(
                controller: _tabController,
                indicatorColor: AppColors.richGold,
                labelColor: AppColors.richGold,
                unselectedLabelColor: AppColors.softGold.withOpacity(0.5),
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Ready'),
                  Tab(text: 'In Transit'),
                  Tab(text: 'Completed'),
                ],
              ),
      ),
      body: _showStats
          ? _buildStatsView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(['Pending']),
                _buildOrdersList(['Ready']),
                _buildOrdersList(['Assigned', 'Out for Delivery']),
                _buildOrdersList(['Complete']),
              ],
            ),
    );
  }

  // ================= STATS VIEW =================

  Widget _buildStatsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No order data available',
              style: TextStyle(color: AppColors.softGold),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        // Calculate statistics
        Map<String, Map<String, dynamic>> vendorStats = {};
        Map<String, int> riderStats = {};
        Map<String, int> statusCounts = {
          'Pending': 0,
          'Ready': 0,
          'Assigned': 0,
          'Out for Delivery': 0,
          'Complete': 0,
        };

        for (var order in orders) {
          final data = order.data() as Map<String, dynamic>;
          final status = data['orderStatus'] ?? 'Unknown';
          final vendorId = data['vendorId'] ?? 'Unknown';
          final vendorName = data['vendorName'] ?? 'Unknown Vendor';
          final riderName = data['riderName'] ?? '';

          // Count by status
          if (statusCounts.containsKey(status)) {
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }

          // Count by vendor
          if (!vendorStats.containsKey(vendorId)) {
            vendorStats[vendorId] = {
              'name': vendorName,
              'total': 0,
              'pending': 0,
              'completed': 0,
            };
          }
          vendorStats[vendorId]!['total'] =
              (vendorStats[vendorId]!['total'] ?? 0) + 1;

          if (status == 'Complete') {
            vendorStats[vendorId]!['completed'] =
                (vendorStats[vendorId]!['completed'] ?? 0) + 1;
          } else if (status == 'Pending' || status == 'Ready') {
            vendorStats[vendorId]!['pending'] =
                (vendorStats[vendorId]!['pending'] ?? 0) + 1;
          }

          // Count by rider
          if (riderName.isNotEmpty && riderName != 'Not assigned') {
            riderStats[riderName] = (riderStats[riderName] ?? 0) + 1;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Stats
              _buildStatCard(
                'Overall Statistics',
                [
                  _statRow('Total Orders', orders.length.toString()),
                  _statRow('Pending', statusCounts['Pending'].toString()),
                  _statRow('Ready', statusCounts['Ready'].toString()),
                  _statRow(
                      'In Transit',
                      ((statusCounts['Assigned'] ?? 0) +
                              (statusCounts['Out for Delivery'] ?? 0))
                          .toString()),
                  _statRow('Completed', statusCounts['Complete'].toString()),
                ],
              ),
              const SizedBox(height: 16),

              // Vendor Stats
              _buildStatCard(
                'Vendor Statistics',
                vendorStats.entries.map((entry) {
                  final vendorData = entry.value;
                  return _expandableVendorStat(
                    entry.key,
                    vendorData,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Rider Stats
              _buildStatCard(
                'Rider Statistics',
                riderStats.entries.map((entry) {
                  return _statRow(entry.key, '${entry.value} deliveries');
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.richGold),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.softGold, fontSize: 14),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.lightGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandableVendorStat(String vendorId, Map<String, dynamic> stats) {
    return FutureBuilder<String>(
      future: _getVendorName(vendorId, stats['name']),
      builder: (context, snapshot) {
        final vendorName = snapshot.data ?? stats['name'] ?? 'Loading...';
        
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            vendorName,
            style: TextStyle(color: AppColors.lightGold, fontSize: 14),
          ),
          trailing: Text(
            '${stats['total']} orders',
            style: TextStyle(
              color: AppColors.richGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: AppColors.richGold,
          collapsedIconColor: AppColors.softGold,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Column(
                children: [
                  _statRow('Pending', stats['pending'].toString()),
                  _statRow('Completed', stats['completed'].toString()),
                  _statRow(
                      'In Progress',
                      (stats['total']! -
                              stats['pending']! -
                              stats['completed']!)
                          .toString()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ================= ORDERS LIST =================

  Widget _buildOrdersList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('orderStatus', whereIn: statuses)
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
                Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                Icon(Icons.inbox,
                    color: AppColors.softGold.withOpacity(0.5), size: 64),
                const SizedBox(height: 16),
                Text(
                  'No orders found',
                  style: TextStyle(color: AppColors.softGold),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;

        // Sort manually after fetching
        orders.sort((a, b) {
          final aDate =
              (a.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
          final bDate =
              (b.data() as Map<String, dynamic>)['orderDate'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            return _buildOrderCard(orders[index].id, data);
          },
        );
      },
    );
  }

  // ================= ORDER CARD =================

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data) {
    final orderStatus = data['orderStatus'] ?? 'Unknown';
    final customerName = (data['customerName'] ?? 'N/A').toString();
    final customerPhone = (data['customerPhone'] ?? 'N/A').toString();
    final address = (data['shippingAddress'] ?? 'N/A').toString();
    final city = (data['city'] ?? 'N/A').toString();
    final double totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

    final vendorId = data['vendorId'];
    final vendorName = data['vendorName'];
    final riderName = data['riderName'] ?? 'Not assigned';
    final assignedToRider = data['assignedToRider'] ?? false;

    final isCompleted = orderStatus == 'Complete';
    final isReady = orderStatus == 'Ready';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(orderStatus),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _getStatusColor(orderStatus).withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${orderId.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: \$${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.softGold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                _statusChip(orderStatus),
              ],
            ),
          ),

          // BODY
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Information with FutureBuilder
                FutureBuilder<String>(
                  future: _getVendorName(vendorId, vendorName),
                  builder: (context, snapshot) {
                    final displayName = snapshot.data ?? 'Loading...';
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.richGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.store, color: AppColors.richGold, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Vendor',
                                  style: TextStyle(
                                    color: AppColors.softGold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: AppColors.lightGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Order Items
                _buildOrderItems(data),

                const SizedBox(height: 12),

                // Customer Information
                _infoRow(Icons.person, 'Customer', customerName),
                _infoRow(Icons.phone, 'Phone', customerPhone),
                _infoRow(Icons.location_on, 'Address', '$address, $city'),

                // Rider Information
                if (assignedToRider && riderName != 'Not assigned')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.delivery_dining, 
                            size: 16, 
                            color: AppColors.richGold),
                        const SizedBox(width: 8),
                        Text(
                          'Rider: ',
                          style: TextStyle(color: AppColors.softGold),
                        ),
                        Expanded(
                          child: Text(
                            riderName,
                            style: TextStyle(
                              color: AppColors.lightGold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isReady && !assignedToRider) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delivery_dining),
                      label: const Text('Assign Rider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.assignRider,
                          arguments: orderId,
                        );
                      },
                    ),
                  ),
                ],

                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: AppColors.richGold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Order Delivered Successfully',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>? ?? [];
    
    if (items.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.softGold.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: AppColors.richGold, size: 16),
              const SizedBox(width: 6),
              Text(
                'Order Items (${items.length})',
                style: TextStyle(
                  color: AppColors.richGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) {
            final itemData = item as Map<String, dynamic>;
            final productName = itemData['productName'] ?? 'Unknown Product';
            final quantity = itemData['quantity'] ?? 1;
            final price = (itemData['price'] as num?)?.toDouble() ?? 0.0;
            final imageBase64 = itemData['imageBase64'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _buildProductThumbnail(imageBase64),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: TextStyle(
                            color: AppColors.lightGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Qty: $quantity',
                              style: TextStyle(
                                color: AppColors.softGold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.richGold,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildProductThumbnail(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: AppColors.softGold,
          size: 20,
        ),
      );
    }

    try {
      final Uint8List bytes = base64Decode(imageBase64);
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.broken_image,
          color: Colors.redAccent,
          size: 20,
        ),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.richGold),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: AppColors.softGold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.lightGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getStatusColor(status)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Ready':
        return Colors.blue;
      case 'Assigned':
      case 'Out for Delivery':
        return Colors.purple;
      case 'Complete':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}