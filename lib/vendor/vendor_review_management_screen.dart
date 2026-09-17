import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';

class VendorReviewManagementScreen extends StatelessWidget {
  const VendorReviewManagementScreen({Key? key}) : super(key: key);

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    if (difference.inHours > 0) return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Text(
          'My Product Reviews',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: _buildReviewsList(context),
    );
  }

  Widget _buildReviewsList(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: AppColors.softGold),
            const SizedBox(height: 16),
            Text(
              'Please login to view reviews',
              style: TextStyle(color: AppColors.softGold),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('vendorId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.richGold),
          );
        }

        if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.softGold.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('No products found', style: TextStyle(color: AppColors.softGold, fontSize: 16)),
              ],
            ),
          );
        }

        final vendorProductIds = productSnapshot.data!.docs.map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collectionGroup('reviews').snapshots(),
          builder: (context, reviewSnapshot) {
            if (reviewSnapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.richGold),
              );
            }

            if (!reviewSnapshot.hasData || reviewSnapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: AppColors.softGold.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No reviews yet', style: TextStyle(color: AppColors.softGold, fontSize: 16)),
                  ],
                ),
              );
            }

            final reviews = reviewSnapshot.data!.docs.where((doc) {
              final productId = doc.reference.parent.parent?.id ?? '';
              return vendorProductIds.contains(productId);
            }).toList();

            if (reviews.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox, size: 64, color: AppColors.softGold.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text('No reviews found', style: TextStyle(color: AppColors.softGold, fontSize: 16)),
                  ],
                ),
              );
            }

            reviews.sort((a, b) {
              final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final doc = reviews[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildReviewCard(data);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'Anonymous';
    final rating = (data['rating'] ?? 0).toDouble();
    final reviewText = data['review'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final productName = data['productName'] ?? 'Unknown Product';
    final adminReply = (data['adminReply'] ?? '').toString();
    final userId = data['userId'] ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, userSnapshot) {
        String? photoUrl;
        if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          photoUrl = userData['photoUrl']; // ✅ customer image URL
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.richGold.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name and timestamp
              Text(productName,
                  style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(_formatTimestamp(timestamp),
                  style: TextStyle(color: AppColors.softGold.withOpacity(0.6), fontSize: 12)),
              const SizedBox(height: 12),
              // User avatar and rating
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.richGold,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(userName[0].toUpperCase(),
                            style: TextStyle(
                                color: AppColors.deepBlack, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(userName,
                        style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: List.generate(
                        5,
                        (i) => Icon(i < rating ? Icons.star : Icons.star_border,
                            color: AppColors.richGold, size: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Review text
              Text(reviewText,
                  style: TextStyle(color: AppColors.softGold, fontSize: 14, height: 1.5)),
              // Admin reply
              if (adminReply.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.reply, color: AppColors.successGreen, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Admin replied: ',
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              TextSpan(
                                text: adminReply,
                                style: TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
