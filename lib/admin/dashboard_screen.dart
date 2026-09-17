import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool isLoading = true;
  
  int totalVendors = 0;
  int totalCustomers = 0;
  int totalRiders = 0;
  int pendingOrders = 0;
  int completedOrders = 0;
  int pendingProducts = 0;
  int approvedProducts = 0;
  int totalReviews = 0;
  int totalMessages = 0;
  double totalSales = 0.0;
  double pendingPayment = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() => isLoading = true);
    
    try {
      // Users
      final vendors = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'vendor')
          .get();
      
      final customers = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      
      final riders = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .get();

      // Orders
      final pending = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderStatus', isEqualTo: 'Pending')
          .get();
      
      final completed = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderStatus', isEqualTo: 'Complete')
          .get();

      // Calculate payments
      double completedSales = 0.0;
      for (var doc in completed.docs) {
        try {
          final data = doc.data();
          if (data['totalAmount'] != null) {
            completedSales += (data['totalAmount'] as num).toDouble();
          }
        } catch (e) {
          print('Error calculating completed sales: $e');
        }
      }

      double pendingPay = 0.0;
      for (var doc in pending.docs) {
        try {
          final data = doc.data();
          if (data['totalAmount'] != null) {
            pendingPay += (data['totalAmount'] as num).toDouble();
          }
        } catch (e) {
          print('Error calculating pending payment: $e');
        }
      }

      // Products
      final pendingProds = await FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: false)
          .get();
      
      final approvedProds = await FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .get();

      // Reviews
      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .get();

      // Messages
      final messages = await FirebaseFirestore.instance
          .collection('conversations')
          .get();

      if (!mounted) return;
      
      setState(() {
        totalVendors = vendors.size;
        totalCustomers = customers.size;
        totalRiders = riders.size;
        pendingOrders = pending.size;
        completedOrders = completed.size;
        totalSales = completedSales;
        pendingPayment = pendingPay;
        pendingProducts = pendingProds.size;
        approvedProducts = approvedProds.size;
        totalReviews = reviews.size;
        totalMessages = messages.size;
        isLoading = false;
      });

    } catch (e) {
      print('Dashboard Error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text(
          'Admin Dashboard',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.richGold),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            )
          : RefreshIndicator(
              color: AppColors.richGold,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Users'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Vendors',
                            '$totalVendors',
                            Icons.store,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Customers',
                            '$totalCustomers',
                            Icons.people,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      'Riders',
                      '$totalRiders',
                      Icons.delivery_dining,
                      Colors.purple,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Orders'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            '$pendingOrders',
                            Icons.pending_actions,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            '$completedOrders',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Payments'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Completed',
                            '\$${totalSales.toStringAsFixed(2)}',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            '\$${pendingPayment.toStringAsFixed(2)}',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Products'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            '$pendingProducts',
                            Icons.pending,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Approved',
                            '$approvedProducts',
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    _buildSectionHeader('Communication'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Reviews',
                            '$totalReviews',
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Messages',
                            '$totalMessages',
                            Icons.message,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.lightGold,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: AppColors.softGold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.lightGold,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}