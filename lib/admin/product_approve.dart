import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../constants/colors.dart';

class ProductApprovalScreen extends StatefulWidget {
  const ProductApprovalScreen({super.key});

  @override
  State<ProductApprovalScreen> createState() => _ProductApprovalScreenState();
}

class _ProductApprovalScreenState extends State<ProductApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollectionReference productsRef =
      FirebaseFirestore.instance.collection('products');
  final CollectionReference notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> approveProduct(String docId, Map<String, dynamic> productData) async {
    try {
      await productsRef.doc(docId).update({
        'isApproved': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await _sendNotification(
        userId: productData['vendorId'] ?? '',
        title: 'Product Approved ✅',
        message: 'Your product "${productData['name']}" has been approved and is now live!',
        vendorName: 'LaptopHarbor Admin',
        productId: docId,
        productImage: productData['imageBase64'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Product approved successfully"),
            backgroundColor: AppColors.richGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to approve product: $e"),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  Future<void> rejectProduct(String docId, Map<String, dynamic> productData) async {
    final reasonController = TextEditingController();
    
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Reject Product', style: TextStyle(color: AppColors.lightGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to reject this product?',
              style: TextStyle(color: AppColors.softGold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter rejection reason (required)',
                hintStyle: TextStyle(color: AppColors.softGold.withOpacity(0.5)),
                filled: true,
                fillColor: AppColors.deepBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.richGold),
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
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && reasonController.text.trim().isNotEmpty) {
      try {
        final reason = reasonController.text.trim();
        
        await productsRef.doc(docId).update({
          'isApproved': false,
          'isRejected': true,
          'rejectionReason': reason,
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        await _sendNotification(
          userId: productData['vendorId'] ?? '',
          title: 'Product Rejected ❌',
          message: 'Your product "${productData['name']}" was rejected. Reason: $reason',
          vendorName: 'LaptopHarbor Admin',
          productId: docId,
          productImage: null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Product rejected and vendor notified"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to reject product: $e"),
              backgroundColor: Colors.red[900],
            ),
          );
        }
      }
    }
  }

  Future<void> _sendNotification({
    required String userId,
    required String title,
    required String message,
    required String vendorName,
    String? productId,
    String? productImage,
  }) async {
    try {
      if (userId.isEmpty) return;

      final docRef = notificationsRef.doc();
      await docRef.set({
        'id': docRef.id,
        'userId': userId,
        'title': title,
        'message': message,
        'vendorName': vendorName,
        'productId': productId,
        'productImage': productImage,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null || categoryId.isEmpty) return 'Unknown';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .get();
      return doc.data()?['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<String> getBrandName(String? brandId) async {
    if (brandId == null || brandId.isEmpty) return 'Unknown';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('brands')
          .doc(brandId)
          .get();
      return doc.data()?['name'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildProductImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.image_not_supported,
          color: AppColors.softGold,
          size: 64,
        ),
      );
    }

    try {
      final Uint8List bytes = base64Decode(imageBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.broken_image,
          color: Colors.redAccent,
          size: 64,
        ),
      );
    }
  }

  void showProductDetails(Map<String, dynamic> product, String docId, bool isApproved) async {
    final categoryName = await getCategoryName(product['categoryId']);
    final brandName = await getBrandName(product['brandId']);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? 'Product Details',
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.lightGold),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductImage(product['imageBase64']),
                      SizedBox(height: 16),
                      
                      _detailRow('Vendor', product['vendorName'] ?? 'Unknown Vendor'),
                      _detailRow('Category', categoryName),
                      _detailRow('Brand', brandName),
                      _detailRow('Price', '\$${product['price'] ?? 0}'),
                      _detailRow('Quantity', '${product['quantity'] ?? 0}'),
                      SizedBox(height: 12),
                      
                      Text(
                        'Description:',
                        style: TextStyle(
                          color: AppColors.richGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        product['description'] ?? 'No description',
                        style: TextStyle(color: AppColors.softGold),
                      ),
                      
                      if (product['specifications'] != null) ...[
                        SizedBox(height: 12),
                        Text(
                          'Specifications:',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...(() {
                          try {
                            final specs = product['specifications'];
                            if (specs is List) {
                              return specs.map((spec) {
                                if (spec is Map) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: AppColors.richGold, size: 16),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${spec['key'] ?? ''}: ${spec['value'] ?? ''}',
                                            style: TextStyle(color: AppColors.softGold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              }).toList();
                            }
                            return [SizedBox.shrink()];
                          } catch (e) {
                            return [SizedBox.shrink()];
                          }
                        })(),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close', style: TextStyle(color: AppColors.softGold)),
                    ),
                    if (!isApproved) ...[
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          Navigator.pop(context);
                          rejectProduct(docId, product);
                        },
                        child: Text('Reject', style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
                        onPressed: () {
                          Navigator.pop(context);
                          approveProduct(docId, product);
                        },
                        child: Text('Approve', style: TextStyle(color: AppColors.deepBlack)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppColors.lightGold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItemImage(String? imageBase64) {
    if (imageBase64 == null || imageBase64.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.inventory_2,
          color: AppColors.richGold,
          size: 28,
        ),
      );
    }

    try {
      final Uint8List bytes = base64Decode(imageBase64);
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (e) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.deepBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.richGold.withOpacity(0.3),
          ),
        ),
        child: Icon(
          Icons.broken_image,
          color: Colors.redAccent,
          size: 28,
        ),
      );
    }
  }

  Widget _buildProductsList(bool isApproved) {
    return StreamBuilder<QuerySnapshot>(
      stream: productsRef
          .where('isApproved', isEqualTo: isApproved)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.redAccent),
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

        final products = snapshot.data!.docs;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isApproved ? Icons.inventory_2 : Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.richGold.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  isApproved ? "No approved products" : "No pending approvals",
                  style: TextStyle(
                    color: AppColors.richGold,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isApproved 
                      ? "Approved products will appear here"
                      : "All products have been reviewed",
                  style: TextStyle(
                    color: AppColors.softGold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final productData = product.data() as Map<String, dynamic>;

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.3),
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: _buildListItemImage(productData['imageBase64']),
                title: Text(
                  productData['name'] ?? 'Unnamed Product',
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Vendor: ${productData['vendorName'] ?? 'Unknown Vendor'}',
                      style: TextStyle(
                        color: AppColors.softGold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.monetization_on,
                            color: AppColors.richGold, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '\$${productData['price'] ?? 0}',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.inventory,
                            color: AppColors.softGold, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Qty: ${productData['quantity'] ?? 0}',
                          style: TextStyle(color: AppColors.softGold),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: AppColors.lightGold),
                  color: AppColors.cardBlack,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: AppColors.richGold, size: 20),
                          SizedBox(width: 8),
                          Text('View Details', style: TextStyle(color: AppColors.softGold)),
                        ],
                      ),
                      value: 'view',
                    ),
                    if (!isApproved) ...[
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Approve', style: TextStyle(color: AppColors.softGold)),
                          ],
                        ),
                        value: 'approve',
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Reject', style: TextStyle(color: AppColors.softGold)),
                          ],
                        ),
                        value: 'reject',
                      ),
                    ],
                  ],
                  onSelected: (value) {
                    if (value == 'view') {
                      showProductDetails(productData, product.id, isApproved);
                    } else if (value == 'approve') {
                      approveProduct(product.id, productData);
                    } else if (value == 'reject') {
                      rejectProduct(product.id, productData);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Product Management', style: TextStyle(color: AppColors.lightGold)),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.richGold,
          labelColor: AppColors.richGold,
          unselectedLabelColor: AppColors.softGold.withOpacity(0.5),
          tabs: [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsList(false), // Pending
          _buildProductsList(true),  // Approved
        ],
      ),
    );
  }
}