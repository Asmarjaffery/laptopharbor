import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  // Password strength
  double _passwordStrength = 0;
  String _strengthText = "Weak";

  // Image storage
  Uint8List? _binaryImage;

  // Premium Theme Colors
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF151515);
  static const Color richGold = Color(0xFFCB9B51);
  static const Color lightGold = Color(0xFFF6E27A);
  static const Color softGold = Color(0xFFFAF0DC);

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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Cannot pick image on this platform")));
    }
  }

  Future<void> signup() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: richGold,
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
          content: Text("Please select an image"),
          backgroundColor: Colors.red[900],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'imageBinary': _binaryImage,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Signup Successful"),
          backgroundColor: richGold,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Signup failed'),
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
        child: Icon(Icons.person_add_alt_1, size: 40, color: deepBlack),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Container(
              constraints: BoxConstraints(maxWidth: 420),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBlack,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: richGold.withOpacity(0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 30, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  // ===== Premium Logo & Brand Header =====
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [lightGold, richGold]),
                      boxShadow: [
                        BoxShadow(
                          color: richGold.withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(Icons.laptop_mac, size: 40, color: deepBlack),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'LaptopHarbor',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: lightGold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: richGold.withOpacity(0.5),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'PREMIUM LAPTOP COLLECTION',
                    style: TextStyle(
                      fontSize: 10,
                      color: richGold.withOpacity(0.7),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 30),
                  // ===== End of Logo & Header =====

                  GestureDetector(
                    onTap: pickImage,
                    child: _buildImagePreview(),
                  ),
                  SizedBox(height: 16),

                  Text("Create Account", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: lightGold)),
                  SizedBox(height: 24),

                  buildField(controller: nameController, label: "Full Name", icon: Icons.person_outline),
                  SizedBox(height: 16),
                  buildField(controller: emailController, label: "Email Address", icon: Icons.email_outlined, keyboard: TextInputType.emailAddress),
                  SizedBox(height: 16),
                  buildField(controller: phoneController, label: "Phone Number", icon: Icons.phone_outlined, keyboard: TextInputType.phone),
                  SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: !_showPassword,
                    onChanged: _checkPasswordStrength,
                    style: TextStyle(color: lightGold),
                    decoration: inputDecoration(
                      "Password",
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off, color: richGold),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _passwordStrength,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _passwordStrength <= 0.25 ? Colors.red : _passwordStrength <= 0.75 ? Colors.orange : richGold),
                  ),
                  SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Strength: $_strengthText",
                      style: TextStyle(
                          color: _passwordStrength <= 0.25 ? Colors.red : _passwordStrength <= 0.75 ? Colors.orange : richGold,
                          fontSize: 12),
                    ),
                  ),
                  SizedBox(height: 16),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    style: TextStyle(color: lightGold),
                    decoration: inputDecoration(
                      "Confirm Password",
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: richGold),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [lightGold, richGold]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : signup,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                      child: _isLoading
                          ? CircularProgressIndicator(color: deepBlack)
                          : Text("Sign Up", style: TextStyle(color: deepBlack, fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                    },
                    child: Text("Already have an account? Login", style: TextStyle(color: richGold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: TextStyle(color: lightGold),
      decoration: inputDecoration(label, icon),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: richGold.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: richGold),
      suffixIcon: suffix,
      filled: true,
      fillColor: deepBlack.withOpacity(0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: richGold.withOpacity(0.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: richGold, width: 2)),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
