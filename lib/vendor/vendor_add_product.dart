import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobileapp/widgets/helpers/customer_notification_helper.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../constants/colors.dart';


class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    required Map<dynamic, dynamic> existingData,
    required String productId,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Hardware Specifications
  final TextEditingController processorController = TextEditingController();
  final TextEditingController ramController = TextEditingController();
  final TextEditingController storageController = TextEditingController();
  final TextEditingController graphicsController = TextEditingController();

  // Display Specifications
  final TextEditingController displaySizeController = TextEditingController();
  final TextEditingController resolutionController = TextEditingController();
  final TextEditingController refreshRateController = TextEditingController();
  final TextEditingController displayTypeController = TextEditingController();

  // Battery & Physical
  final TextEditingController batteryController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController dimensionsController = TextEditingController();

  // Connectivity & Ports
  final TextEditingController portsController = TextEditingController();
  final TextEditingController connectivityController = TextEditingController();

  // Software & Warranty
  final TextEditingController osController = TextEditingController();
  final TextEditingController warrantyController = TextEditingController();

  // Additional Features
  final TextEditingController webcamController = TextEditingController();
  final TextEditingController keyboardController = TextEditingController();
  final TextEditingController audioController = TextEditingController();

  // Image
  dynamic selectedImage;
  String? imageBase64;
  final ImagePicker _picker = ImagePicker();

  // Dropdowns
  String? selectedCategory;
  String? selectedBrand;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> brands = [];

  bool isLoading = false;
  bool isLoadingData = true;

  @override
  void initState() {
    super.initState();
    loadCategoriesAndBrands();
  }

  Future<void> loadCategoriesAndBrands() async {
    try {
      final categorySnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();
      final brandSnapshot = await FirebaseFirestore.instance
          .collection('brands')
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        categories = categorySnapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['name']})
            .toList();
        brands = brandSnapshot.docs
            .map((doc) => {'id': doc.id, 'name': doc['name']})
            .toList();
        isLoadingData = false;
      });
    } catch (e) {
      setState(() => isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load categories or brands"),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 500000) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Image too large. Max 500KB allowed"),
              backgroundColor: Colors.red[900],
            ),
          );
          return;
        }

        setState(() {
          selectedImage = kIsWeb ? bytes : File(image.path);
          imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $e"),
          backgroundColor: Colors.red[900],
        ),
      );
    }
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategory == null || selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select category and brand"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    if (imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a product image"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final vendorDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (!vendorDoc.exists) {
        throw Exception("Vendor profile not found");
      }

      final vendorData = vendorDoc.data();
      String vendorName = vendorData?['shopName'] ?? 
                         vendorData?['name'] ?? 
                         'Unknown Vendor';

      final specifications = {
        'description': descriptionController.text.trim(),
        // Hardware
        'processor': processorController.text.trim(),
        'ram': ramController.text.trim(),
        'storage': storageController.text.trim(),
        'graphics': graphicsController.text.trim(),
        // Display
        'displaySize': displaySizeController.text.trim(),
        'resolution': resolutionController.text.trim(),
        'refreshRate': refreshRateController.text.trim(),
        'displayType': displayTypeController.text.trim(),
        // Battery & Physical
        'battery': batteryController.text.trim(),
        'weight': weightController.text.trim(),
        'dimensions': dimensionsController.text.trim(),
        // Connectivity
        'ports': portsController.text.trim(),
        'connectivity': connectivityController.text.trim(),
        // Software & Warranty
        'os': osController.text.trim(),
        'warranty': warrantyController.text.trim(),
        // Additional
        'webcam': webcamController.text.trim(),
        'keyboard': keyboardController.text.trim(),
        'audio': audioController.text.trim(),
      };

      final productData = {
        'name': nameController.text.trim(),
        'price': double.parse(priceController.text.trim()),
        'quantity': int.parse(quantityController.text.trim()),
        'categoryId': selectedCategory,
        'brandId': selectedBrand,
        'specifications': specifications,
        'vendorId': user.uid,
        'vendorName': vendorName, 
        'imageBase64': imageBase64,
        'isActive': true,
        'isApproved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add product to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('products')
          .add(productData);

      String productId = docRef.id;
      String productName = nameController.text.trim();

      print('Product added with ID: $productId');

      // 🆕 OPTIONAL: Notify customers about new product
      // You can choose to notify all customers or specific ones
      // For now, we'll notify all customers - you can modify this logic
      try {
        print('Fetching customers to notify...');
        final customers = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'customer')
            .limit(100) // Limit to prevent overwhelming notifications
            .get();

        print('Found ${customers.docs.length} customers');

        // Send notification to each customer
        for (var customer in customers.docs) {
          await CustomerNotificationHelper.sendNewProductNotification(
            customerId: customer.id,
            productName: productName,
            productId: productId,
          );
        }

        print('Notifications sent to all customers');
      } catch (notifError) {
        // Don't fail the whole operation if notification fails
        print('Error sending notifications: $notifError');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product submitted for admin approval & customers notified"),
          backgroundColor: AppColors.richGold,
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true); // Return true to refresh dashboard
    } catch (e) {
      print('Error saving product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save product: $e"),
          backgroundColor: Colors.red[900],
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (selectedImage != null) {
      return kIsWeb
          ? Image.memory(selectedImage as Uint8List, fit: BoxFit.cover, width: double.infinity)
          : Image.file(selectedImage as File, fit: BoxFit.cover, width: double.infinity);
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingData) {
      return Scaffold(
        backgroundColor: AppColors.deepBlack,
        appBar: AppBar(
          title: Text('Add Product', style: TextStyle(color: AppColors.lightGold)),
          backgroundColor: AppColors.deepBlack,
          iconTheme: IconThemeData(color: AppColors.lightGold),
        ),
        body: Center(child: CircularProgressIndicator(color: AppColors.richGold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Add New Laptop', style: TextStyle(color: AppColors.lightGold)),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.lightGold),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Image Card
                _buildCard(
                  title: 'Product Image',
                  icon: Icons.image,
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.deepBlack.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
                        ),
                        child: (selectedImage != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildImagePreview(),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 64, color: AppColors.richGold.withOpacity(0.5)),
                                  SizedBox(height: 12),
                                  Text('Tap to select image', style: TextStyle(color: AppColors.softGold)),
                                  SizedBox(height: 4),
                                  Text('(Max 500KB)', style: TextStyle(color: AppColors.softGold.withOpacity(0.6))),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Basic Info Card
                _buildCard(
                  title: 'Basic Information',
                  icon: Icons.info_outline,
                  children: [
                    _buildTextField(
                        controller: nameController,
                        label: 'Product Name',
                        icon: Icons.laptop,
                        hint: 'e.g., Dell XPS 15',
                        validator: (val) => val!.isEmpty ? 'Required' : null),
                    SizedBox(height: 16),
                    _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        icon: Icons.description_outlined,
                        hint: 'High-performance laptop for professionals...',
                        maxLines: 3,
                        validator: (val) => val!.isEmpty ? 'Required' : null),
                  ],
                ),
                SizedBox(height: 16),

                // Category & Brand Card
                _buildCard(
                  title: 'Category & Brand',
                  icon: Icons.category,
                  children: [
                    _buildDropdown(
                      value: selectedCategory,
                      items: categories,
                      label: 'Select Category',
                      icon: Icons.category_outlined,
                      onChanged: (val) => setState(() => selectedCategory = val),
                    ),
                    SizedBox(height: 16),
                    _buildDropdown(
                      value: selectedBrand,
                      items: brands,
                      label: 'Select Brand',
                      icon: Icons.business_outlined,
                      onChanged: (val) => setState(() => selectedBrand = val),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Pricing & Stock Card
                _buildCard(
                  title: 'Pricing & Stock',
                  icon: Icons.attach_money,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: priceController,
                            label: 'Price (USD)',
                            icon: Icons.monetization_on_outlined,
                            hint: 'e.g., 999.99',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val!.isEmpty) return 'Required';
                              if (double.tryParse(val) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: quantityController,
                            label: 'Stock Quantity',
                            icon: Icons.inventory_outlined,
                            hint: 'e.g., 50',
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val!.isEmpty) return 'Required';
                              if (int.tryParse(val) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // HARDWARE SPECIFICATIONS
                _buildCard(
                  title: 'Hardware Specifications',
                  icon: Icons.memory,
                  children: [
                    _buildTextField(
                      controller: processorController,
                      label: 'Processor',
                      icon: Icons.speed,
                      hint: 'e.g., Intel Core i7-12700H',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: ramController,
                            label: 'RAM',
                            icon: Icons.developer_board,
                            hint: 'e.g., 16GB DDR5',
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: storageController,
                            label: 'Storage',
                            icon: Icons.storage,
                            hint: 'e.g., 512GB SSD',
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: graphicsController,
                      label: 'Graphics Card',
                      icon: Icons.videogame_asset,
                      hint: 'e.g., NVIDIA GeForce RTX 3060',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // DISPLAY SPECIFICATIONS
                _buildCard(
                  title: 'Display Specifications',
                  icon: Icons.monitor,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: displaySizeController,
                            label: 'Screen Size',
                            icon: Icons.screenshot,
                            hint: 'e.g., 15.6 inch',
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: resolutionController,
                            label: 'Resolution',
                            icon: Icons.high_quality,
                            hint: 'e.g., 1920x1080 FHD',
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: refreshRateController,
                            label: 'Refresh Rate',
                            icon: Icons.refresh,
                            hint: 'e.g., 144Hz',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: displayTypeController,
                            label: 'Display Type',
                            icon: Icons.screen_share,
                            hint: 'e.g., IPS, Anti-Glare',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // BATTERY & PHYSICAL
                _buildCard(
                  title: 'Battery & Physical Specs',
                  icon: Icons.battery_charging_full,
                  children: [
                    _buildTextField(
                      controller: batteryController,
                      label: 'Battery',
                      icon: Icons.battery_std,
                      hint: 'e.g., 56Wh, up to 8 hours',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: weightController,
                            label: 'Weight',
                            icon: Icons.line_weight,
                            hint: 'e.g., 2.1 kg',
                            validator: (val) => val!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: dimensionsController,
                            label: 'Dimensions',
                            icon: Icons.straighten,
                            hint: 'e.g., 35.8 x 23.5 x 1.8 cm',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // CONNECTIVITY & PORTS
                _buildCard(
                  title: 'Connectivity & Ports',
                  icon: Icons.cable,
                  children: [
                    _buildTextField(
                      controller: portsController,
                      label: 'Ports',
                      icon: Icons.usb,
                      hint: 'e.g., 3x USB-A, 1x USB-C, HDMI',
                      maxLines: 2,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: connectivityController,
                      label: 'Connectivity',
                      icon: Icons.wifi,
                      hint: 'e.g., Wi-Fi 6, Bluetooth 5.2',
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // SOFTWARE & WARRANTY
                _buildCard(
                  title: 'Software & Warranty',
                  icon: Icons.verified_user,
                  children: [
                    _buildTextField(
                      controller: osController,
                      label: 'Operating System',
                      icon: Icons.computer,
                      hint: 'e.g., Windows 11 Pro',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: warrantyController,
                      label: 'Warranty',
                      icon: Icons.shield,
                      hint: 'e.g., 1 Year International',
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // ADDITIONAL FEATURES
                _buildCard(
                  title: 'Additional Features',
                  icon: Icons.star,
                  children: [
                    _buildTextField(
                      controller: webcamController,
                      label: 'Webcam',
                      icon: Icons.camera_alt,
                      hint: 'e.g., HD 720p Webcam',
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: keyboardController,
                      label: 'Keyboard',
                      icon: Icons.keyboard,
                      hint: 'e.g., RGB Backlit Keyboard',
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      controller: audioController,
                      label: 'Audio',
                      icon: Icons.volume_up,
                      hint: 'e.g., Dual Speakers with Dolby',
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : saveProduct,
                  child: isLoading
                      ? CircularProgressIndicator(color: AppColors.deepBlack)
                      : Text(
                          "Submit for Approval",
                          style: TextStyle(
                            color: AppColors.deepBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: Size(double.infinity, 54),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Product will be visible after admin approval',
                  style: TextStyle(color: AppColors.softGold.withOpacity(0.8), fontSize: 12),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---
  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.richGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.richGold, size: 22),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.lightGold),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.softGold),
        hintStyle: TextStyle(color: AppColors.softGold.withOpacity(0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
        filled: true,
        fillColor: AppColors.deepBlack.withOpacity(0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.softGold),
          prefixIcon: Icon(icon, color: AppColors.richGold, size: 20),
          border: InputBorder.none,
        ),
        items: items
            .map((e) => DropdownMenuItem<String>(
                  value: e['id'],
                  child: Text(e['name'], style: TextStyle(color: AppColors.lightGold)),
                ))
            .toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Required' : null,
        dropdownColor: AppColors.cardBlack,
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    descriptionController.dispose();
    processorController.dispose();
    ramController.dispose();
    storageController.dispose();
    graphicsController.dispose();
    displaySizeController.dispose();
    resolutionController.dispose();
    refreshRateController.dispose();
    displayTypeController.dispose();
    batteryController.dispose();
    weightController.dispose();
    dimensionsController.dispose();
    portsController.dispose();
    connectivityController.dispose();
    osController.dispose();
    warrantyController.dispose();
    webcamController.dispose();
    keyboardController.dispose();
    audioController.dispose();
    super.dispose();
  }
}