import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/constants/colors.dart';
import 'package:mobileapp/routes/app_routes.dart';

class RiderDashboard extends StatefulWidget {
  const RiderDashboard({super.key});

  @override
  State<RiderDashboard> createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  Map<String, dynamic>? riderData;
  bool isLoading = true;
  int assignedOrders = 0;
  int completedOrders = 0;
  double totalEarnings = 0.0;
  Uint8List? riderImage;

  @override
  void initState() {
    super.initState();
    _loadRiderData();
  }

  Future<void> _loadRiderData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Get rider info
        final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        if (doc.exists) {
          final data = doc.data();

          // Convert imageBinary to Uint8List
          Uint8List? imageBytes;
          if (data?['imageBinary'] != null) {
            imageBytes = Uint8List.fromList(List<int>.from(data!['imageBinary']));
          }

          setState(() {
            riderData = data;
            riderImage = imageBytes;
          });
        }

        // Get order counts and calculate earnings
        final ordersSnapshot = await FirebaseFirestore.instance
            .collection('orders')
            .where('riderId', isEqualTo: userId)
            .get();

        int assigned = 0;
        int completed = 0;
        double earnings = 0.0;

        for (var doc in ordersSnapshot.docs) {
          final data = doc.data();
          final status = data['orderStatus'] ?? '';

          // Count assigned or out for delivery
          if (status == 'Assigned' || status == 'Out for Delivery') {
            assigned++;
          } else if (status == 'Complete' || status == 'Delivered') {
            completed++;
            earnings += (data['deliveryFee'] ?? 10).toDouble();
          }
        }

        setState(() {
          assignedOrders = assigned;
          completedOrders = completed;
          totalEarnings = earnings;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading rider data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  void _goToProfile() {
    if (riderData?['isAvailable'] == false) return; // Blocked - no action
    Navigator.pushNamed(context, AppRoutes.riderProfile).then((_) {
      _loadRiderData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );
    }

    bool isBlocked = riderData?['isAvailable'] == false;

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRiderData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _loadRiderData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBlocked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.block, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your account is currently blocked. Contact admin to reactivate.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildRiderInfoCard(isBlocked),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active',
                        assignedOrders.toString(),
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Completed',
                        completedOrders.toString(),
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildEarningsCard(),
                const SizedBox(height: 24),
                _buildActionButton(
                  context,
                  'View My Deliveries',
                  Icons.delivery_dining,
                  isBlocked ? null : () => Navigator.pushNamed(context, AppRoutes.riderOrders),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  'Edit Profile',
                  Icons.edit,
                  isBlocked ? null : _goToProfile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiderInfoCard(bool isBlocked) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isBlocked ? null : _goToProfile,
            child: CircleAvatar(
              radius: 35,
              backgroundColor: AppColors.richGold.withOpacity(0.2),
              backgroundImage: riderImage != null ? MemoryImage(riderImage!) : null,
              child: riderImage == null
                  ? Icon(Icons.delivery_dining, size: 35, color: AppColors.richGold)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riderData?['name'] ?? 'Rider',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.lightGold),
                ),
                const SizedBox(height: 4),
                Text(
                  riderData?['vehicleType'] ?? 'N/A',
                  style: TextStyle(fontSize: 14, color: AppColors.richGold.withOpacity(0.7)),
                ),
                Text(
                  riderData?['vehicleNumber'] ?? 'N/A',
                  style: TextStyle(fontSize: 12, color: AppColors.softGold.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: riderData?['isAvailable'] == true
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: riderData?['isAvailable'] == true ? Colors.green : Colors.red,
              ),
            ),
            child: Text(
              riderData?['isAvailable'] == true ? 'Available' : 'Offline',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: riderData?['isAvailable'] == true ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.richGold, AppColors.lightGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deepBlack.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet, color: AppColors.deepBlack, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Earnings',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.deepBlack.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.deepBlack),
                ),
                Text(
                  'From $completedOrders deliveries',
                  style: TextStyle(fontSize: 11, color: AppColors.deepBlack.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.softGold.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback? onTap) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.lightGold, AppColors.richGold]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: AppColors.richGold.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.deepBlack,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
