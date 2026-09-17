import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/customer/add_review_screen.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../common/navbar.dart';


class ProductDetailViewScreen extends StatefulWidget {
  final String productId;
  final String? productName;
  final double? productPrice;
  final String? imageBase64;

  const ProductDetailViewScreen({
    super.key,
    required this.productId,
    this.productName,
    this.productPrice,
    this.imageBase64,
  });

  @override
  State<ProductDetailViewScreen> createState() => _ProductDetailViewScreenState();
}

class _ProductDetailViewScreenState extends State<ProductDetailViewScreen> {
  Map<String, dynamic>? productData;
  bool isLoading = true;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.offset >= 200 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset < 200 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (!docSnapshot.exists) {
        throw Exception('Product not found');
      }

      if (mounted) {
        setState(() {
          productData = docSnapshot.data();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll('Exception: ', '');
          isLoading = false;
        });
      }
    }
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (productData == null) return;

    try {
      final String name = productData!['name'] ?? 'Unknown Product';
      final double price = (productData!['price'] ?? 0).toDouble();
      final String imageBase64 = productData!['imageBase64'] ?? '';

      await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(widget.productId)
          .set({
        'productId': widget.productId,
        'productName': name,
        'price': price,
        'quantity': 1,
        'imageBase64': imageBase64,
        'addedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$name added to cart'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleBasedNav(
      role: UserRole.customer,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          iconTheme: const IconThemeData(color: AppColors.lightGold),
          title: Text(
            widget.productName ?? 'Product Details',
            style: AppStyles.headingStyle,
          ),
          elevation: 0,
        ),
        body: Stack(
          children: [
            isLoading
                ? _buildLoadingState()
                : errorMessage != null
                    ? _buildErrorState()
                    : _buildProductDetails(),
            
            // Scroll to top button
            if (_showScrollToTop)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  backgroundColor: AppColors.richGold,
                  child: Icon(
                    Icons.arrow_upward,
                    color: AppColors.deepBlack,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.richGold, strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'Loading product details...',
              style: AppStyles.bodyStyle.copyWith(fontSize: 16),
            ),
          ],
        ),
      );

  Widget _buildErrorState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 60),
              ),
              const SizedBox(height: 24),
              Text(
                'Failed to Load Product',
                style: AppStyles.headingStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? '',
                textAlign: TextAlign.center,
                style: AppStyles.bodyStyle,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProductDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  foregroundColor: AppColors.deepBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: AppStyles.buttonTextStyle,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Go Back',
                  style: AppStyles.bodyStyle.copyWith(
                    color: AppColors.lightGold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildProductDetails() {
    if (productData == null) return const SizedBox();

    final String name = productData!['name'] ?? 'Unknown Product';
    final double price = (productData!['price'] ?? 0).toDouble();
    final String imageBase64 = productData!['imageBase64'] ?? '';
    final int stock = productData!['quantity'] ?? 0;
    final String description = productData!['description'] ??
        'This is a high-quality laptop with premium features and excellent performance.';

    final Map<String, dynamic>? specs = productData!['specifications'] as Map<String, dynamic>?;

    return RefreshIndicator(
      onRefresh: _loadProductDetails,
      color: AppColors.richGold,
      backgroundColor: AppColors.cardBlack,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(imageBase64),
              const SizedBox(height: 24),
              Text(
                name,
                style: AppStyles.headingStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "\$${price.toStringAsFixed(2)}",
                    style: AppStyles.cardValueStyle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Star Rating Display
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductReviewsScreen(
                            productId: widget.productId,
                            productName: name,
                          ),
                        ),
                      );
                    },
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('products')
                          .doc(widget.productId)
                          .collection('reviews')
                          .where('status', isEqualTo: 'approved')
                          .snapshots(),
                      builder: (context, snapshot) {
                        double avgRating = 0;
                        int reviewCount = 0;
                        
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final reviews = snapshot.data!.docs;
                          reviewCount = reviews.length;
                          double totalRating = 0;
                          for (var review in reviews) {
                            final data = review.data() as Map<String, dynamic>;
                            totalRating += (data['rating'] ?? 0).toDouble();
                          }
                          avgRating = totalRating / reviews.length;
                        }

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: AppColors.richGold,
                              size: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reviewCount > 0 
                                  ? '${avgRating.toStringAsFixed(1)} (${reviewCount})'
                                  : 'No reviews',
                              style: TextStyle(
                                color: AppColors.richGold,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildDescription(description),
              const SizedBox(height: 20),
              if (specs != null && specs.isNotEmpty) _buildSpecifications(specs),
              const SizedBox(height: 32),
              _buildActionButtons(stock, name),
              const SizedBox(height: 80), // Extra space for scroll to top button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageBase64) => Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(16),
          ),
          child: imageBase64.isNotEmpty
              ? Image.memory(
                  base64Decode(imageBase64),
                  height: 260,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                )
              : _buildImagePlaceholder(),
        ),
      );

  Widget _buildImagePlaceholder() => Container(
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80, color: AppColors.softGold),
        ),
      );

  Widget _buildDescription(String description) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Product Description",
            style: AppStyles.subHeadingStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              description,
              style: AppStyles.bodyStyle.copyWith(height: 1.5),
            ),
          ),
        ],
      );

  Widget _buildSpecifications(Map<String, dynamic> specs) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Specifications",
            style: AppStyles.subHeadingStyle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: specs.entries
                  .map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                "${entry.key}:",
                                style: AppStyles.cardTitleStyle.copyWith(
                                  color: AppColors.richGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: AppStyles.bodyStyle,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      );

  Widget _buildActionButtons(int stock, String name) {
    final inStock = stock > 0;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: inStock ? _addToCart : null,
        icon: const Icon(Icons.shopping_cart),
        label: Text(
          inStock ? 'Add to Cart' : 'Out of Stock',
          style: AppStyles.buttonTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: inStock ? AppColors.richGold : Colors.grey,
          foregroundColor: AppColors.deepBlack,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: inStock ? 4 : 0,
        ),
      ),
    );
  }
}