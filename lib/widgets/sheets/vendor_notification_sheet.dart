import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../routes/app_routes.dart';

class VendorNotificationSheet extends StatefulWidget {
  final String vendorId;

  const VendorNotificationSheet({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorNotificationSheet> createState() => _VendorNotificationSheetState();
}

class _VendorNotificationSheetState extends State<VendorNotificationSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildNotificationList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.richGold,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.lightGold,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.softGold, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: widget.vendorId)
          .where('orderStatus', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, orderSnapshot) {
        if (orderSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
        }

        final orders = orderSnapshot.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reviews')
              .where('vendorId', isEqualTo: widget.vendorId)
              .where('status', isEqualTo: 'approved')
              // Removed .where('vendorNotificationRead', isEqualTo: false)
              // → shows ALL approved reviews (read or unread)
              .snapshots(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
            }

            if (reviewSnapshot.hasError || orderSnapshot.hasError) {
              final error = reviewSnapshot.hasError ? reviewSnapshot.error : orderSnapshot.error;
              final errorStr = error.toString();

              if (kDebugMode) print('Stream error: $errorStr');

              // Better error UI for index missing
              final isIndexError = errorStr.contains('requires an index') ||
                  errorStr.contains('FAILED_PRECONDITION') ||
                  errorStr.contains('index');

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 80, color: Colors.redAccent),
                      const SizedBox(height: 24),
                      const Text(
                        'Error loading notifications',
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isIndexError
                            ? 'Missing Firestore index.\n\n1. Open the link from debug console\n2. Create the index in Firebase Console\n3. Wait 1–5 minutes\n4. Reload this sheet'
                            : errorStr,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 14, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final reviews = reviewSnapshot.data?.docs ?? [];

            if (orders.isEmpty && reviews.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: orders.length + reviews.length,
              itemBuilder: (context, index) {
                if (index < orders.length) {
                  return _buildOrderNotification(context, orders[index]);
                } else {
                  return _buildReviewNotification(context, reviews[index - orders.length]);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: AppColors.softGold.withOpacity(0.4)),
          const SizedBox(height: 24),
          const Text(
            'All caught up!',
            style: TextStyle(color: AppColors.lightGold, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'No new pending orders or approved reviews',
            style: TextStyle(color: AppColors.softGold.withOpacity(0.7), fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotification(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final orderId = doc.id.substring(0, 8).toUpperCase();
    final customerName = data['customerName'] ?? 'Customer';
    final customerPhone = data['customerPhone'] ?? 'N/A';
    final customerEmail = data['customerEmail'] ?? 'N/A';
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final productName = (data['items'] as List?)?.isNotEmpty == true
        ? data['items'][0]['name'] ?? 'Product'
        : 'Order';

    final address = data['shippingAddress']?.toString() ?? 'Address not available';

    return InkWell(
      onTap: () {
        doc.reference.update({'vendorNotificationRead': true});
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRoutes.vendorOrders);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customer: $customerName',
              style: TextStyle(color: AppColors.softGold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone, color: AppColors.softGold, size: 16),
                const SizedBox(width: 6),
                Text(customerPhone, style: TextStyle(color: AppColors.softGold.withOpacity(0.9), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.email, color: AppColors.softGold, size: 16),
                const SizedBox(width: 6),
                Text(customerEmail, style: TextStyle(color: AppColors.softGold.withOpacity(0.9), fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Colors.orangeAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(color: AppColors.softGold.withOpacity(0.85), fontSize: 14, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag, color: Colors.orange, size: 18),
                    const SizedBox(width: 6),
                    Text(productName, style: const TextStyle(color: Colors.orange, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewNotification(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final productName = data['productName'] ?? 'Product';
    final rating = data['rating'] ?? 0;
    final reviewText = data['review'] ?? data['comment'] ?? 'No comment';

    return InkWell(
      onTap: () {
        doc.reference.update({'vendorNotificationRead': true});
        Navigator.pop(context);
        Navigator.pushNamed(context, AppRoutes.vendorReviews);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withOpacity(0.25), Colors.orange.withOpacity(0.15)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Customer Review',
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Product: $productName',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$rating/5',
                        style: const TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reviewText,
                    style: TextStyle(
                      color: AppColors.softGold.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}