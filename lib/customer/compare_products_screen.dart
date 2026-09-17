import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';
import 'product_detail_screen.dart';

class CompareProductsScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> products;

  const CompareProductsScreen({
    Key? key,
    required this.products,
  }) : super(key: key);

  @override
  State<CompareProductsScreen> createState() => _CompareProductsScreenState();
}

class _CompareProductsScreenState extends State<CompareProductsScreen> {
  Map<String, String> brandNames = {};
  Map<String, String> categoryNames = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrandsAndCategories();
  }

  // ✅ Fetch Brand and Category Names
  Future<void> _loadBrandsAndCategories() async {
    try {
      // Get all unique brand IDs
      final brandIds = widget.products.values
          .map((p) => p['brandId'] as String?)
          .where((id) => id != null)
          .toSet();

      // Get all unique category IDs
      final categoryIds = widget.products.values
          .map((p) => p['categoryId'] as String?)
          .where((id) => id != null)
          .toSet();

      // Fetch brand names
      for (final brandId in brandIds) {
        final doc = await FirebaseFirestore.instance
            .collection('brands')
            .doc(brandId)
            .get();
        if (doc.exists) {
          brandNames[brandId!] = doc.data()?['name'] ?? 'Unknown';
        }
      }

      // Fetch category names
      for (final categoryId in categoryIds) {
        final doc = await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .get();
        if (doc.exists) {
          categoryNames[categoryId!] = doc.data()?['name'] ?? 'Unknown';
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading brands/categories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productList = widget.products.entries.toList();

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          backgroundColor: AppColors.deepBlack,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.lightGold),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Compare Products',
            style: TextStyle(color: AppColors.lightGold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.richGold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.lightGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Compare Products',
          style: TextStyle(color: AppColors.lightGold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== PRODUCT IMAGES ROW =====
            Container(
              color: AppColors.cardBlack,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: productList.map((entry) {
                  final data = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(data['imageBase64']),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['name'],
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.lightGold,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ===== COMPARISON TABLE =====
            _buildComparisonTable(productList),

            const SizedBox(height: 16),

            // ===== ACTION BUTTONS =====
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: productList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final productEntry = productList[index];
                  final productId = productEntry.key;
                  final data = productEntry.value;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                productId: productId,
                                productName: data['name'],
                                productPrice: double.tryParse(
                                        data['price'].toString()) ?? 0,
                                imageBase64: data['imageBase64'],
                                availableStock: data['quantity'] ?? 0,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Buy',
                          style: TextStyle(
                            color: AppColors.deepBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable(List<MapEntry<String, Map<String, dynamic>>> productList) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Price Row
          _buildComparisonRow(
            'Price',
            productList.map((e) => '\$${e.value['price']}').toList(),
            isHeader: true,
          ),

          // Stock Row
          _buildComparisonRow(
            'Stock',
            productList.map((e) {
              final stock = e.value['quantity'] ?? 0;
              return stock > 0 ? '$stock units' : 'Out of Stock';
            }).toList(),
          ),

          // ✅ Brand Row - Fixed
          _buildComparisonRow(
            'Brand',
            productList.map((e) {
              final brandId = e.value['brandId'] as String?;
              return brandId != null 
                  ? (brandNames[brandId] ?? 'Unknown')
                  : 'N/A';
            }).toList(),
          ),

          // ✅ Category Row - Fixed
          _buildComparisonRow(
            'Category',
            productList.map((e) {
              final categoryId = e.value['categoryId'] as String?;
              return categoryId != null 
                  ? (categoryNames[categoryId] ?? 'Unknown')
                  : 'N/A';
            }).toList(),
          ),

          // ✅ Description from specifications
          _buildComparisonRow(
            'Description',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['description'] ?? 'No description').toString();
              }
              return 'No description';
            }).toList(),
          ),

          // You can add more specs fields if needed
          _buildComparisonRow(
            'Processor',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['processor'] ?? 'Intel Core i7').toString();
              }
              return 'Intel Core i7';
            }).toList(),
          ),

          _buildComparisonRow(
            'RAM',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['ram'] ?? '16GB DDR4').toString();
              }
              return '16GB DDR4';
            }).toList(),
          ),

          _buildComparisonRow(
            'Storage',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['storage'] ?? '512GB SSD').toString();
              }
              return '512GB SSD';
            }).toList(),
          ),

          _buildComparisonRow(
            'Display',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['display'] ?? '15.6" FHD').toString();
              }
              return '15.6" FHD';
            }).toList(),
          ),

          _buildComparisonRow(
            'Graphics',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['graphics'] ?? 'NVIDIA GTX').toString();
              }
              return 'NVIDIA GTX';
            }).toList(),
          ),

          _buildComparisonRow(
            'Warranty',
            productList.map((e) {
              final specs = e.value['specifications'];
              if (specs != null && specs is Map) {
                return (specs['warranty'] ?? '1 Year').toString();
              }
              return '1 Year';
            }).toList(),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    List<String> values, {
    bool isHeader = false,
    bool isLast = false,
  }) {
    // Find best value (lowest price or highest stock)
    int bestIndex = -1;
    if (label == 'Price') {
      double minPrice = double.infinity;
      for (int i = 0; i < values.length; i++) {
        final price = double.tryParse(values[i].replaceAll('\$', '')) ?? double.infinity;
        if (price < minPrice) {
          minPrice = price;
          bestIndex = i;
        }
      }
    } else if (label == 'Stock') {
      int maxStock = -1;
      for (int i = 0; i < values.length; i++) {
        final stock = int.tryParse(values[i].split(' ').first) ?? -1;
        if (stock > maxStock) {
          maxStock = stock;
          bestIndex = i;
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(
                  color: AppColors.richGold.withOpacity(0.2),
                ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // Label Column
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: isHeader ? AppColors.richGold : AppColors.softGold,
                  fontSize: 13,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),

            // Value Columns
            ...values.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              final isBest = index == bestIndex;

              return Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: isBest
                      ? BoxDecoration(
                          color: AppColors.richGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.richGold.withOpacity(0.5),
                          ),
                        )
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isBest)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.star,
                            color: AppColors.richGold,
                            size: 14,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isBest
                                ? AppColors.richGold
                                : AppColors.lightGold,
                            fontSize: isHeader ? 14 : 12,
                            fontWeight: isHeader || isBest
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}