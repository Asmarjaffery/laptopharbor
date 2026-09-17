import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../common/navbar.dart';
import 'product_detail_screen.dart';
import 'product_detail_view_screen.dart';
import 'package:mobileapp/customer/compare_products_screen.dart';
import 'package:mobileapp/constants/styles.dart';
import 'package:mobileapp/customer/add_review_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  
  const SearchScreen({Key? key, this.initialQuery = ''}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedBrand = 'All';
  String _sortBy = 'name';
  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _showFilters = false;

  Set<String> selectedProductIds = {};
  Map<String, Map<String, dynamic>> selectedProducts = {};
  Map<String, Map<String, dynamic>> productReviews = {};

  List<String> categories = ['All'];
  List<String> brands = ['All'];
  
  Map<String, String> categoryIdToName = {};
  Map<String, String> brandIdToName = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchQuery = widget.initialQuery;
      _searchController.text = widget.initialQuery;
    }
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
          categoryIdToName = {
            for (var doc in catSnapshot.docs) doc.id: doc['name'] as String
          };
          
          brandIdToName = {
            for (var doc in brandSnapshot.docs) doc.id: doc['name'] as String
          };
          
          categories = ['All', ...categoryIdToName.values];
          brands = ['All', ...brandIdToName.values];
        });
      }
    } catch (e) {
      print('Error loading filters: $e');
    }
  }

  Uint8List _decode(String img) => base64Decode(img);

  List<DocumentSnapshot> _applyFiltersAndSort(List<DocumentSnapshot> docs) {
    if (_searchQuery.isNotEmpty) {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final brandId = data['brandId'] ?? '';
        final brandName = (brandIdToName[brandId] ?? '').toLowerCase();
        final categoryId = data['categoryId'] ?? '';
        final categoryName = (categoryIdToName[categoryId] ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        return name.contains(query) || 
               brandName.contains(query) || 
               categoryName.contains(query);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final categoryId = data['categoryId'] ?? '';
        final categoryName = categoryIdToName[categoryId] ?? '';
        return categoryName == _selectedCategory;
      }).toList();
    }

    if (_selectedBrand != 'All') {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final brandId = data['brandId'] ?? '';
        final brandName = brandIdToName[brandId] ?? '';
        return brandName == _selectedBrand;
      }).toList();
    }

    docs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final price = double.tryParse(data['price'].toString()) ?? 0;
      return price >= _minPrice && price <= _maxPrice;
    }).toList();

    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      if (_sortBy == 'name') {
        return (dataA['name'] ?? '').toString().compareTo((dataB['name'] ?? '').toString());
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
            Text(label, style: const TextStyle(color: AppColors.lightGold, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppColors.richGold, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _gridCard(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final img = _decode(d['imageBase64']);
    final int stock = d['quantity'] ?? 0;
    final bool isOutOfStock = stock == 0;
    final bool isSelected = selectedProductIds.contains(doc.id);

    double rating = 0.0;
    int reviewCount = 0;

    try {
      if (productReviews.isNotEmpty && productReviews.containsKey(doc.id)) {
        final reviewData = productReviews[doc.id];
        if (reviewData != null) {
          rating = (reviewData['average'] ?? 0.0).toDouble();
          reviewCount = reviewData['count'] ?? 0;
        }
      }
    } catch (e) {
      print('Error getting review data: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: AppColors.richGold, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(img, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      if (isOutOfStock)
                        Container(
                          color: Colors.black.withOpacity(0.7),
                          alignment: Alignment.center,
                          child: const Text('OUT OF\nSTOCK', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8, left: 8,
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('wishlists').doc(FirebaseAuth.instance.currentUser?.uid ?? '').collection('items').doc(doc.id).snapshots(),
                    builder: (context, snapshot) {
                      final isInWishlist = snapshot.hasData && snapshot.data!.exists;
                      return GestureDetector(
                        onTap: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login first'), backgroundColor: Colors.orange));
                            return;
                          }
                          final wishlistRef = FirebaseFirestore.instance.collection('wishlists').doc(user.uid).collection('items').doc(doc.id);
                          if (isInWishlist) {
                            await wishlistRef.delete();
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from wishlist'), backgroundColor: Colors.orange));
                          } else {
                            await wishlistRef.set({'productId': doc.id, 'productName': d['name'], 'price': double.tryParse(d['price'].toString()) ?? 0, 'imageBase64': d['imageBase64'], 'addedAt': FieldValue.serverTimestamp()});
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to wishlist!'), backgroundColor: Colors.green));
                          }
                        },
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]),
                          child: Icon(isInWishlist ? Icons.favorite : Icons.favorite_border, color: isInWishlist ? Colors.red : AppColors.richGold, size: 18),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleCompare(doc),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(color: isSelected ? AppColors.richGold : Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.richGold, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]),
                      child: isSelected ? const Icon(Icons.check, color: AppColors.deepBlack, size: 18) : const Icon(Icons.compare_arrows, color: AppColors.richGold, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(d['name'], maxLines: 2, overflow: TextOverflow.ellipsis, style: AppStyles.bodyStyle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${d['price']}', style: AppStyles.cardValueStyle),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductReviewsScreen(productId: doc.id, productName: d['name']))),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.richGold, size: 14),
                            const SizedBox(width: 4),
                            Text(rating > 0 ? '${rating.toStringAsFixed(1)} ($reviewCount)' : 'No reviews', style: const TextStyle(color: AppColors.lightGold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailViewScreen(productId: doc.id, productName: d['name'], productPrice: double.tryParse(d['price'].toString()) ?? 0, imageBase64: d['imageBase64']))),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.richGold, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Detail', style: AppStyles.outlinedButtonTextStyle),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isOutOfStock ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: doc.id, productName: d['name'], productPrice: double.tryParse(d['price'].toString()) ?? 0, imageBase64: d['imageBase64'], availableStock: stock))),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack, disabledBackgroundColor: Colors.grey.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          child: const Text('Buy', style: AppStyles.buttonTextStyle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleBasedNav(
      role: UserRole.customer,
      child: Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(backgroundColor: AppColors.deepBlack, elevation: 0, title: const Text('Search Products', style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold)), iconTheme: const IconThemeData(color: AppColors.richGold)),
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.lightGold),
                    decoration: InputDecoration(
                      hintText: 'Search laptops, brands, categories...',
                      hintStyle: const TextStyle(color: AppColors.softGold),
                      prefixIcon: const Icon(Icons.search, color: AppColors.richGold),
                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: AppColors.softGold), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; })) : null,
                      filled: true,
                      fillColor: AppColors.cardBlack,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                Container(
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
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => DraggableScrollableSheet(
                                    initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
                                    builder: (context, scrollController) => Container(
                                      decoration: const BoxDecoration(color: AppColors.cardBlack, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      child: Column(
                                        children: [
                                          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.softGold, borderRadius: BorderRadius.circular(2))),
                                          const Padding(padding: EdgeInsets.all(16), child: Text('Select Category', style: TextStyle(color: AppColors.richGold, fontSize: 18, fontWeight: FontWeight.bold))),
                                          Expanded(
                                            child: ListView.builder(
                                              controller: scrollController,
                                              itemCount: categories.length,
                                              itemBuilder: (context, index) {
                                                final cat = categories[index];
                                                return ListTile(
                                                  title: Text(cat, style: const TextStyle(color: AppColors.lightGold)),
                                                  trailing: _selectedCategory == cat ? const Icon(Icons.check, color: AppColors.richGold) : null,
                                                  onTap: () { setState(() => _selectedCategory = cat); Navigator.pop(context); },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              _buildFilterChip('Brand: $_selectedBrand', () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder: (_) => DraggableScrollableSheet(
                                    initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.9, expand: false,
                                    builder: (context, scrollController) => Container(
                                      decoration: const BoxDecoration(color: AppColors.cardBlack, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                      child: Column(
                                        children: [
                                          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.softGold, borderRadius: BorderRadius.circular(2))),
                                          const Padding(padding: EdgeInsets.all(16), child: Text('Select Brand', style: TextStyle(color: AppColors.richGold, fontSize: 18, fontWeight: FontWeight.bold))),
                                          Expanded(
                                            child: ListView.builder(
                                              controller: scrollController,
                                              itemCount: brands.length,
                                              itemBuilder: (context, index) {
                                                final brand = brands[index];
                                                return ListTile(
                                                  title: Text(brand, style: const TextStyle(color: AppColors.lightGold)),
                                                  trailing: _selectedBrand == brand ? const Icon(Icons.check, color: AppColors.richGold) : null,
                                                  onTap: () { setState(() => _selectedBrand = brand); Navigator.pop(context); },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              _buildFilterChip('Sort', () {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: AppColors.cardBlack,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                  builder: (_) => Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Sort By', style: TextStyle(color: AppColors.richGold, fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 10),
                                        ListTile(title: const Text('Name (A-Z)', style: TextStyle(color: AppColors.lightGold)), trailing: _sortBy == 'name' ? const Icon(Icons.check, color: AppColors.richGold) : null, onTap: () { setState(() => _sortBy = 'name'); Navigator.pop(context); }),
                                        ListTile(title: const Text('Price: Low to High', style: TextStyle(color: AppColors.lightGold)), trailing: _sortBy == 'price_low' ? const Icon(Icons.check, color: AppColors.richGold) : null, onTap: () { setState(() => _sortBy = 'price_low'); Navigator.pop(context); }),
                                        ListTile(title: const Text('Price: High to Low', style: TextStyle(color: AppColors.lightGold)), trailing: _sortBy == 'price_high' ? const Icon(Icons.check, color: AppColors.richGold) : null, onTap: () { setState(() => _sortBy = 'price_high'); Navigator.pop(context); }),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      IconButton(icon: Icon(_showFilters ? Icons.filter_alt : Icons.filter_alt_outlined, color: AppColors.richGold), onPressed: () => setState(() => _showFilters = !_showFilters)),
                    ],
                  ),
                ),
                if (_showFilters)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.cardBlack.withOpacity(0.5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Price Range', style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold)),
                            TextButton(onPressed: _clearFilters, child: const Text('Clear All', style: TextStyle(color: AppColors.richGold))),
                          ],
                        ),
                        RangeSlider(values: RangeValues(_minPrice, _maxPrice), min: 0, max: 10000, divisions: 100, activeColor: AppColors.richGold, inactiveColor: AppColors.softGold, labels: RangeLabels('\$${_minPrice.toInt()}', '\$${_maxPrice.toInt()}'), onChanged: (values) => setState(() { _minPrice = values.start; _maxPrice = values.end; })),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('\$${_minPrice.toInt()}', style: const TextStyle(color: AppColors.softGold)), Text('\$${_maxPrice.toInt()}', style: const TextStyle(color: AppColors.softGold))]),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('products').where('isApproved', isEqualTo: true).where('isActive', isEqualTo: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.richGold));
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 64, color: AppColors.softGold), const SizedBox(height: 16), const Text('No products available', style: TextStyle(color: AppColors.lightGold, fontSize: 18, fontWeight: FontWeight.w600))]));
                      
                      final filteredDocs = _applyFiltersAndSort(snapshot.data!.docs);
                      
                      if (filteredDocs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 64, color: AppColors.softGold), const SizedBox(height: 16), const Text('No products found', style: TextStyle(color: AppColors.lightGold, fontSize: 18, fontWeight: FontWeight.w600)), const SizedBox(height: 8), const Text('Try adjusting your filters', style: TextStyle(color: AppColors.softGold, fontSize: 14)), const SizedBox(height: 16), ElevatedButton(onPressed: _clearFilters, style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold, foregroundColor: AppColors.deepBlack), child: const Text('Clear Filters'))]));
                      
                      return GridView.builder(padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 90), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.72), itemCount: filteredDocs.length, itemBuilder: (_, i) => _gridCard(filteredDocs[i]));
                    },
                  ),
                ),
              ],
            ),
            if (selectedProductIds.length >= 2)
              Positioned(
                bottom: 16, left: 16, right: 16,
                child: Material(
                  elevation: 12,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: _openCompareScreen,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.richGold, Color(0xFFD4AF37)]), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppColors.richGold.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.compare_arrows, color: AppColors.deepBlack, size: 24), const SizedBox(width: 10), Text('Compare ${selectedProductIds.length} Products', style: const TextStyle(color: AppColors.deepBlack, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5))]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}