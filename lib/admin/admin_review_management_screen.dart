import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';

class AdminReviewManagementScreen extends StatefulWidget {
  const AdminReviewManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminReviewManagementScreen> createState() =>
      _AdminReviewManagementScreenState();
}

class _AdminReviewManagementScreenState
    extends State<AdminReviewManagementScreen> {

  // ================== OPTIONS MENU ==================
  void _showOptionsMenu(
    BuildContext context,
    String productId,
    String reviewId,
    String status,
    double rating,
    Offset tapPosition,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    List<PopupMenuEntry<dynamic>> items = [];

    if (status == 'pending') {
      items.addAll([
        PopupMenuItem(
          child: _menuRow(Icons.check_circle, 'Approve', Colors.green),
          onTap: () => Future.microtask(() =>
              _approveReview(productId, reviewId, rating)),
        ),
        PopupMenuItem(
          child: _menuRow(Icons.edit, 'Approve with Custom Reply', Colors.blue),
          onTap: () => Future.microtask(() =>
              _showCustomReplyDialog(productId, reviewId, rating)),
        ),
        PopupMenuItem(
          child: _menuRow(Icons.cancel, 'Reject', Colors.red),
          onTap: () => Future.microtask(
              () => _showRejectDialog(productId, reviewId)),
        ),
      ]);
    }

    if (status == 'approved') {
      items.addAll([
        PopupMenuItem(
          child: _menuRow(Icons.edit, 'Edit Reply', Colors.blue),
          onTap: () => Future.microtask(() =>
              _showEditReplyDialog(productId, reviewId)),
        ),
        PopupMenuItem(
          child: _menuRow(Icons.delete, 'Delete', Colors.red),
          onTap: () => Future.microtask(
              () => _deleteReview(productId, reviewId)),
        ),
      ]);
    }

    if (status == 'rejected') {
      items.add(
        PopupMenuItem(
          child: _menuRow(Icons.delete, 'Delete', Colors.red),
          onTap: () => Future.microtask(
              () => _deleteReview(productId, reviewId)),
        ),
      );
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        tapPosition.dx,
        tapPosition.dy,
        overlay.size.width - tapPosition.dx,
        overlay.size.height - tapPosition.dy,
      ),
      items: items,
      color: AppColors.cardBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
      ),
    );
  }

  Widget _menuRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color)),
      ],
    );
  }

  // ================== FIRESTORE ACTIONS ==================
  Future<void> _approveReview(String productId, String reviewId, double rating) async {
    String autoReply = _generateAutoReply(rating);

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .update({
      'status': 'approved',
      'adminReply': autoReply,
      'approvedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Review approved with auto-reply!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _generateAutoReply(double rating) {
    if (rating >= 4.5) {
      return "Thank you so much for your wonderful feedback! We're thrilled you had a great experience with us. 🌟";
    } else if (rating >= 3.5) {
      return "Thank you for your feedback! We're glad you chose us and hope to serve you again soon. 😊";
    } else if (rating >= 2.5) {
      return "Thank you for sharing your experience. We appreciate your feedback and are working to improve our service.";
    } else {
      return "We sincerely apologize for your experience. Your feedback is valuable and we're committed to doing better. Please contact our support team so we can make this right.";
    }
  }

  void _showCustomReplyDialog(String productId, String reviewId, double rating) {
    final controller = TextEditingController(text: _generateAutoReply(rating));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Approve with Custom Reply',
            style: TextStyle(color: AppColors.richGold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit your reply to the customer:',
              style: TextStyle(color: AppColors.softGold, fontSize: 13),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: AppColors.lightGold),
              decoration: InputDecoration(
                hintText: 'Write your professional reply...',
                hintStyle: TextStyle(color: AppColors.softGold.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.deepBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reply cannot be empty'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .collection('reviews')
                  .doc(reviewId)
                  .update({
                'status': 'approved',
                'adminReply': controller.text.trim(),
                'approvedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Review approved with custom reply!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text('Approve & Send'),
          ),
        ],
      ),
    );
  }

  void _showEditReplyDialog(String productId, String reviewId) async {
    final doc = await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .get();
    
    final currentReply = (doc.data()?['adminReply'] ?? '').toString();
    final controller = TextEditingController(text: currentReply);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Edit Reply',
            style: TextStyle(color: AppColors.richGold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update your reply:',
              style: TextStyle(color: AppColors.softGold, fontSize: 13),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: TextStyle(color: AppColors.lightGold),
              decoration: InputDecoration(
                hintText: 'Write your updated reply...',
                hintStyle: TextStyle(color: AppColors.softGold.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.deepBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reply cannot be empty'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .collection('reviews')
                  .doc(reviewId)
                  .update({
                'adminReply': controller.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✏️ Reply updated successfully!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            child: Text('Update Reply'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(String productId, String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Delete Review?', style: TextStyle(color: AppColors.richGold)),
        content: Text(
          'Are you sure you want to permanently delete this review?',
          style: TextStyle(color: AppColors.lightGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .doc(reviewId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ Review deleted permanently'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(String productId, String reviewId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Reject Review',
            style: TextStyle(color: AppColors.richGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: AppColors.softGold, fontSize: 13),
            ),
            SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              style: TextStyle(color: AppColors.lightGold),
              decoration: InputDecoration(
                hintText: 'e.g., Contains inappropriate language',
                hintStyle: TextStyle(color: AppColors.softGold.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.deepBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              String replyMessage =
                  "We apologize, but your review couldn't be approved. ${controller.text.trim()}";

              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId)
                  .collection('reviews')
                  .doc(reviewId)
                  .update({
                'status': 'rejected',
                'rejectionReason': controller.text.trim(),
                'adminReply': replyMessage,
                'rejectedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Review rejected with explanation'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reject'),
          )
        ],
      ),
    );
  }

  Future<Map<String, String>> getProductAndVendorInfo(
    String productId,
    String? currentProductName,
    String? currentVendorName,
  ) async {
    String productName = currentProductName ?? '';
    String vendorName = currentVendorName ?? '';

    if (productName.isNotEmpty && vendorName.isNotEmpty) {
      return {'productName': productName, 'vendorName': vendorName};
    }

    try {
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .get();
      
      if (!productDoc.exists) {
        return {
          'productName': productName.isEmpty ? 'Unknown Product' : productName,
          'vendorName': vendorName.isEmpty ? 'Unknown Vendor' : vendorName,
        };
      }

      final productData = productDoc.data() as Map<String, dynamic>;
      
      if (productName.isEmpty) {
        productName = productData['name'] ?? 'Unknown Product';
      }

      if (vendorName.isEmpty) {
        final vendorId = productData['vendorId'] as String?;
        if (vendorId != null && vendorId.isNotEmpty) {
          final vendorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(vendorId)
              .get();
          if (vendorDoc.exists) {
            final vendorData = vendorDoc.data() as Map<String, dynamic>;
            vendorName = vendorData['shopName'] ?? vendorData['name'] ?? 'Unknown Vendor';
          }
        }
      }

      return {
        'productName': productName.isEmpty ? 'Unknown Product' : productName,
        'vendorName': vendorName.isEmpty ? 'Unknown Vendor' : vendorName,
      };
    } catch (e) {
      print('Error fetching product/vendor info: $e');
      return {
        'productName': productName.isEmpty ? 'Unknown Product' : productName,
        'vendorName': vendorName.isEmpty ? 'Unknown Vendor' : vendorName,
      };
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
          'Review Management',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.richGold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('reviews').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'Error loading reviews',
                      style: TextStyle(color: Colors.red, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: AppColors.softGold, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 80,
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No reviews found',
                    style: TextStyle(
                      color: AppColors.softGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Reviews will appear here once customers submit them',
                    style: TextStyle(
                      color: AppColors.softGold.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;
          
          docs.sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final productId = doc.reference.parent.parent!.id;

              return FutureBuilder<Map<String, String>>(
                future: getProductAndVendorInfo(
                  productId,
                  data['productName'],
                  data['vendorName'],
                ),
                builder: (context, infoSnapshot) {
                  final productName = infoSnapshot.data?['productName'] ?? 'Loading...';
                  final vendorName = infoSnapshot.data?['vendorName'] ?? 'Loading...';
                  
                  return _reviewCard(
                    productId: productId,
                    reviewId: doc.id,
                    userName: data['userName'] ?? 'Anonymous',
                    vendorName: vendorName,
                    productName: productName,
                    rating: (data['rating'] ?? 0).toDouble(),
                    reviewText: data['review'] ?? '',
                    status: data['status'] ?? 'pending',
                    rejectionReason: data['rejectionReason'],
                    verified: data['verified'] ?? false,
                    adminReply: data['adminReply'],
                    timestamp: data['timestamp'],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _reviewCard({
    required String productId,
    required String reviewId,
    required String userName,
    required String vendorName,
    required String productName,
    required double rating,
    required String reviewText,
    required String status,
    required bool verified,
    dynamic rejectionReason,
    String? adminReply,
    Timestamp? timestamp,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusBorderColor(status),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.richGold.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.richGold.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              userName,
                              style: TextStyle(
                                color: AppColors.lightGold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (verified) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.verified, color: Colors.green, size: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Verified Purchase',
                        style: TextStyle(color: Colors.green, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
                const SizedBox(width: 8),
                GestureDetector(
                  onTapDown: (d) => _showOptionsMenu(
                    context,
                    productId,
                    reviewId,
                    status,
                    rating,
                    d.globalPosition,
                  ),
                  child: Icon(Icons.more_vert, color: AppColors.richGold),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (timestamp != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: AppColors.softGold, size: 14),
                        SizedBox(width: 6),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            color: AppColors.softGold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.softGold.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag, color: AppColors.richGold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              productName,
                              style: TextStyle(
                                color: AppColors.lightGold,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.store, color: AppColors.softGold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vendorName,
                              style: TextStyle(color: AppColors.softGold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: AppColors.richGold,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${rating.toStringAsFixed(1)}/5.0',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.richGold.withOpacity(0.2)),
                  ),
                  child: Text(
                    reviewText.isNotEmpty ? reviewText : 'No review text provided',
                    style: TextStyle(
                      color: AppColors.lightGold,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),

                if (adminReply != null && adminReply.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.reply, color: Colors.green, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Reply (Visible to Customer)',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  adminReply,
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (rejectionReason != null && rejectionReason.toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rejection Reason',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  rejectionReason.toString(),
                                  style: TextStyle(color: Colors.red[300], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Product: $productId | Review: $reviewId',
                    style: TextStyle(
                      color: AppColors.softGold.withOpacity(0.3),
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color statusColor = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return AppColors.softGold;
    }
  }

  Color _getStatusBorderColor(String status) {
    return _getStatusColor(status).withOpacity(0.3);
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
    return 'Just now';
  }
}