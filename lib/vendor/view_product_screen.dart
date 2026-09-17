import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';

class ViewProductScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ViewProductScreen({super.key, required this.productData});

  @override
  State<ViewProductScreen> createState() => _ViewProductScreenState();
}

class _ViewProductScreenState extends State<ViewProductScreen> {
  String categoryName = '';
  String brandName = '';

  @override
  void initState() {
    super.initState();
    _fetchCategoryAndBrand();
  }

  Future<void> _fetchCategoryAndBrand() async {
    try {
      final categoryId = widget.productData['categoryId'];
      final brandId = widget.productData['brandId'];

      if (categoryId != null) {
        final catDoc = await FirebaseFirestore.instance
            .collection('categories')
            .doc(categoryId)
            .get();
        if (catDoc.exists) {
          categoryName = catDoc['name'];
        }
      }

      if (brandId != null) {
        final brandDoc = await FirebaseFirestore.instance
            .collection('brands')
            .doc(brandId)
            .get();
        if (brandDoc.exists) {
          brandName = brandDoc['name'];
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Category/Brand fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;

    try {
      if (widget.productData['imageBase64'] != null &&
          widget.productData['imageBase64'].isNotEmpty) {
        imageBytes = base64Decode(widget.productData['imageBase64']);
      }
    } catch (_) {}

    final specs =
        widget.productData['specifications'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          'Product Details',
          style: TextStyle(color: AppColors.lightGold),
        ),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      )
                    : _placeholderImage(),
              ),
            ),
            const SizedBox(height: 20),

            // BASIC INFO
            _detailRow('Name', widget.productData['name']),
            _detailRow('Vendor', widget.productData['vendorName']),
            _detailRow('Category',
                categoryName.isNotEmpty ? categoryName : 'Loading...'),
            _detailRow(
                'Brand', brandName.isNotEmpty ? brandName : 'Loading...'),
            _detailRow(
                'Price', '\$${widget.productData['price'] ?? 0}'),
            _detailRow(
                'Stock', '${widget.productData['quantity'] ?? 0}'),
            _detailRow(
              'Status',
              widget.productData['isApproved'] == true
                  ? 'Approved'
                  : 'Pending',
              valueColor: widget.productData['isApproved'] == true
                  ? Colors.green
                  : Colors.orange,
            ),

            /// ✅ DESCRIPTION (FIXED)
            _detailRow(
              'Description',
              specs['description'] ?? 'No description provided',
            ),

            const SizedBox(height: 16),

            // HARDWARE
            _sectionTitle('Hardware Specifications'),
            _detailRow('Processor', specs['processor']),
            _detailRow('RAM', specs['ram']),
            _detailRow('Storage', specs['storage']),
            _detailRow('Graphics', specs['graphics']),

            const SizedBox(height: 16),

            // DISPLAY
            _sectionTitle('Display Specifications'),
            _detailRow('Screen Size', specs['displaySize']),
            _detailRow('Resolution', specs['resolution']),
            _detailRow('Refresh Rate', specs['refreshRate']),
            _detailRow('Display Type', specs['displayType']),

            const SizedBox(height: 16),

            // BATTERY
            _sectionTitle('Battery & Physical'),
            _detailRow('Battery', specs['battery']),
            _detailRow('Weight', specs['weight']),
            _detailRow('Dimensions', specs['dimensions']),

            const SizedBox(height: 16),

            // CONNECTIVITY
            _sectionTitle('Connectivity & Ports'),
            _detailRow('Ports', specs['ports']),
            _detailRow('Connectivity', specs['connectivity']),

            const SizedBox(height: 16),

            // SOFTWARE
            _sectionTitle('Software & Warranty'),
            _detailRow('Operating System', specs['os']),
            _detailRow('Warranty', specs['warranty']),

            const SizedBox(height: 16),

            // EXTRA
            _sectionTitle('Additional Features'),
            _detailRow('Webcam', specs['webcam']),
            _detailRow('Keyboard', specs['keyboard']),
            _detailRow('Audio', specs['audio']),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _placeholderImage() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.image_not_supported,
        size: 60,
        color: AppColors.richGold.withOpacity(0.4),
      ),
    );
  }

  Widget _detailRow(String label, String? value, {Color? valueColor}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.lightGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.softGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.richGold,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
