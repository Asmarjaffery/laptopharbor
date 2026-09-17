import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';

class ProductReviewsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductReviewsScreen({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductReviewsScreen> createState() => _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends State<ProductReviewsScreen> {
  final TextEditingController _reviewController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  double _selectedRating = 5.0;
  bool _isSubmitting = false;
  bool _hasPurchased = false;
  bool _isCheckingPurchase = true;
  bool _hasAlreadyReviewed = false;
  
  // Set to FALSE for production - only purchased users can review
  final bool _bypassPurchaseCheck = false;

  @override
  void initState() {
    super.initState();
    _checkIfUserPurchased();
    _checkIfAlreadyReviewed();
  }

  Future<void> _checkIfAlreadyReviewed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final existingReview = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      setState(() {
        _hasAlreadyReviewed = existingReview.docs.isNotEmpty;
      });
    } catch (e) {
      print('Error checking existing review: $e');
    }
  }

  Future<void> _checkIfUserPurchased() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _hasPurchased = false;
        _isCheckingPurchase = false;
      });
      return;
    }

    try {
      // Get ALL orders for this user
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .get();

      print('📦 Total orders found: ${ordersSnapshot.docs.length}');

      bool purchased = false;

      for (var order in ordersSnapshot.docs) {
        final orderData = order.data();
        
        // Check multiple possible status field names
        final status = orderData['status'] as String?;
        final orderStatus = orderData['orderStatus'] as String?;
        
        print('Order ${order.id}: status="$status", orderStatus="$orderStatus"');
        
        // Accept multiple completion states
        final isCompleted = 
            status?.toLowerCase() == 'delivered' ||
            status?.toLowerCase() == 'complete' ||
            status?.toLowerCase() == 'completed' ||
            status?.toLowerCase() == 'confirmed' ||
            orderStatus?.toLowerCase() == 'delivered' ||
            orderStatus?.toLowerCase() == 'complete' ||
            orderStatus?.toLowerCase() == 'completed' ||
            orderStatus?.toLowerCase() == 'confirmed';
        
        if (!isCompleted) {
          print('  ⏭️ Skipping - order not completed');
          continue;
        }

        // ✅ CHECK MULTIPLE POSSIBLE FIELD NAMES FOR ITEMS
        List<dynamic> items = [];
        
        // Try different field names
        if (orderData.containsKey('items') && orderData['items'] != null) {
          items = orderData['items'] as List<dynamic>;
          print('  Found items array: ${items.length} items');
        } else if (orderData.containsKey('products') && orderData['products'] != null) {
          items = orderData['products'] as List<dynamic>;
          print('  Found products array: ${items.length} items');
        } else if (orderData.containsKey('orderItems') && orderData['orderItems'] != null) {
          items = orderData['orderItems'] as List<dynamic>;
          print('  Found orderItems array: ${items.length} items');
        }
        
        // ✅ ALSO CHECK IF PRODUCT ID IS DIRECTLY IN ORDER
        if (items.isEmpty) {
          // Check if productId is directly stored in order (single product orders)
          final directProductId = orderData['productId']?.toString() ?? '';
          print('  Checking direct productId: $directProductId vs ${widget.productId}');
          
          if (directProductId == widget.productId) {
            purchased = true;
            print('✅ MATCH FOUND! (Direct product ID)');
            break;
          }
          
          // ✅ PRINT COMPLETE ORDER STRUCTURE FOR DEBUGGING
          print('  🔍 Complete order data keys: ${orderData.keys.toList()}');
          print('  🔍 Complete order data: $orderData');
        }
        
        // Check items array
        for (var item in items) {
          // Handle both Map and direct String product IDs
          String itemProductId = '';
          
          if (item is Map<String, dynamic>) {
            itemProductId = item['productId']?.toString() ?? 
                           item['id']?.toString() ?? 
                           item['product_id']?.toString() ?? '';
          } else if (item is String) {
            itemProductId = item;
          }
          
          print('  Checking item productId: $itemProductId vs ${widget.productId}');
          
          if (itemProductId == widget.productId) {
            purchased = true;
            print('✅ MATCH FOUND! User has purchased this product');
            break;
          }
        }
        
        if (purchased) break;
      }

      print('Final result - hasPurchased: $purchased');
      
      setState(() {
        _hasPurchased = purchased;
        _isCheckingPurchase = false;
      });
    } catch (e) {
      print('❌ Error checking purchase: $e');
      setState(() {
        _hasPurchased = false;
        _isCheckingPurchase = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to submit a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // STRICT CHECK: Must have purchased to review
    if (!_hasPurchased && !_bypassPurchaseCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only purchased products can be reviewed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous User';

      // Get product details
      final productDoc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();
      
      final productData = productDoc.data() as Map<String, dynamic>;
      final vendorId = productData['vendorId'] as String?;
      
      // Get vendor name
      String vendorName = 'Unknown Vendor';
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

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userName': userName,
        'productName': widget.productName,
        'vendorName': vendorName,
        'rating': _selectedRating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'adminReply': '',
        'verified': true,
      });

      _reviewController.clear();
      _selectedRating = 5.0;
      
      setState(() {
        _hasAlreadyReviewed = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Review submitted successfully! Waiting for admin approval.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews',
              style: TextStyle(color: AppColors.richGold, fontSize: 20),
            ),
            Text(
              widget.productName,
              style: TextStyle(color: AppColors.softGold, fontSize: 12),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: AppColors.richGold),
      ),
      body: Theme(
        data: ThemeData(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor: MaterialStateProperty.all(Colors.grey),
            thickness: MaterialStateProperty.all(8),
            radius: Radius.circular(4),
            thumbVisibility: MaterialStateProperty.all(true),
          ),
        ),
        child: Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.reviews, color: AppColors.richGold, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Customer Reviews',
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Reviews List
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.productId)
                        .collection('reviews')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.richGold,
                          ),
                        );
                      }

                      final allReviews = snapshot.data!.docs;
                      final reviews = allReviews.where((review) {
                        final data = review.data() as Map<String, dynamic>;
                        return (data['status'] ?? '') == 'approved';
                      }).toList();

                      if (reviews.isEmpty) {
                        return Container(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 60,
                                color: AppColors.richGold.withOpacity(0.3),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No reviews yet',
                                style: TextStyle(
                                  color: AppColors.softGold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Be the first to review!',
                                style: TextStyle(
                                  color: AppColors.softGold.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Calculate average rating
                      double totalRating = 0;
                      for (var review in reviews) {
                        final data = review.data() as Map<String, dynamic>;
                        totalRating += (data['rating'] ?? 0).toDouble();
                      }
                      final avgRating = totalRating / reviews.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Average Rating Display
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.deepBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: AppColors.richGold, size: 40),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      avgRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: AppColors.richGold,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Based on ${reviews.length} reviews',
                                      style: TextStyle(
                                        color: AppColors.softGold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),

                          // Individual Reviews
                          ...reviews.map((review) {
                            final data = review.data() as Map<String, dynamic>;
                            final rating = (data['rating'] ?? 0).toDouble();
                            final reviewText = data['review'] ?? '';
                            final userName = data['userName'] ?? 'Anonymous';
                            final adminReply = (data['adminReply'] ?? '').toString();
                            final timestamp = data['timestamp'] as Timestamp?;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.deepBlack,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.richGold.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: AppColors.richGold.withOpacity(0.2),
                                            child: Text(
                                              userName[0].toUpperCase(),
                                              style: TextStyle(color: AppColors.richGold),
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            userName,
                                            style: TextStyle(
                                              color: AppColors.lightGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: AppColors.richGold, size: 18),
                                          SizedBox(width: 4),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: TextStyle(
                                              color: AppColors.richGold,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    reviewText,
                                    style: TextStyle(
                                      color: AppColors.softGold,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),

                                  if (adminReply.isNotEmpty) ...[
                                    SizedBox(height: 10),
                                    Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.blue.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.reply, color: Colors.blue, size: 18),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Store Reply',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  adminReply,
                                                  style: TextStyle(
                                                    color: Colors.blue[300],
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (timestamp != null) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      _formatTimestamp(timestamp),
                                      style: TextStyle(
                                        color: AppColors.softGold.withOpacity(0.5),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: 30),
                  Divider(color: AppColors.richGold.withOpacity(0.3), thickness: 1),
                  SizedBox(height: 20),

                  // Write Review Section - ONLY FOR PURCHASED USERS
                  if (_isCheckingPurchase)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: AppColors.richGold),
                      ),
                    )
                  else if (!_hasPurchased && !_bypassPurchaseCheck)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.orange, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Purchase Required',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Only customers who have purchased this product can write a review',
                                  style: TextStyle(
                                    color: Colors.orange[300],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_hasAlreadyReviewed)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.blue, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Already Submitted',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your review is pending admin approval',
                                  style: TextStyle(
                                    color: Colors.blue[300],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Icon(Icons.edit, color: AppColors.richGold, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Write Your Review',
                          style: TextStyle(
                            color: AppColors.lightGold,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Rating Selector
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Your Rating:',
                            style: TextStyle(
                              color: AppColors.softGold,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(width: 12),
                          ...List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRating = (index + 1).toDouble();
                                });
                              },
                              child: Icon(
                                index < _selectedRating ? Icons.star : Icons.star_border,
                                color: AppColors.richGold,
                                size: 32,
                              ),
                            );
                          }),
                          SizedBox(width: 8),
                          Text(
                            _selectedRating.toStringAsFixed(0),
                            style: TextStyle(
                              color: AppColors.richGold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Review Text Field
                    TextField(
                      controller: _reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your experience with this product...',
                        hintStyle: TextStyle(
                          color: AppColors.softGold.withOpacity(0.5),
                        ),
                        filled: true,
                        fillColor: AppColors.deepBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.richGold.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.richGold.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.richGold,
                            width: 2,
                          ),
                        ),
                      ),
                      style: TextStyle(color: AppColors.softGold, fontSize: 14),
                    ),
                    SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: AppColors.deepBlack,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Submit Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  @override
  void dispose() {
    _reviewController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
