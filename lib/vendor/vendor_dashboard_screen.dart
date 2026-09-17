import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import 'EditProfileScreen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  Map<String, dynamic>? vendorData;
  bool isLoading = true;

  // Product stats
  int totalProducts = 0;
  int approvedProducts = 0;
  int pendingProducts = 0;

  // Order stats
  int totalOrders = 0;
  int pendingOrders = 0;
  int completedOrders = 0;

  // Sales stats
  double totalSales = 0;
  double pendingSales = 0;
  double achievedSales = 0;

  // Other stats
  int totalReviews = 0;
  int totalMessages = 0;

  @override
  void initState() {
    super.initState();
    loadVendorData();
    loadDashboardStats();
  }

  Future<void> loadVendorData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(userId).get();

        setState(() {
          vendorData = doc.data();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading vendor data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // --- PRODUCTS ---
      final allProducts = await FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: userId)
          .get();

      final vendorProductIds = allProducts.docs.map((p) => p.id).toList();

      totalProducts = allProducts.size;
      approvedProducts =
          allProducts.docs.where((p) => p['isApproved'] == true).length;
      pendingProducts =
          allProducts.docs.where((p) => p['isApproved'] == false).length;

      // --- ORDERS ---
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: userId)
          .get();

      int pendingCount = 0;
      int completedCount = 0;
      double pendingAmount = 0;
      double completedAmount = 0;
      double totalAmount = 0;

      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final status = data['orderStatus'] ?? '';
        double amount = 0;
        final total = data['totalAmount'];
        if (total != null) {
          if (total is num) amount = total.toDouble();
          else if (total is String) amount = double.tryParse(total) ?? 0.0;
        }

        totalAmount += amount;

        if (status.toLowerCase() == 'pending') {
          pendingCount++;
          pendingAmount += amount;
        } else if (status.toLowerCase() == 'complete' ||
            status.toLowerCase() == 'completed') {
          completedCount++;
          completedAmount += amount;
        }
      }

      totalOrders = ordersSnapshot.size;
      pendingOrders = pendingCount;
      completedOrders = completedCount;
      totalSales = totalAmount;
      pendingSales = pendingAmount;
      achievedSales = completedAmount;

      // --- REVIEWS ---
      List<QueryDocumentSnapshot> reviewsDocs = [];
      if (vendorProductIds.isNotEmpty) {
        const batchSize = 10; // Firestore whereIn limit
        for (var i = 0; i < vendorProductIds.length; i += batchSize) {
          var batch = vendorProductIds.sublist(
              i,
              i + batchSize > vendorProductIds.length
                  ? vendorProductIds.length
                  : i + batchSize);
          final reviewsSnapshot = await FirebaseFirestore.instance
              .collection('reviews')
              .where('productId', whereIn: batch)
              .get();
          reviewsDocs.addAll(reviewsSnapshot.docs);
        }
      }
      totalReviews = reviewsDocs.length;

      // --- MESSAGES ---
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('vendorId', isEqualTo: userId)
          .get();
      totalMessages = messagesSnapshot.size;

      setState(() {});
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isBlocked = vendorData?['isAvailable'] == false;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : RefreshIndicator(
              color: AppColors.richGold,
              backgroundColor: AppColors.cardBlack,
              onRefresh: () async {
                await loadVendorData();
                await loadDashboardStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isBlocked)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        color: Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.block, color: Colors.white),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your account is currently blocked. Contact support to reactivate.',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildProfileCard(),
                    const SizedBox(height: 20),
                    _buildDashboardStats(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    if (vendorData == null) return SizedBox.shrink();

    String name = vendorData!['name'] ?? 'Vendor';
    String shopName = vendorData!['shopName'] ?? 'Shop Name';
    bool isAvailable = vendorData!['isAvailable'] ?? true;

    Uint8List? imageBytes;
    if (vendorData!['imageBinary'] != null) {
      try {
        var imgData = vendorData!['imageBinary'];
        if (imgData is Uint8List) {
          imageBytes = imgData;
        } else if (imgData is List) {
          imageBytes = Uint8List.fromList(List<int>.from(imgData));
        }
      } catch (e) {
        print('Error loading image: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cardBlack, AppColors.deepBlack],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          imageBytes != null
              ? CircleAvatar(radius: 50, backgroundImage: MemoryImage(imageBytes))
              : CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.richGold,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'V',
                    style: TextStyle(
                        color: AppColors.deepBlack,
                        fontSize: 32,
                        fontWeight: FontWeight.bold),
                  ),
                ),
          const SizedBox(height: 16),
          Text(name,
              style: TextStyle(
                  color: AppColors.lightGold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store, size: 16, color: AppColors.richGold),
              const SizedBox(width: 6),
              Text(shopName,
                  style: TextStyle(color: AppColors.softGold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isAvailable ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isAvailable ? Colors.green : Colors.red),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Blocked',
              style: TextStyle(color: isAvailable ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Overview',
            style: TextStyle(
                color: AppColors.lightGold,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(Icons.inventory_2, 'Total Products', totalProducts.toString(), AppColors.richGold),
            _buildStatCard(Icons.check_circle, 'Approved Products', approvedProducts.toString(), Colors.green),
            _buildStatCard(Icons.pending, 'Pending Products', pendingProducts.toString(), Colors.orange),
            _buildStatCard(Icons.shopping_bag, 'Total Orders', totalOrders.toString(), AppColors.richGold),
            _buildStatCard(Icons.pending_actions, 'Pending Orders', pendingOrders.toString(), Colors.orangeAccent),
            _buildStatCard(Icons.check_circle_outline, 'Completed Orders', completedOrders.toString(), Colors.greenAccent),
            _buildStatCard(Icons.attach_money, 'Total Sales', '\$${totalSales.toStringAsFixed(2)}', Colors.amber),
            _buildStatCard(Icons.money_off, 'Pending Sales', '\$${pendingSales.toStringAsFixed(2)}', Colors.orange),
            _buildStatCard(Icons.monetization_on, 'Achieved Sales', '\$${achievedSales.toStringAsFixed(2)}', Colors.green),
            _buildStatCard(Icons.rate_review, 'Total Reviews', totalReviews.toString(), Colors.blueAccent),
            _buildStatCard(Icons.message, 'Total Messages', totalMessages.toString(), Colors.purpleAccent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Card(
      color: AppColors.cardBlack,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    color: AppColors.softGold.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
