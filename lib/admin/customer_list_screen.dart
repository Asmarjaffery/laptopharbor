import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: AppColors.deepBlack,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Real-time Customer List from Firestore
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'customer')
                    .snapshots(),
                builder: (context, snapshot) {
                  // Loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.richGold,
                      ),
                    );
                  }

                  // Error state
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading customers',
                            style: TextStyle(
                                color: AppColors.softGold, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            style: TextStyle(
                              color: AppColors.softGold.withOpacity(0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  // No data state
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 80,
                            color: AppColors.richGold.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No customers yet',
                            style: TextStyle(
                              color: AppColors.softGold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Customers will appear here automatically',
                            style: TextStyle(
                              color: AppColors.softGold.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Display customers
                  var customers = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      var customerData =
                          customers[index].data() as Map<String, dynamic>;
                      String customerId = customers[index].id;

                      String name = customerData['name'] ?? 'Unknown Customer';
                      String email = customerData['email'] ?? '';
                      String phone = customerData['phone'] ?? '';
                      bool isBlocked = customerData['isBlocked'] ?? false;

                      // Properly handle image binary data
                      Uint8List? imageBytes;
                      if (customerData['imageBinary'] != null) {
                        try {
                          var imgData = customerData['imageBinary'];
                          if (imgData is Uint8List) {
                            imageBytes = imgData;
                          } else if (imgData is List) {
                            imageBytes =
                                Uint8List.fromList(List<int>.from(imgData));
                          }
                        } catch (e) {
                          print('Error loading image: $e');
                        }
                      }

                      return Card(
                        color: AppColors.cardBlack,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.richGold.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: Stack(
                            children: [
                              imageBytes != null
                                  ? CircleAvatar(
                                      radius: 30,
                                      backgroundImage: MemoryImage(imageBytes),
                                      backgroundColor: Colors.transparent,
                                    )
                                  : CircleAvatar(
                                      radius: 30,
                                      backgroundColor: AppColors.richGold,
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : 'C',
                                        style: TextStyle(
                                          color: AppColors.deepBlack,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              if (isBlocked)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.block,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: AppColors.lightGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isBlocked)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.red, width: 1),
                                  ),
                                  child: Text(
                                    'BLOCKED',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              if (phone.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone_outlined,
                                      size: 14,
                                      color: AppColors.softGold.withOpacity(0.7),
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        phone,
                                        style: TextStyle(
                                          color: AppColors.softGold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_outlined,
                                    size: 14,
                                    color: AppColors.softGold.withOpacity(0.7),
                                  ),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: TextStyle(
                                        color:
                                            AppColors.softGold.withOpacity(0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: AppColors.lightGold,
                            ),
                            color: AppColors.cardBlack,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility,
                                        color: AppColors.richGold, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'View Details',
                                      style: TextStyle(color: AppColors.softGold),
                                    ),
                                  ],
                                ),
                                value: 'view',
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(
                                      isBlocked ? Icons.check_circle : Icons.block,
                                      color: isBlocked ? Colors.green : Colors.orange,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      isBlocked ? 'Unblock' : 'Block/Suspend',
                                      style: TextStyle(color: AppColors.softGold),
                                    ),
                                  ],
                                ),
                                value: 'block',
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    Icon(Icons.delete,
                                        color: Colors.redAccent, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.softGold),
                                    ),
                                  ],
                                ),
                                value: 'delete',
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'view') {
                                _showCustomerDetails(context, customerData, imageBytes);
                              } else if (value == 'block') {
                                _toggleBlockStatus(context, customerId, name, isBlocked);
                              } else if (value == 'delete') {
                                _showDeleteConfirmation(
                                    context, customerId, name);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Map<String, dynamic> customerData, Uint8List? imageBytes) {
    String name = customerData['name'] ?? 'Unknown Customer';
    String email = customerData['email'] ?? 'N/A';
    String phone = customerData['phone'] ?? 'N/A';
    String address = customerData['address'] ?? 'N/A';
    bool isBlocked = customerData['isBlocked'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Row(
          children: [
            Text(
              'Customer Details',
              style: TextStyle(color: AppColors.lightGold, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            if (isBlocked)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red, width: 1),
                ),
                child: Text(
                  'BLOCKED',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image
              imageBytes != null
                  ? CircleAvatar(
                      radius: 50,
                      backgroundImage: MemoryImage(imageBytes),
                      backgroundColor: Colors.transparent,
                    )
                  : CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.richGold,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              SizedBox(height: 20),
              
              // Customer Details
              _buildDetailRow('Name', name, Icons.person),
              SizedBox(height: 12),
              _buildDetailRow('Email', email, Icons.email),
              SizedBox(height: 12),
              _buildDetailRow('Phone', phone, Icons.phone),
              SizedBox(height: 12),
              _buildDetailRow('Address', address, Icons.location_on),
              SizedBox(height: 12),
              _buildDetailRow('Status', isBlocked ? 'Blocked' : 'Active', 
                  isBlocked ? Icons.block : Icons.check_circle,
                  valueColor: isBlocked ? Colors.red : Colors.green),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.softGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.richGold, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.softGold.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? AppColors.lightGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBlockStatus(BuildContext context, String customerId, String customerName, bool currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          currentStatus ? 'Unblock Customer' : 'Block Customer',
          style: TextStyle(color: AppColors.lightGold),
        ),
        content: Text(
          currentStatus 
              ? 'Are you sure you want to unblock "$customerName"? They will be able to use the app again.'
              : 'Are you sure you want to block "$customerName"? They will not be able to use the app.',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.softGold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(customerId)
                    .update({'isBlocked': !currentStatus});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(currentStatus 
                        ? 'Customer unblocked successfully' 
                        : 'Customer blocked successfully'),
                    backgroundColor: AppColors.richGold,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update customer status'),
                    backgroundColor: Colors.red[900],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? Colors.green : Colors.orange,
            ),
            child: Text(currentStatus ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String customerId, String customerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text(
          'Delete Customer',
          style: TextStyle(color: AppColors.lightGold),
        ),
        content: Text(
          'Are you sure you want to delete "$customerName"? This action cannot be undone.',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.softGold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(customerId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Customer deleted successfully'),
                    backgroundColor: AppColors.richGold,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete customer'),
                    backgroundColor: Colors.red[900],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}