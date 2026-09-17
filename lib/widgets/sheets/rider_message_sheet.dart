import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/colors.dart';

class RiderMessageSheet extends StatefulWidget {
  final String riderId;

  const RiderMessageSheet({
    super.key,
    required this.riderId,
  });

  @override
  State<RiderMessageSheet> createState() => _RiderMessageSheetState();
}

class _RiderMessageSheetState extends State<RiderMessageSheet> {
  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final query = FirebaseFirestore.instance
          .collection('withdrawals')
          .where('riderId', isEqualTo: widget.riderId)
          .where('status', whereIn: ['approved', 'completed'])
          .where('riderMessageRead', isEqualTo: false);

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'riderMessageRead': true});
      }

      await batch.commit();

      if (kDebugMode) {
        debugPrint('Marked ${snapshot.docs.length} rider messages as read');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error marking rider messages read: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMessageList()),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mail_rounded,
              color: AppColors.richGold,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Messages',
              style: TextStyle(
                color: AppColors.lightGold,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.softGold, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('withdrawals')
          .where('riderId', isEqualTo: widget.riderId)
          .where('status', whereIn: ['approved', 'completed'])
          .orderBy('requestDate', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
        }

        if (snapshot.hasError) {
          final errorStr = snapshot.error.toString();
          final isIndexError = errorStr.contains('requires an index') ||
              errorStr.contains('FAILED_PRECONDITION') ||
              errorStr.contains('index');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 72, color: Colors.redAccent),
                  const SizedBox(height: 24),
                  const Text(
                    'Error loading messages',
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

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) => _buildMessageItem(docs[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.deepBlack,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 72,
              color: AppColors.softGold.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              color: AppColors.lightGold,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Withdrawal approval / completion updates\nwill appear here',
            style: TextStyle(
              color: AppColors.softGold.withOpacity(0.65),
              fontSize: 15,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract fields safely with correct types
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final paymentMethod = data['paymentMethod']?.toString() ?? 'N/A';
    final accountDetails = data['accountDetails']?.toString() ?? 'N/A';
    final isRead = data['riderMessageRead'] == true;

    // ── Date formatting ──────────────────────────────────────────────
    String dateStr = '—';
    final requestDate = data['requestDate'];

    if (requestDate is Timestamp) {
      try {
        final date = requestDate.toDate();
        // Format suitable for Pakistan (24-hour + month name)
        dateStr = DateFormat('dd MMM yyyy • HH:mm', 'en_US').format(date);
        // Alternative common in Pakistan: dateStr = DateFormat('dd-MM-yyyy HH:mm').format(date);
      } catch (e) {
        if (kDebugMode) debugPrint('Date parse error: $e');
        dateStr = 'Invalid date';
      }
    } else if (requestDate != null) {
      dateStr = requestDate.toString();
    }

    final bool isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.5) : AppColors.richGold.withOpacity(0.45),
          width: 1.2,
        ),
        boxShadow: isRead
            ? null
            : [
                BoxShadow(
                  color: AppColors.richGold.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCompleted
                    ? [Colors.green.withOpacity(0.25), Colors.teal.withOpacity(0.12)]
                    : [AppColors.richGold.withOpacity(0.25), AppColors.lightGold.withOpacity(0.12)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: isCompleted ? Colors.green[400] : AppColors.richGold,
              size: 28,
            ),
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
                        'Withdrawal ${status.toUpperCase()}',
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 16.5,
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded, color: AppColors.richGold, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '\$${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      paymentMethod.toLowerCase().contains('jazzcash') ||
                              paymentMethod.toLowerCase().contains('mobile')
                          ? Icons.phone_android_rounded
                          : Icons.account_balance,
                      size: 16,
                      color: AppColors.softGold.withOpacity(0.75),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$paymentMethod • $accountDetails',
                        style: TextStyle(
                          color: AppColors.softGold.withOpacity(0.75),
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppColors.softGold.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: AppColors.softGold.withOpacity(0.6),
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withOpacity(0.18)
                            : AppColors.richGold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: isCompleted ? Colors.green[300] : AppColors.richGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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
  }
}