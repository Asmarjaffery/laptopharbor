import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';
import 'view_product_screen.dart';
import 'edit_product_screen.dart';

class VendorProductListScreen extends StatelessWidget {
  const VendorProductListScreen({super.key});

  // Delete Product Function
  Future<void> _deleteProduct(BuildContext context, String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Delete Product',
          style: TextStyle(color: AppColors.lightGold),
        ),
        content: Text(
          'Are you sure you want to delete this product?',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: AppColors.richGold,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: $e'),
              backgroundColor: Colors.red[900],
            ),
          );
        }
      }
    }
  }

  // Edit Product Function
  Future<void> _editProduct(
    BuildContext context,
    String productId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Navigate to EditProductScreen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProductScreen(
            productId: productId,
            productData: data,
          ),
        ),
      );

      // Show success message if product was updated
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: AppColors.richGold,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening edit screen: $e'),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        body: Center(
          child: Text(
            'Please login to view products',
            style: TextStyle(color: AppColors.softGold),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text(
          'My Products',
          style: TextStyle(color: AppColors.lightGold),
        ),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('vendorId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.richGold),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No products added yet',
                    style: TextStyle(
                      color: AppColors.softGold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;
          products.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final doc = products[index];
              final data = doc.data() as Map<String, dynamic>;
              final productId = doc.id;

              Uint8List? imageBytes;
              try {
                if (data['imageBase64'] != null &&
                    data['imageBase64'].toString().isNotEmpty) {
                  imageBytes = base64Decode(data['imageBase64']);
                }
              } catch (e) {
                print('Image decode error: $e');
              }

              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageBytes != null
                          ? Image.memory(
                              imageBytes,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderImage();
                              },
                            )
                          : _buildPlaceholderImage(),
                    ),
                    SizedBox(width: 12),

                    // Product Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'] ?? 'Unknown Product',
                            style: TextStyle(
                              color: AppColors.lightGold,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Price: \$${data['price'] ?? 0}',
                            style: TextStyle(color: AppColors.softGold),
                          ),
                          Text(
                            'Stock: ${data['quantity'] ?? 0}',
                            style: TextStyle(color: AppColors.softGold),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge & Menu
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Status Badge
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: data['isApproved'] == true
                                ? Colors.green
                                : Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data['isApproved'] == true ? 'Approved' : 'Pending',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),

                        // Popup Menu for Edit, Delete, View
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_vert,
                            color: AppColors.richGold,
                            size: 24,
                          ),
                          color: AppColors.cardBlack,
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await _editProduct(context, productId, data);
                            } else if (value == 'delete') {
                              await _deleteProduct(context, productId);
                            } else if (value == 'view') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ViewProductScreen(productData: data),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility,
                                      color: AppColors.lightGold, size: 20),
                                  SizedBox(width: 8),
                                  Text('View',
                                      style:
                                          TextStyle(color: AppColors.lightGold)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: AppColors.lightGold, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit',
                                      style:
                                          TextStyle(color: AppColors.lightGold)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: AppColors.richGold.withOpacity(0.5),
        size: 30,
      ),
    );
  }
}