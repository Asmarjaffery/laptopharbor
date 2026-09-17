import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/customer/add_review_screen.dart';

import 'package:mobileapp/customer/compare_products_screen.dart';
import 'package:mobileapp/constants/styles.dart';
import 'package:mobileapp/routes/app_routes.dart';
import '../../constants/colors.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';
import 'product_detail_view_screen.dart';
import '../customer/search_result_screen.dart';



class HorizontalWheelScroll extends StatelessWidget {
  final Widget child;
  final ScrollController controller;

  const HorizontalWheelScroll({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final newOffset = controller.offset + event.scrollDelta.dy;
          if (controller.hasClients) {
            controller.jumpTo(
              newOffset.clamp(
                controller.position.minScrollExtent,
                controller.position.maxScrollExtent,
              ),
            );
          }
        }
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
          },
        ),
        child: child,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Screen State
  final ScrollController _brandController = ScrollController();
  final Map<String, ScrollController> _categoryControllers = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';
  String _sortBy = 'name';
  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _showFilters = false;

  // Compare functionality
  Set<String> selectedProductIds = {};
  Map<String, Map<String, dynamic>> selectedProducts = {};

  // Review data
  Map<String, Map<String, dynamic>> productReviews = {};

  List<String> categories = ['All'];
  List<String> brands = ['All'];

  @override
  void initState() {
    super.initState();
    _loadFilters();
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      Map<String, Map<String, dynamic>> reviewData = {};

      for (var productDoc in productsSnapshot.docs) {
        final productId = productDoc.id;

        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .collection('reviews')
            .where('status', isEqualTo: 'approved')
            .get();

        if (reviewsSnapshot.docs.isNotEmpty) {
          double totalRating = 0;
          for (var reviewDoc in reviewsSnapshot.docs) {
            totalRating += (reviewDoc.data()['rating'] ?? 0).toDouble();
          }

          final average = totalRating / reviewsSnapshot.docs.length;
          reviewData[productId] = {
            'average': average,
            'count': reviewsSnapshot.docs.length,
          };
        }
      }

      if (mounted) {
        setState(() {
          productReviews = reviewData;
        });
      }
    } catch (e) {
      print('Error loading reviews: $e');
    }
  }

  Future<void> _loadFilters() async {
    try {
      final catSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();

      final brandSnapshot = await FirebaseFirestore.instance
          .collection('brands')
          .get();

      if (mounted) {
        setState(() {
          categories = [
            'All',
            ...catSnapshot.docs.map((doc) => doc['name'] as String),
          ];
          brands = [
            'All',
            ...brandSnapshot.docs.map((doc) => doc['name'] as String),
          ];
        });
      }
    } catch (e) {
      print('Error loading filters: $e');
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedBrand = 'All';
      _sortBy = 'name';
      _minPrice = 0;
      _maxPrice = 10000;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _toggleCompare(DocumentSnapshot doc) {
    setState(() {
      final productId = doc.id;
      final data = doc.data() as Map<String, dynamic>;

      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
        selectedProducts.remove(productId);
      } else {
        if (selectedProductIds.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can compare maximum 4 products'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        selectedProductIds.add(productId);
        selectedProducts[productId] = data;
      }
    });
  }

  void _openCompareScreen() {
    if (selectedProductIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least 2 products to compare'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompareProductsScreen(products: selectedProducts),
      ),
    ).then((_) {
      setState(() {
        selectedProductIds.clear();
        selectedProducts.clear();
      });
    });
  }

  List<DocumentSnapshot> _applyFiltersAndSort(List<DocumentSnapshot> docs) {
    if (_searchQuery.isNotEmpty) {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final brand = (data['brandName'] ?? '').toString().toLowerCase();
        final category = (data['categoryName'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || brand.contains(query) || category.contains(query);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        return data['categoryName'] == _selectedCategory;
      }).toList();
    }

    if (_selectedBrand != 'All') {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        return data['brandName'] == _selectedBrand;
      }).toList();
    }

    docs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;
      final price = double.tryParse(data['price'].toString()) ?? 0;
      return price >= _minPrice && price <= _maxPrice;
    }).toList();

    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>?;
      final dataB = b.data() as Map<String, dynamic>?;
      if (dataA == null || dataB == null) return 0;

      if (_sortBy == 'name') {
        return (dataA['name'] ?? '').toString().compareTo(
          (dataB['name'] ?? '').toString(),
        );
      } else if (_sortBy == 'price_low') {
        final priceA = double.tryParse(dataA['price'].toString()) ?? 0;
        final priceB = double.tryParse(dataB['price'].toString()) ?? 0;
        return priceA.compareTo(priceB);
      } else if (_sortBy == 'price_high') {
        final priceA = double.tryParse(dataA['price'].toString()) ?? 0;
        final priceB = double.tryParse(dataB['price'].toString()) ?? 0;
        return priceB.compareTo(priceA);
      }
      return 0;
    });

    return docs;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _searchController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    _categoryControllers.clear();
    super.dispose();
  }

  ScrollController _getCategoryController(String id) {
    return _categoryControllers.putIfAbsent(id, () => ScrollController());
  }

  Uint8List _decodeBase64(String base64String) => base64Decode(base64String);

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(title, style: AppStyles.headingStyle),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: AppColors.lightGold),
          decoration: InputDecoration(
            hintText: 'Search laptops, brands, categories...',
            hintStyle: const TextStyle(color: AppColors.softGold),
            prefixIcon: const Icon(Icons.search, color: AppColors.richGold),
            suffixIcon: _searchController.text.isNotEmpty
                ? Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.softGold),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.cardBlack,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isEmpty) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchScreen(
                  initialQuery: value.trim(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.lightGold,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.richGold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Category: $_selectedCategory', () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.cardBlack,
                      builder: (_) => ListView(
                        shrinkWrap: true,
                        children: categories
                            .map(
                              (cat) => ListTile(
                                title: Text(
                                  cat,
                                  style: const TextStyle(
                                    color: AppColors.lightGold,
                                  ),
                                ),
                                onTap: () {
                                  setState(() => _selectedCategory = cat);
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }),
                  _buildFilterChip('Brand: $_selectedBrand', () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.cardBlack,
                      builder: (_) => ListView(
                        shrinkWrap: true,
                        children: brands
                            .map(
                              (brand) => ListTile(
                                title: Text(
                                  brand,
                                  style: const TextStyle(
                                    color: AppColors.lightGold,
                                  ),
                                ),
                                onTap: () {
                                  setState(() => _selectedBrand = brand);
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }),
                  _buildFilterChip('Sort', () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.cardBlack,
                      builder: (_) => ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            title: const Text(
                              'Name (A-Z)',
                              style: TextStyle(color: AppColors.lightGold),
                            ),
                            onTap: () {
                              setState(() => _sortBy = 'name');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text(
                              'Price: Low to High',
                              style: TextStyle(color: AppColors.lightGold),
                            ),
                            onTap: () {
                              setState(() => _sortBy = 'price_low');
                              Navigator.pop(context);
                            },
                          ),
                          ListTile(
                            title: const Text(
                              'Price: High to Low',
                              style: TextStyle(color: AppColors.lightGold),
                            ),
                            onTap: () {
                              setState(() => _sortBy = 'price_high');
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(
                Icons.filter_alt_outlined,
                color: AppColors.richGold,
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRangeFilter() {
    if (!_showFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardBlack.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price Range',
                style: TextStyle(
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text(
                  'Clear All',
                  style: TextStyle(color: AppColors.richGold),
                ),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: AppColors.richGold,
            inactiveColor: AppColors.softGold,
            labels: RangeLabels(
              '\$${_minPrice.toInt()}',
              '\$${_maxPrice.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${_minPrice.toInt()}',
                style: const TextStyle(color: AppColors.softGold),
              ),
              Text(
                '\$${_maxPrice.toInt()}',
                style: const TextStyle(color: AppColors.softGold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCardFromFirebase(String name, String logoBase64) {
    final imageBytes = _decodeBase64(logoBase64);
    return Container(
      width: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.memory(imageBytes, height: 50),
          const SizedBox(height: 8),
          Text(name, style: AppStyles.smallTextStyle),
        ],
      ),
    );
  }

  Widget _buildProductCard(DocumentSnapshot productDoc) {
    final data = productDoc.data() as Map<String, dynamic>;
    final double price = double.tryParse(data['price'].toString()) ?? 0.0;
    final String productId = productDoc.id;

    // ✅ FIX: Check if productId is empty
    if (productId.isEmpty) {
      return const SizedBox.shrink();
    }

    final product = Product(
      id: productId,
      name: data['name'] ?? '',
      price: price,
      imageUrl: '',
    );

    final imageBytes = _decodeBase64(data['imageBase64']);
    final int stock = data['quantity'] ?? 0;
    final bool isOutOfStock = stock == 0;
    final bool isSelected = selectedProductIds.contains(productId);

    double rating = 0.0;
    int reviewCount = 0;

    try {
      if (productReviews.isNotEmpty && productReviews.containsKey(productId)) {
        final reviewData = productReviews[productId];
        if (reviewData != null) {
          rating = (reviewData['average'] ?? 0.0).toDouble();
          reviewCount = reviewData['count'] ?? 0;
        }
      }
    } catch (e) {
      print('Error getting review data: $e');
    }

    // ✅ FIX: Get current user safely
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(18),
        border: isSelected
            ? Border.all(color: AppColors.richGold, width: 2)
            : null,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Image.memory(
                  imageBytes,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // ✅ FIX: Only show wishlist if user is logged in
              if (userId.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('wishlists')
                        .doc(userId)
                        .collection('items')
                        .doc(productId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final isInWishlist =
                          snapshot.hasData && snapshot.data!.exists;

                      return GestureDetector(
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login first'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          final wishlistRef = FirebaseFirestore.instance
                              .collection('wishlists')
                              .doc(user.uid)
                              .collection('items')
                              .doc(productId);

                          if (isInWishlist) {
                            await wishlistRef.delete();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from wishlist'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } else {
                            await wishlistRef.set({
                              'productId': productId,
                              'productName': product.name,
                              'price': price,
                              'imageBase64': data['imageBase64'],
                              'addedAt': FieldValue.serverTimestamp(),
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Added to wishlist!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                            color: isInWishlist ? Colors.red : AppColors.richGold,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _toggleCompare(productDoc),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.richGold
                          : Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.richGold, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: AppColors.deepBlack,
                            size: 18,
                          )
                        : const Icon(
                            Icons.compare_arrows,
                            color: AppColors.richGold,
                            size: 16,
                          ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyStyle,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: AppStyles.cardValueStyle,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductReviewsScreen(
                              productId: productId,
                              productName: product.name,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.richGold,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0
                                ? '${rating.toStringAsFixed(1)} ($reviewCount)'
                                : 'No reviews',
                            style: const TextStyle(
                              color: AppColors.lightGold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailViewScreen(
                                  productId: productId,
                                  productName: product.name,
                                  productPrice: price,
                                  imageBase64: data['imageBase64'],
                                ),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.richGold,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Detail',
                          style: AppStyles.outlinedButtonTextStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(
                                        productId: productId,
                                        productName: product.name,
                                        productPrice: price,
                                        imageBase64: data['imageBase64'],
                                        availableStock: stock,
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          foregroundColor: AppColors.deepBlack,
                          disabledBackgroundColor: Colors.grey.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Buy',
                          style: AppStyles.buttonTextStyle,
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

  Widget _buildCategorySection(String categoryId, String categoryName) {
    final controller = _getCategoryController(categoryId);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('categoryId', isEqualTo: categoryId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        List<DocumentSnapshot> filteredDocs = _applyFiltersAndSort(
          snapshot.data!.docs,
        );

        if (filteredDocs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(categoryName),
            SizedBox(
              height: 250,
              child: HorizontalWheelScroll(
                controller: controller,
                child: ListView.builder(
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) =>
                      _buildProductCard(filteredDocs[index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              _buildFilterBar(),
              _buildPriceRangeFilter(),
              _buildSectionTitle('Browse Laptop Brands'),
              SizedBox(
                height: 130,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('brands')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.richGold,
                        ),
                      );
                    }

                    List<DocumentSnapshot> filteredBrands = snapshot.data!.docs;
                    if (_searchQuery.isNotEmpty) {
                      filteredBrands = filteredBrands.where((doc) {
                        final name = (doc['name'] ?? '')
                            .toString()
                            .toLowerCase();
                        return name.contains(_searchQuery.toLowerCase());
                      }).toList();
                    }

                    if (filteredBrands.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return HorizontalWheelScroll(
                      controller: _brandController,
                      child: ListView.builder(
                        controller: _brandController,
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredBrands.length,
                        itemBuilder: (context, index) {
                          final doc = filteredBrands[index];
                          return _buildBrandCardFromFirebase(
                            doc['name'],
                            doc['logoBase64'],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('categories')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }
                  return Column(
                    children: snapshot.data!.docs
                        .map(
                          (doc) => _buildCategorySection(doc.id, doc['name']),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
        if (selectedProductIds.length >= 2)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _openCompareScreen,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.richGold, Color(0xFFD4AF37)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.richGold.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.compare_arrows,
                        color: AppColors.deepBlack,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Compare ${selectedProductIds.length} Products',
                        style: const TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}