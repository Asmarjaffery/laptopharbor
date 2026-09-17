import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/customer/add_review_screen.dart';
import '../constants/colors.dart';
import '../common/navbar.dart';

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

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final String fontFamily = 'Poppins';
  int _quantity = 1;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
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

  void _incrementQuantity() {
    if (_quantity < widget.availableStock) setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  Future<void> _addToCart(BuildContext context) async {
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

    try {
      final cartDoc = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(widget.productId);

      final snapshot = await cartDoc.get();
      if (snapshot.exists) {
        final currentQty = snapshot.data()?['quantity'] ?? 0;
        await cartDoc.update({'quantity': currentQty + _quantity});
      } else {
        await cartDoc.set({
          'productId': widget.productId,
          'productName': widget.productName,
          'price': widget.productPrice,
          'quantity': _quantity,
          'imageBase64': widget.imageBase64,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('$_quantity item(s) added to cart!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _quantity = 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _buyNow(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final totalAmount = widget.productPrice * _quantity;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          totalAmount: totalAmount,
          itemCount: _quantity,
          productId: widget.productId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.productPrice * _quantity;

    return RoleBasedNav(
      role: UserRole.customer,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.lightGold),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Product Details',
            style: TextStyle(
              fontFamily: fontFamily,
              color: AppColors.lightGold,
            ),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBlack,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(widget.imageBase64),
                            height: 280,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Product Name
                    Text(
                      widget.productName,
                      style: TextStyle(
                        fontFamily: fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightGold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Price and Star Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${widget.productPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.richGold,
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
                                  productName: widget.productName,
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
                                      fontFamily: fontFamily,
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

                    // Quantity Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: AppColors.softGold,
                              fontSize: 16,
                            ),
                          ),
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
                                  icon: Icon(
                                    Icons.remove_circle_outline,
                                    color: _quantity > 1 
                                        ? AppColors.richGold 
                                        : AppColors.softGold.withOpacity(0.3),
                                  ),
                                  iconSize: 24,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    _quantity.toString(),
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      color: AppColors.richGold,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _incrementQuantity,
                                  icon: Icon(
                                    Icons.add_circle_outline,
                                    color: _quantity < widget.availableStock 
                                        ? AppColors.richGold 
                                        : AppColors.softGold.withOpacity(0.3),
                                  ),
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
                        gradient: LinearGradient(
                          colors: [
                            AppColors.richGold.withOpacity(0.2),
                            AppColors.richGold.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.richGold, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Price:',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: AppColors.lightGold,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '\$${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: AppColors.richGold,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom buttons
                  ],
                ),
              ),
            ),

            // Scroll to top button
            if (_showScrollToTop)
              Positioned(
                right: 16,
                bottom: 90,
                child: FloatingActionButton.small(
                  onPressed: _scrollToTop,
                  backgroundColor: AppColors.richGold,
                  child: Icon(
                    Icons.arrow_upward,
                    color: AppColors.deepBlack,
                  ),
                ),
              ),

            // Bottom Buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, -5)
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _addToCart(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            ),
                            elevation: 3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.shopping_cart,
                                color: AppColors.deepBlack,
                                size: 22
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add to Cart',
                                style: TextStyle(
                                  fontFamily: fontFamily,
                                  color: AppColors.deepBlack,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
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
                          onPressed: () => _buyNow(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.richGold,
                              width: 2
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            ),
                          ),
                          child: Text(
                            'Buy Now',
                            style: TextStyle(
                              fontFamily: fontFamily,
                              color: AppColors.richGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}