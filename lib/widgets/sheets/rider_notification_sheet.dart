import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/colors.dart';
import '../../routes/app_routes.dart';

class RiderNotificationSheet extends StatefulWidget {
  final String riderId;

  const RiderNotificationSheet({
    super.key,
    required this.riderId,
  });

  @override
  State<RiderNotificationSheet> createState() => _RiderNotificationSheetState();
}

class _RiderNotificationSheetState extends State<RiderNotificationSheet> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('RiderNotificationSheet opened with riderId: ${widget.riderId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F), // Facebook dark theme black
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_rounded, color: Color(0xFF1877F2), size: 28), // Facebook blue
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 28),
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
          .where('riderId', isEqualTo: widget.riderId)
          .where('orderStatus', whereIn: ['Pending', 'Assigned'])
          .orderBy('assignedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1877F2)));
        }

        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          if (kDebugMode) print('Stream error: $error');

          final isIndexError = error.contains('index') || error.contains('FAILED_PRECONDITION');

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
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isIndexError
                        ? 'Missing Firestore index.\nOpen debug console link → Create index → Wait 1–5 min → Restart app'
                        : error,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final orders = snapshot.data?.docs ?? [];

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: orders.length,
          itemBuilder: (context, index) => _buildOrderCard(context, orders[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 24),
          const Text(
            'No new notifications',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'New delivery assignments will appear here',
            style: TextStyle(color: Colors.white70, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final orderId = doc.id.substring(0, 8).toUpperCase();
    final customerName = data['customerName'] ?? 'Customer';
    final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final orderStatus = data['orderStatus'] ?? 'Pending';
    final customerPhone = data['customerPhone'] ?? 'N/A';
    final address = data['shippingAddress']?.toString() ?? 'Address not available';

    // Vendor name from vendorId (real-time fetch)
    final vendorId = data['vendorId'] as String?;

    // Assigned date
    String assignedDate = '—';
    final assignedAt = data['assignedAt'];
    if (assignedAt is Timestamp) {
      try {
        final date = assignedAt.toDate();
        assignedDate = DateFormat('dd MMM • HH:mm').format(date);
      } catch (_) {}
    }

    final bool isUnread = data['riderNotificationRead'] != true;

    return FutureBuilder<DocumentSnapshot>(
      future: vendorId != null
          ? FirebaseFirestore.instance.collection('users').doc(vendorId).get()
          : null,
      builder: (context, vendorSnapshot) {
        String vendorName = 'Vendor';
        if (vendorSnapshot.hasData && vendorSnapshot.data!.exists) {
          vendorName = vendorSnapshot.data!['name'] ?? vendorSnapshot.data!['shopName'] ?? 'Vendor';
        }

        return InkWell(
          onTap: () {
            // Mark as read (optional)
            doc.reference.update({'riderNotificationRead': true});
            Navigator.pop(context);
            Navigator.pushNamed(context, AppRoutes.riderOrders);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnread ? const Color(0xFF0A1F3A) : const Color(0xFF121212), // Facebook unread blue tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread ? const Color(0xFF1877F2).withOpacity(0.3) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left blue line for unread
                if (isUnread)
                  Container(
                    width: 4,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1877F2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                const SizedBox(width: 12),

                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF1877F2), size: 28),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'New Delivery - $vendorName',
                              style: TextStyle(
                                color: isUnread ? Colors.white : Colors.white70,
                                fontSize: 16,
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #$orderId • $assignedDate',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customer: $customerName',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            orderStatus.toUpperCase(),
                            style: TextStyle(
                              color: orderStatus == 'Assigned' ? Colors.orange : Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}