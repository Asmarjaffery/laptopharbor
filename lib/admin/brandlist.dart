import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class ViewBrandsScreen extends StatefulWidget {
  const ViewBrandsScreen({super.key});

  @override
  State<ViewBrandsScreen> createState() => _ViewBrandsScreenState();
}

class _ViewBrandsScreenState extends State<ViewBrandsScreen> {
  final CollectionReference brandsRef =
      FirebaseFirestore.instance.collection('brands');
  final ImagePicker _picker = ImagePicker();

  Future<void> deleteBrand(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Delete Brand', style: TextStyle(color: AppColors.lightGold)),
        content: Text(
          'Are you sure you want to delete this brand?',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await brandsRef.doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Brand deleted successfully"),
              backgroundColor: AppColors.richGold,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to delete brand"),
              backgroundColor: Colors.red[900],
            ),
          );
        }
      }
    }
  }

  Future<void> editBrand(String docId, String currentName, bool currentStatus, String? currentLogo) async {
    final TextEditingController nameController = TextEditingController(text: currentName);
    bool isActive = currentStatus;
    Uint8List? newImageBytes;
    String? newImageBase64 = currentLogo;

    Future<void> pickImage(StateSetter setDialogState) async {
      try {
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          final base64String = base64Encode(bytes);
          
          setDialogState(() {
            newImageBytes = bytes;
            newImageBase64 = base64String;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to pick image"),
              backgroundColor: Colors.red[900],
            ),
          );
        }
      }
    }

    void removeImage(StateSetter setDialogState) {
      setDialogState(() {
        newImageBytes = null;
        newImageBase64 = null;
      });
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBlack,
          title: Text('Edit Brand', style: TextStyle(color: AppColors.lightGold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Section
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.richGold.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Brand Logo',
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 12),
                      
                      // Image Display
                      if (newImageBytes != null || newImageBase64 != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.richGold,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  newImageBytes ?? base64Decode(newImageBase64!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: IconButton(
                                onPressed: () => removeImage(setDialogState),
                                icon: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        GestureDetector(
                          onTap: () => pickImage(setDialogState),
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.deepBlack.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: AppColors.richGold.withOpacity(0.7),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Add Logo',
                                  style: TextStyle(
                                    color: AppColors.softGold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      if (newImageBytes != null || newImageBase64 != null) ...[
                        SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () => pickImage(setDialogState),
                          icon: Icon(Icons.refresh, color: AppColors.richGold, size: 16),
                          label: Text(
                            'Change Logo',
                            style: TextStyle(color: AppColors.richGold, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Name Field
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppColors.lightGold),
                  decoration: InputDecoration(
                    labelText: "Brand Name",
                    labelStyle: TextStyle(color: AppColors.richGold),
                    filled: true,
                    fillColor: AppColors.deepBlack.withOpacity(0.6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.richGold, width: 2),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                
                // Active Status
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.deepBlack.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.richGold.withOpacity(0.3),
                    ),
                  ),
                  child: SwitchListTile(
                    title: Text('Active Status', style: TextStyle(color: AppColors.lightGold, fontSize: 14)),
                    value: isActive,
                    onChanged: (val) {
                      setDialogState(() {
                        isActive = val;
                      });
                    },
                    activeColor: AppColors.richGold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.richGold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.richGold),
              onPressed: () async {
                try {
                  final updateData = {
                    'name': nameController.text.trim(),
                    'isActive': isActive,
                  };
                  
                  // Add or remove logo
                  if (newImageBase64 != null) {
                    updateData['logoBase64'] = newImageBase64 as Object;
                  } else {
                    updateData['logoBase64'] = FieldValue.delete();
                  }
                  
                  await brandsRef.doc(docId).update(updateData);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Brand updated successfully"),
                        backgroundColor: AppColors.richGold,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to update brand"),
                        backgroundColor: Colors.red[900],
                      ),
                    );
                  }
                }
              },
              child: Text('Save', style: TextStyle(color: AppColors.deepBlack)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Brand Management', style: TextStyle(color: AppColors.lightGold)),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Add New Brand Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addBrand);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.richGold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.deepBlack, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Add New Brand',
                      style: TextStyle(
                        color: AppColors.deepBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Brands List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: brandsRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: AppColors.richGold),
                  );
                }

                final brands = snapshot.data!.docs;

                if (brands.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 80,
                          color: AppColors.richGold.withOpacity(0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No brands added yet",
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    final brandData = brand.data() as Map<String, dynamic>;
                    final isActive = brandData['isActive'] ?? true;
                    final logoBase64 = brandData['logoBase64'] as String?;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBlack,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Brand Logo/Icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.deepBlack,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.richGold.withOpacity(0.3),
                              ),
                            ),
                            child: logoBase64 != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      base64Decode(logoBase64),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.business,
                                    color: AppColors.richGold,
                                    size: 28,
                                  ),
                          ),
                          SizedBox(width: 16),

                          // Brand Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  brandData['name'] ?? 'Unnamed',
                                  style: TextStyle(
                                    color: AppColors.lightGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isActive ? Icons.check_circle : Icons.cancel,
                                      color: isActive
                                          ? AppColors.richGold
                                          : Colors.redAccent,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: AppColors.softGold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // More Options Menu
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: AppColors.lightGold,
                            ),
                            color: AppColors.cardBlack,
                            onSelected: (value) {
                              if (value == 'edit') {
                                editBrand(
                                  brand.id,
                                  brandData['name'] ?? '',
                                  isActive,
                                  logoBase64,
                                );
                              } else if (value == 'delete') {
                                deleteBrand(brand.id);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: AppColors.lightGold, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Edit',
                                      style: TextStyle(color: AppColors.lightGold),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.redAccent),
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}