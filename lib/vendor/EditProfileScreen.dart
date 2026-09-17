import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/colors.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> vendorData;
  const EditProfileScreen({Key? key, required this.vendorData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _shopNameController;
  late TextEditingController _shopAddressController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool isLoading = false;

  // Password strength
  double _passwordStrength = 0;
  String _strengthText = "Weak";

  // Image
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.vendorData['name'] ?? '');
    _emailController = TextEditingController(text: widget.vendorData['email'] ?? '');
    _phoneController = TextEditingController(text: widget.vendorData['phone'] ?? '');
    _shopNameController = TextEditingController(text: widget.vendorData['shopName'] ?? '');
    _shopAddressController = TextEditingController(text: widget.vendorData['shopAddress'] ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Load image
    var imgData = widget.vendorData['imageBinary'];
    if (imgData != null) {
      if (imgData is Uint8List) {
        _imageBytes = imgData;
      } else if (imgData is List) {
        _imageBytes = Uint8List.fromList(imgData.cast<int>());
      } else if (imgData is String) {
        _imageBytes = Uint8List.fromList(imgData.codeUnits);
      }
    }
  }

  void _checkPasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 6) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
      if (strength <= 0.25) _strengthText = "Weak";
      else if (strength <= 0.75) _strengthText = "Medium";
      else _strengthText = "Strong";
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
          setState(() => _imageBytes = result.files.single.bytes);
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          File file = File(result.files.single.path!);
          Uint8List bytes = await file.readAsBytes();
          setState(() => _imageBytes = bytes);
        }
      }
    } catch (e) {
      print("Image pick error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot pick image on this platform")),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red[900]),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        // Update Firestore
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'shopName': _shopNameController.text.trim(),
          'shopAddress': _shopAddressController.text.trim(),
          'imageBinary': _imageBytes,
        };

        await FirebaseFirestore.instance.collection('users').doc(userId).update(updateData);

        // Update password if provided
        if (_passwordController.text.isNotEmpty) {
          await FirebaseAuth.instance.currentUser?.updatePassword(_passwordController.text.trim());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!"), backgroundColor: AppColors.richGold),
        );

        Navigator.pop(context, true); // Return true to dashboard
      }
    } catch (e) {
      print("Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_imageBytes != null) {
      return CircleAvatar(radius: 50, backgroundImage: MemoryImage(_imageBytes!));
    } else {
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[800],
        child: Icon(Icons.person, size: 50, color: AppColors.deepBlack),
      );
    }
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: AppColors.deepBlack,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.richGold))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(onTap: pickImage, child: _buildImagePreview()),
                    SizedBox(height: 8),
                    Text("Tap to change profile image",
                        style: TextStyle(color: AppColors.richGold.withOpacity(0.7), fontSize: 12)),
                    SizedBox(height: 24),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: AppColors.lightGold),
                      decoration: inputDecoration("Name", Icons.person_outline),
                      validator: (val) => val!.isEmpty ? "Enter name" : null,
                    ),
                    SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: AppColors.lightGold),
                      decoration: inputDecoration("Email", Icons.email_outlined),
                      validator: (val) {
                        if (val!.isEmpty) return "Enter email";
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return "Enter valid email";
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      style: TextStyle(color: AppColors.lightGold),
                      decoration: inputDecoration("Phone", Icons.phone_outlined),
                    ),
                    SizedBox(height: 16),

                    // Shop Name
                    TextFormField(
                      controller: _shopNameController,
                      style: TextStyle(color: AppColors.lightGold),
                      decoration: inputDecoration("Shop Name", Icons.store_outlined),
                    ),
                    SizedBox(height: 16),

                    // Shop Address
                    TextFormField(
                      controller: _shopAddressController,
                      style: TextStyle(color: AppColors.lightGold),
                      decoration: inputDecoration("Shop Address", Icons.location_on_outlined),
                    ),
                    SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
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
                          onPressed: () => setState(() => _showPassword = !_showPassword),
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
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Strength: $_strengthText",
                            style: TextStyle(
                                color: _passwordStrength <= 0.25
                                    ? Colors.red
                                    : _passwordStrength <= 0.75
                                        ? Colors.orange
                                        : AppColors.richGold,
                                fontSize: 12))),
                    SizedBox(height: 16),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: TextStyle(color: AppColors.lightGold),
                      decoration: inputDecoration(
                        "Confirm Password",
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.richGold,
                          ),
                          onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Save Changes", style: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
