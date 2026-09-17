import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/colors.dart';
import '../../constants/styles.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../common/navbar.dart'; // Import navbar
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;
  final double productPrice;
  final String imageBase64;
  final int availableStock;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.imageBase64,
    required this.availableStock,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with SingleTickerProviderStateMixin {
  int quantity = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasUserPurchased = false;
  bool _isCheckingPurchase = true;
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkUserPurchaseHistory();
    _loadProductRating();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  Future<void> _checkUserPurchaseHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isCheckingPurchase = false;
        _hasUserPurchased = false;
      });
      return;
    }

    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: user.uid)
          .where('orderStatus', isEqualTo: 'Complete')
          .get();

      bool hasPurchased = false;
      
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data();
        
        final items = orderData['items'] as List<dynamic>?;
        if (items != null) {
          for (var item in items) {
            if (item['productId'] == widget.productId) {
              hasPurchased = true;
              break;
            }
          }
        }
        
        if (orderData['productId'] == widget.productId) {
          hasPurchased = true;
        }
        
        if (hasPurchased) break;
      }

      if (mounted) {
        setState(() {
          _hasUserPurchased = hasPurchased;
          _isCheckingPurchase = false;
        });
      }
    } catch (e) {
      print('Error checking purchase history: $e');
      if (mounted) {
        setState(() {
          _isCheckingPurchase = false;
        });
      }
    }
  }

  Future<void> _loadProductRating() async {
    try {
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        setState(() {
          _averageRating = 0.0;
          _totalReviews = 0;
        });
        return;
      }

      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalReviews = reviewsSnapshot.docs.length;
          _averageRating = totalRating / _totalReviews;
        });
      }
    } catch (e) {
      print('Error loading rating: $e');
    }
  }

  void _showReviewDialog() {
    if (!_hasUserPurchased) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock, color: AppColors.deepBlack),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You need to purchase this product before reviewing it',
                  style: AppStyles.bodyStyle.copyWith(color: AppColors.deepBlack),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final TextEditingController reviewController = TextEditingController();
    double rating = 5.0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Write a Review', style: AppStyles.headingStyle.copyWith(fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rate this product:', style: AppStyles.bodyStyle),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setDialogState(() {
                          rating = (index + 1).toDouble();
                        });
                      },
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: AppColors.richGold,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Text('Your Review:', style: AppStyles.bodyStyle),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  style: AppStyles.bodyStyle,
                  decoration: InputDecoration(
                    hintText: 'Share your experience...',
                    hintStyle: AppStyles.smallTextStyle,
                    filled: true,
                    fillColor: AppColors.deepBlack,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.richGold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppStyles.outlinedButtonTextStyle),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reviewController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please write a review', style: AppStyles.bodyStyle.copyWith(color: Colors.white)),
                    ),
                  );
                  return;
                }
                await _submitReview(reviewController.text, rating);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
              ),
              child: Text('Submit', style: AppStyles.buttonTextStyle),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(String reviewText, double rating) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? user.displayName ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .add({
        'userId': user.uid,
        'userName': userName,
        'rating': rating,
        'review': reviewText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _loadProductRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.deepBlack),
                const SizedBox(width: 12),
                Text('Review submitted successfully!', style: AppStyles.bodyStyle.copyWith(color: AppColors.deepBlack)),
              ],
            ),
            backgroundColor: AppColors.richGold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review', style: AppStyles.bodyStyle.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Uint8List _decodeBase64(String base64String) => base64Decode(base64String);

  void _incrementQuantity() {
    if (quantity < widget.availableStock) setState(() => quantity++);
  }

  void _decrementQuantity() {
    if (quantity > 1) setState(() => quantity--);
  }

  void _addToCart() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    for (int i = 0; i < quantity; i++) {
      cartProvider.addToCart(
        Product(
          id: widget.productId,
          name: widget.productName,
          price: widget.productPrice,
          imageUrl: '',
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$quantity x ${widget.productName} added to cart', style: AppStyles.bodyStyle.copyWith(color: AppColors.deepBlack)),
        backgroundColor: AppColors.richGold,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context);
  }

  void _buyNow() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    for (int i = 0; i < quantity; i++) {
      cartProvider.addToCart(
        Product(
          id: widget.productId,
          name: widget.productName,
          price: widget.productPrice,
          imageUrl: '',
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          totalAmount: widget.productPrice * quantity,
          itemCount: quantity,
          productId: widget.productId,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
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
    final imageBytes = _decodeBase64(widget.imageBase64);
    final totalPrice = widget.productPrice * quantity;

    // Wrap with RoleBasedNav for customer
    return RoleBasedNav(
      role: UserRole.customer,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.lightGold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Product Details', style: AppStyles.headingStyle),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'product_${widget.productId}',
                          child: Container(
                            width: double.infinity,
                            height: 280,
                            decoration: BoxDecoration(
                              color: AppColors.cardBlack,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Image.memory(imageBytes, fit: BoxFit.contain),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.productName, style: AppStyles.headingStyle.copyWith(fontSize: 22)),
                              const SizedBox(height: 12),
                              _buildRatingSection(),
                              const SizedBox(height: 16),
                              // Price & Stock
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [AppColors.richGold.withOpacity(0.1), AppColors.richGold.withOpacity(0.05)]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Price', style: AppStyles.smallTextStyle),
                                        const SizedBox(height: 4),
                                        Text('\$${widget.productPrice.toStringAsFixed(2)}', style: AppStyles.cardValueStyle.copyWith(fontSize: 24)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: widget.availableStock > 10 ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: widget.availableStock > 10 ? Colors.green : Colors.orange),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.inventory_2, size: 16, color: widget.availableStock > 10 ? Colors.green : Colors.orange),
                                          const SizedBox(width: 6),
                                          Text('${widget.availableStock} in stock',
                                              style: AppStyles.smallTextStyle.copyWith(color: widget.availableStock > 10 ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Quantity Selector
                              Text('Select Quantity', style: AppStyles.subHeadingStyle),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBlack,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Quantity', style: AppStyles.bodyStyle),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.deepBlack,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.richGold.withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: _decrementQuantity,
                                            icon: Icon(Icons.remove_circle_outline, color: quantity > 1 ? AppColors.richGold : AppColors.softGold.withOpacity(0.3)),
                                            iconSize: 24,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text(quantity.toString(), style: AppStyles.cardValueStyle.copyWith(fontSize: 18)),
                                          ),
                                          IconButton(
                                            onPressed: _incrementQuantity,
                                            icon: Icon(Icons.add_circle_outline, color: quantity < widget.availableStock ? AppColors.richGold : AppColors.softGold.withOpacity(0.3)),
                                            iconSize: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Total Price
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [AppColors.richGold.withOpacity(0.2), AppColors.richGold.withOpacity(0.1)]),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.richGold, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Price:', style: AppStyles.subHeadingStyle),
                                    Text('\$${totalPrice.toStringAsFixed(2)}', style: AppStyles.cardValueStyle.copyWith(fontSize: 26)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildReviewsSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, -5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _addToCart,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.shopping_cart, color: AppColors.deepBlack, size: 22),
                            const SizedBox(width: 8),
                            Text('Add to Cart', style: AppStyles.buttonTextStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _buyNow,
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.richGold, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: Text('Buy Now', style: AppStyles.outlinedButtonTextStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.richGold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(index < _averageRating ? Icons.star : Icons.star_border, color: AppColors.richGold, size: 22);
            }),
          ),
          const SizedBox(width: 12),
          Text('($_totalReviews reviews)', style: AppStyles.smallTextStyle.copyWith(color: AppColors.softGold)),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Customer Reviews', style: AppStyles.subHeadingStyle.copyWith(fontSize: 18)),
            _isCheckingPurchase
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.richGold,
                      strokeWidth: 2,
                    ),
                  )
                : TextButton.icon(
                    onPressed: _showReviewDialog,
                    icon: Icon(
                      _hasUserPurchased ? Icons.rate_review : Icons.lock,
                      color: _hasUserPurchased ? AppColors.richGold : AppColors.softGold.withOpacity(0.5),
                      size: 14,
                    ),
                    label: Text(
                      'Write Review',
                      style: AppStyles.outlinedButtonTextStyle.copyWith(
                        color: _hasUserPurchased ? AppColors.richGold : AppColors.softGold.withOpacity(0.5),
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .doc(widget.productId)
              .collection('reviews')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.richGold.withOpacity(0.2)),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: AppColors.softGold.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _hasUserPurchased 
                            ? 'No reviews yet. Be the first to review!' 
                            : 'No reviews yet',
                        style: AppStyles.bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildReviewCard(data);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.richGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(data['userName'] ?? 'Anonymous', style: AppStyles.cardTitleStyle.copyWith(fontSize: 16)),
              Row(
                children: List.generate(5, (index) {
                  return Icon(index < (data['rating'] ?? 0) ? Icons.star : Icons.star_border, color: AppColors.richGold, size: 18);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(data['review'] ?? '', style: AppStyles.bodyStyle),
          const SizedBox(height: 6),
          Text(
            _formatTimestamp(data['timestamp']),
            style: AppStyles.smallTextStyle.copyWith(color: AppColors.softGold),
          ),
        ],
      ),
    );
  }
}