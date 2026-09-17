import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/colors.dart';
import '../routes/app_routes.dart';

class RiderListScreen extends StatefulWidget {
  const RiderListScreen({super.key});

  @override
  State<RiderListScreen> createState() => _RiderListScreenState();
}

class _RiderListScreenState extends State<RiderListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.richGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rider Management',
          style: TextStyle(
            color: AppColors.richGold,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Add New Rider Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addRider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: AppColors.deepBlack, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Add New Rider',
                    style: TextStyle(
                      color: AppColors.deepBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Riders List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'rider')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.motorcycle,
                          size: 80,
                          color: AppColors.richGold.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No riders found',
                          style: TextStyle(
                            color: AppColors.richGold.withOpacity(0.7),
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first rider to get started',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final riders = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: riders.length,
                  itemBuilder: (context, index) {
                    final rider = riders[index].data() as Map<String, dynamic>;
                    final riderId = riders[index].id;

                    return _buildRiderCard(
                      riderId: riderId,
                      name: rider['name'] ?? 'Unknown',
                      email: rider['email'] ?? 'No email',
                      vehicleType: rider['vehicleType'] ?? 'N/A',
                      vehicleNumber: rider['vehicleNumber'] ?? 'N/A',
                      phone: rider['phone'] ?? 'No phone',
                      isAvailable: rider['isAvailable'] ?? false,
                      imageBinary: rider['imageBinary'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard({
    required String riderId,
    required String name,
    required String email,
    required String vehicleType,
    required String vehicleNumber,
    required String phone,
    required bool isAvailable,
    dynamic imageBinary,
  }) {
    // Convert imageBinary to Uint8List
    Uint8List? imageBytes;
    if (imageBinary != null) {
      if (imageBinary is Uint8List) {
        imageBytes = imageBinary;
      } else if (imageBinary is List) {
        try {
          imageBytes = Uint8List.fromList(List<int>.from(imageBinary));
        } catch (e) {
          print('Error converting image binary: $e');
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.richGold,
          backgroundImage: imageBytes != null ? MemoryImage(imageBytes) : null,
          child: imageBytes == null
              ? Icon(Icons.person, color: AppColors.deepBlack, size: 30)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: AppColors.richGold,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isAvailable ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Blocked',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.motorcycle, color: Colors.grey, size: 16),
                SizedBox(width: 6),
                Text(
                  '$vehicleType - $vehicleNumber',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, color: Colors.grey, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.richGold),
          color: AppColors.cardBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
          ),
          onSelected: (value) {
            if (value == 'view') {
              _viewRiderDetails(
                  riderId, name, email, vehicleType, vehicleNumber, phone, isAvailable);
            } else if (value == 'delete') {
              _deleteRider(riderId, name);
            } else if (value == 'toggle') {
              _toggleAvailability(riderId, isAvailable);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, color: AppColors.richGold, size: 20),
                  SizedBox(width: 12),
                  Text('View Details', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    isAvailable ? Icons.block : Icons.check_circle,
                    color: AppColors.richGold,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    isAvailable ? 'Block' : 'Mark Available',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewRiderDetails(String riderId, String name, String email,
      String vehicleType, String vehicleNumber, String phone, bool isAvailable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.richGold),
        ),
        title: Text(
          'Rider Details',
          style: TextStyle(color: AppColors.richGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name:', name),
            _detailRow('Email:', email),
            _detailRow('Phone:', phone),
            _detailRow('Vehicle:', '$vehicleType - $vehicleNumber'),
            _detailRow(
                'Status:', isAvailable ? 'Available' : 'Blocked',
                valueColor: isAvailable ? Colors.green : Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppColors.richGold)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAvailability(String riderId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(riderId)
          .update({'isAvailable': !currentStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus ? 'Rider is now Available' : 'Rider has been Blocked',
          ),
          backgroundColor: AppColors.richGold,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteRider(String riderId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red),
        ),
        title: Text(
          'Delete Rider',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          'Are you sure you want to delete $name?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(riderId)
                    .delete();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rider deleted successfully'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
