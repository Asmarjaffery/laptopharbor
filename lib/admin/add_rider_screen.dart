import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../routes/app_routes.dart';

class AddRiderScreen extends StatefulWidget {
  const AddRiderScreen({super.key});

  @override
  State<AddRiderScreen> createState() => _AddRiderScreenState();
}

class _AddRiderScreenState extends State<AddRiderScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final vehicleNumberController = TextEditingController();
  final licenseNumberController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  String _selectedVehicleType = 'Bike';
  final _vehicleTypes = ['Bike', 'Car', 'Scooter'];

  Uint8List? _binaryImage;

  // Validation states
  String? _passwordStrength;
  bool _isPasswordValid = false;
  bool _isEmailValid = false;
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    _validateAdmin();
  }

  void _validateAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final adminEmail = prefs.getString('adminEmail');
    
    if (adminEmail != 'admin@laptopharbor.com') {
      Future.microtask(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unauthorized access'),
            backgroundColor: Colors.red[900],
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (_) => false);
      });
    }
  }

  // Email validation
  void _validateEmail(String value) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _isEmailValid = emailRegex.hasMatch(value);
    });
  }

  // Phone validation (Pakistan format)
  void _validatePhone(String value) {
    final phoneRegex = RegExp(r'^(\+92|0)?[0-9]{10}$');
    setState(() {
      _isPhoneValid = phoneRegex.hasMatch(value.replaceAll(' ', ''));
    });
  }

  // Password strength validation
  void _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = null;
        _isPasswordValid = false;
      });
      return;
    }

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;

    int strength = 0;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialChar) strength++;
    if (hasMinLength) strength++;

    setState(() {
      if (strength < 3) {
        _passwordStrength = 'Weak';
        _isPasswordValid = false;
      } else if (strength < 5) {
        _passwordStrength = 'Medium';
        _isPasswordValid = true;
      } else {
        _passwordStrength = 'Strong';
        _isPasswordValid = true;
      }
    });
  }

  Future<void> pickImage() async {
    try {
      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
        if (result != null) {
          _binaryImage = result.files.single.bytes;
          setState(() {});
        }
      } else {
        final result =
            await FilePicker.platform.pickFiles(type: FileType.image);
        if (result != null) {
          final file = File(result.files.single.path!);
          _binaryImage = await file.readAsBytes();
          setState(() {});
        }
      }
    } catch (_) {}
  }

  Future<void> addRider() async {
    // Validation
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        vehicleNumberController.text.trim().isEmpty ||
        licenseNumberController.text.trim().isEmpty ||
        _binaryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields and upload image'),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    if (!_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    if (!_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least Medium strength'),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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
      
      final riderCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final riderUid = riderCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(riderUid).set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'vehicleType': _selectedVehicleType,
        'vehicleNumber': vehicleNumberController.text.trim(),
        'licenseNumber': licenseNumberController.text.trim(),
        'role': 'rider',
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'imageBinary': _binaryImage,
      });

      // Sign out from secondary app
      await secondaryAuth.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Rider created successfully'),
          backgroundColor: AppColors.richGold,
        ),
      );

      // Clear form
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      vehicleNumberController.clear();
      licenseNumberController.clear();
      setState(() {
        _binaryImage = null;
        _selectedVehicleType = 'Bike';
        _passwordStrength = null;
        _isPasswordValid = false;
        _isEmailValid = false;
        _isPhoneValid = false;
      });

    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        title: Text('Add New Rider', style: TextStyle(color: AppColors.richGold)),
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.richGold),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            margin: EdgeInsets.all(20),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBlack,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.richGold.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppColors.richGold),
                        SizedBox(height: 16),
                        Text(
                          'Creating rider account...',
                          style: TextStyle(color: AppColors.richGold),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Header
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.richGold,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.motorcycle,
                            size: 40,
                            color: AppColors.deepBlack,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Title
                      Center(
                        child: Text(
                          'Add Rider',
                          style: TextStyle(
                            color: AppColors.richGold,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'CREATE RIDER ACCOUNT',
                          style: TextStyle(
                            color: AppColors.richGold.withOpacity(0.6),
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Image Picker
                      GestureDetector(
                        onTap: pickImage,
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: AppColors.charcoalGray,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.richGold,
                                width: 2,
                              ),
                            ),
                            child: _binaryImage != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _binaryImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.motorcycle,
                                    size: 50,
                                    color: AppColors.richGold.withOpacity(0.5),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Tap to select rider photo',
                          style: TextStyle(
                            color: AppColors.richGold.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Name Field
                      _buildTextField(
                        controller: nameController,
                        label: 'Rider Name',
                        icon: Icons.person_outline,
                      ),
                      SizedBox(height: 16),

                      // Email Field with validation
                      _buildTextField(
                        controller: emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: _validateEmail,
                        showValidation: emailController.text.isNotEmpty,
                        isValid: _isEmailValid,
                      ),
                      SizedBox(height: 16),

                      // Phone Field with validation
                      _buildTextField(
                        controller: phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        onChanged: _validatePhone,
                        showValidation: phoneController.text.isNotEmpty,
                        isValid: _isPhoneValid,
                      ),
                      SizedBox(height: 16),

                      // Vehicle Type Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.deepBlack.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.richGold.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedVehicleType,
                          dropdownColor: AppColors.charcoalGray,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.two_wheeler_outlined,
                              color: AppColors.richGold,
                            ),
                            labelText: 'Vehicle Type',
                            labelStyle: TextStyle(
                              color: AppColors.richGold.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: _vehicleTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedVehicleType = value);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 16),

                      // Vehicle Number Field
                      _buildTextField(
                        controller: vehicleNumberController,
                        label: 'Vehicle Number',
                        icon: Icons.pin_outlined,
                      ),
                      SizedBox(height: 16),

                      // License Number Field
                      _buildTextField(
                        controller: licenseNumberController,
                        label: 'License Number',
                        icon: Icons.badge_outlined,
                      ),
                      SizedBox(height: 16),

                      // Password Field with strength indicator
                      _buildTextField(
                        controller: passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        showPassword: _showPassword,
                        onTogglePassword: () =>
                            setState(() => _showPassword = !_showPassword),
                        onChanged: _validatePassword,
                      ),
                      if (_passwordStrength != null) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Strength: ',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            Text(
                              _passwordStrength!,
                              style: TextStyle(
                                color: _passwordStrength == 'Weak'
                                    ? Colors.red
                                    : _passwordStrength == 'Medium'
                                        ? Colors.orange
                                        : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 16),

                      // Confirm Password Field
                      _buildTextField(
                        controller: confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        showPassword: _showConfirmPassword,
                        onTogglePassword: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword),
                      ),
                      SizedBox(height: 24),

                      // Add Rider Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : addRider,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.richGold,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Add Rider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBlack,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      // Cancel Button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.richGold.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    Function(String)? onChanged,
    bool showValidation = false,
    bool isValid = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.richGold.withOpacity(0.3),
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !showPassword,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.richGold),
          labelText: label,
          labelStyle: TextStyle(
            color: AppColors.richGold.withOpacity(0.7),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: AppColors.richGold.withOpacity(0.7),
                  ),
                  onPressed: onTogglePassword,
                )
              : showValidation
                  ? Icon(
                      isValid ? Icons.check_circle : Icons.cancel,
                      color: isValid ? Colors.green : Colors.red,
                    )
                  : null,
        ),
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
    vehicleNumberController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }
}