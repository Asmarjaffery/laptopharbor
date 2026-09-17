import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/colors.dart';
import '../routes/app_routes.dart';

class AddVendorScreen extends StatefulWidget {
  const AddVendorScreen({super.key});

  @override
  State<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopAddressController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Password strength
  double _passwordStrength = 0;
  String _strengthText = "Weak";

  // Image storage
  Uint8List? _binaryImage;

  void _checkPasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 6) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.25) {
        _strengthText = "Weak";
      } else if (strength <= 0.75) {
        _strengthText = "Medium";
      } else {
        _strengthText = "Strong";
      }
    });
  }

  Future<void> pickImage() async {
    try {
      if (kIsWeb) {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.single.bytes != null) {
          setState(() {
            _binaryImage = result.files.single.bytes;
          });
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          File file = File(result.files.single.path!);
          Uint8List bytes = await file.readAsBytes();
          setState(() {
            _binaryImage = bytes;
          });
        }
      }
    } catch (e) {
      print("Image pick error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot pick image on this platform")),
      );
    }
  }

  Future<void> addVendor() async {
    // Validation
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        shopNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: AppColors.richGold,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    if (_binaryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a profile image"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('👤 [AddVendor] Starting vendor creation...');

      // Create secondary Firebase app to prevent admin logout
      FirebaseApp? secondaryApp;
      
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      
      final vendorCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final vendorUid = vendorCredential.user!.uid;
      print('✅ [AddVendor] Vendor created with UID: $vendorUid');

      await FirebaseFirestore.instance.collection('users').doc(vendorUid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'shopName': shopNameController.text.trim(),
        'shopAddress': shopAddressController.text.trim(),
        'role': 'vendor',
        'isApproved': true,
        'createdAt': FieldValue.serverTimestamp(),
        'imageBinary': _binaryImage,
      });

      print('✅ [AddVendor] Vendor data saved to Firestore');

      // Sign out from secondary app
      await secondaryAuth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Vendor created successfully'),
          backgroundColor: AppColors.richGold,
        ),
      );

      // Clear form
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      shopNameController.clear();
      shopAddressController.clear();
      setState(() {
        _binaryImage = null;
        _passwordStrength = 0;
        _strengthText = "Weak";
      });

    } catch (e) {
      print('❌ [AddVendor] Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[900],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_binaryImage != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: MemoryImage(_binaryImage!),
      );
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[800],
        child: Icon(Icons.store, size: 40, color: AppColors.deepBlack),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Add New Vendor'),
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
                    child: Icon(Icons.store, size: 40, color: AppColors.deepBlack),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Add Vendor',
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
                    'CREATE VENDOR ACCOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.richGold.withOpacity(0.7),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                  // ===== End of Header =====

                  GestureDetector(
                    onTap: pickImage,
                    child: _buildImagePreview(),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tap to select vendor photo",
                    style: TextStyle(
                      color: AppColors.richGold.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 24),

                  // Personal Information
                  buildField(
                    controller: nameController,
                    label: "Vendor Name",
                    icon: Icons.person_outline,
                  ),
                  SizedBox(height: 16),
                  buildField(
                    controller: emailController,
                    label: "Email Address",
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16),
                  buildField(
                    controller: phoneController,
                    label: "Phone Number",
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  SizedBox(height: 16),

                  // Shop Information
                  buildField(
                    controller: shopNameController,
                    label: "Shop Name",
                    icon: Icons.store_outlined,
                  ),
                  SizedBox(height: 16),
                  buildField(
                    controller: shopAddressController,
                    label: "Shop Address (Optional)",
                    icon: Icons.location_on_outlined,
                  ),
                  SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passwordController,
                    obscureText: !_showPassword,
                    onChanged: _checkPasswordStrength,
                    style: TextStyle(color: AppColors.lightGold),
                    decoration: inputDecoration(
                      "Password",
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.richGold,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _passwordStrength <= 0.25
                          ? Colors.red
                          : _passwordStrength <= 0.75
                              ? Colors.orange
                              : AppColors.richGold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Strength: $_strengthText",
                      style: TextStyle(
                        color: _passwordStrength <= 0.25
                            ? Colors.red
                            : _passwordStrength <= 0.75
                                ? Colors.orange
                                : AppColors.richGold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    style: TextStyle(color: AppColors.lightGold),
                    decoration: inputDecoration(
                      "Confirm Password",
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.richGold,
                        ),
                        onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Add Vendor Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.lightGold, AppColors.richGold],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : addVendor,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: AppColors.deepBlack,
                            )
                          : Text(
                              "Add Vendor",
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
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: TextStyle(color: AppColors.lightGold),
      decoration: inputDecoration(label, icon),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.richGold.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: AppColors.richGold),
      suffixIcon: suffix,
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
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    shopNameController.dispose();
    shopAddressController.dispose();
    super.dispose();
  }
}