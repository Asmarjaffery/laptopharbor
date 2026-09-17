import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';

class AddBrandScreen extends StatefulWidget {
  const AddBrandScreen({super.key});

  @override
  State<AddBrandScreen> createState() => _AddBrandScreenState();
}

class _AddBrandScreenState extends State<AddBrandScreen> {
  final TextEditingController nameController = TextEditingController();
  bool isActive = true;
  bool isLoading = false;
  
  // ✅ Image handling
  Uint8List? _imageBytes;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();

  // ✅ Pick Image
  Future<void> _pickImage() async {
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
        
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _imageBase64 = base64String;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to pick image: $e"),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    }
  }

  // ✅ Remove Image
  void _removeImage() {
    if (mounted) {
      setState(() {
        _imageBytes = null;
        _imageBase64 = null;
      });
    }
  }

  Future<void> addBrand() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Brand name is required"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    // ✅ Image is optional but recommended
    if (_imageBase64 == null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBlack,
          title: Text(
            'No Logo Selected',
            style: TextStyle(color: AppColors.lightGold),
          ),
          content: Text(
            'Do you want to add brand without a logo?',
            style: TextStyle(color: AppColors.softGold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Continue', style: TextStyle(color: AppColors.richGold)),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final brandData = {
        'name': nameController.text.trim(),
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // ✅ Add image if selected
      if (_imageBase64 != null) {
        brandData['logoBase64'] = _imageBase64 as Object;
      }

      await FirebaseFirestore.instance.collection('brands').add(brandData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Brand Added Successfully"),
            backgroundColor: AppColors.richGold,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add brand: $e"),
            backgroundColor: Colors.red[900],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Add New Brand'),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ===== Premium Header =====
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold, AppColors.richGold],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.branding_watermark, 
                        size: 40, color: AppColors.deepBlack),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Add Brand',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightGold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: AppColors.richGold.withOpacity(0.5),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'CREATE BRAND',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.richGold.withOpacity(0.7),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                  // ===== End of Header =====

                  // ✅ Brand Logo Upload Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.deepBlack.withOpacity(0.6),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Image Preview or Upload Button
                        _imageBytes != null
                            ? Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    height: 150,
                                    width: 150,
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
                                        _imageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  // Remove button
                                  Positioned(
                                    top: -8,
                                    right: -8,
                                    child: IconButton(
                                      onPressed: _removeImage,
                                      icon: Container(
                                        padding: EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 150,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: AppColors.deepBlack.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.richGold.withOpacity(0.5),
                                      width: 2,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppColors.richGold.withOpacity(0.7),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Upload Logo',
                                        style: TextStyle(
                                          color: AppColors.softGold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        '(Optional)',
                                        style: TextStyle(
                                          color: AppColors.softGold.withOpacity(0.6),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        
                        if (_imageBytes != null) ...[
                          SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.refresh, color: AppColors.richGold, size: 18),
                            label: Text(
                              'Change Logo',
                              style: TextStyle(color: AppColors.richGold, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Brand Name Field
                  buildField(
                    controller: nameController,
                    label: "Brand Name",
                    icon: Icons.business_outlined,
                  ),
                  SizedBox(height: 20),

                  // Active Status Toggle
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.deepBlack.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.richGold.withOpacity(0.3),
                      ),
                    ),
                    child: SwitchListTile(
                      value: isActive,
                      activeColor: AppColors.richGold,
                      title: Text(
                        "Active Status",
                        style: TextStyle(
                          color: AppColors.lightGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        isActive ? "Brand is active" : "Brand is inactive",
                        style: TextStyle(
                          color: AppColors.richGold.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      onChanged: (val) {
                        if (mounted) {
                          setState(() => isActive = val);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 24),

                  // Add Brand Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold, AppColors.richGold],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.4),
                          blurRadius: 20,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : addBrand,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.deepBlack,
                            )
                          : Text(
                              "Add Brand",
                              style: TextStyle(
                                color: AppColors.deepBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: AppColors.richGold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.lightGold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.richGold.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppColors.richGold),
        filled: true,
        fillColor: AppColors.deepBlack.withOpacity(0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.richGold, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}