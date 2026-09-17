import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobileapp/routes/app_routes.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  static const String adminEmail = 'admin@laptopharbor.com';
  static const String adminPassword = 'Admin123';

  // Black and Golden Color Scheme (Premium)
  static const Color deepBlack = Color(0xFF0A0A0A);
  static const Color cardBlack = Color(0xFF151515);
  static const Color richGold = Color(0xFFCB9B51);
  static const Color lightGold = Color(0xFFF6E27A);
  static const Color shineGold = Color(0xFFF6E27A);
  static const Color softGold = Color(0xFFFAF0DC);

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: richGold,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // 🔴 STEP 1: ADMIN HARDCODE CHECK
      if (email == adminEmail && password == adminPassword) {
        print('✅ Hardcoded Admin Login');

        // ✅ Store fake admin UID in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('adminUid', 'hardcoded_admin_uid_12345');
        await prefs.setString('adminEmail', adminEmail);
        print('✅ Stored admin UID in SharedPreferences');

        // ✅ USE ROUTE NAME instead of direct widget
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
        return;
      }

      // 🔵 STEP 2: NORMAL USER LOGIN (FIREBASE)
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Login: ${userCredential.user!.email}');

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      String role = 'customer';

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': userCredential.user!.email,
          'name': userCredential.user!.email?.split('@')[0] ?? 'User',
          'role': 'customer',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        role = userDoc['role'] ?? 'customer';
      }

      // 🎯 STEP 3: ROLE-BASED NAVIGATION - USE ROUTE NAMES
      if (role == 'admin') {
        print('✅ Navigating to Admin Dashboard');
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else if (role == 'vendor') {
        print('✅ Navigating to Vendor Dashboard');
        Navigator.pushReplacementNamed(context, AppRoutes.vendorDashboard);
      } else if (role == 'rider') {
        print('✅ Navigating to Rider Dashboard');
        Navigator.pushReplacementNamed(context, AppRoutes.riderDashboard);
      } else {
        print('✅ Navigating to Customer Home Screen');
        // ✅ USE ROUTE NAME - This will automatically wrap with RoleBasedNav
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.message}'),
          backgroundColor: Colors.red[900],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Simple Password Reset (Firebase Standard Flow)
  Future<void> showSimplePasswordResetDialog() async {
    final TextEditingController resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isResetting = false;

          return Dialog(
            backgroundColor: cardBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: richGold.withOpacity(0.3), width: 1.5),
            ),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: richGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          color: richGold,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: lightGold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Receive reset link via email',
                              style: TextStyle(
                                fontSize: 12,
                                color: richGold.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: richGold, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Email Field
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: lightGold, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(
                        color: richGold.withOpacity(0.7),
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: richGold,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: deepBlack.withOpacity(0.5),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: richGold.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: richGold,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Info Message
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: richGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: richGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: richGold,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How it works:',
                                style: TextStyle(
                                  color: lightGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '1. Click "Send Reset Link"\n2. Check your email inbox\n3. Click the link in email\n4. Enter new password\n5. Login with new password',
                                style: TextStyle(
                                  color: softGold.withOpacity(0.8),
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isResetting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: richGold,
                            side: BorderSide(color: richGold.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [lightGold, richGold],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: richGold.withOpacity(0.4),
                                blurRadius: 15,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: isResetting
                                ? null
                                : () async {
                                    if (resetEmailController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please enter your email'),
                                          backgroundColor: Colors.red[900],
                                        ),
                                      );
                                      return;
                                    }

                                    setDialogState(() {
                                      isResetting = true;
                                    });

                                    try {
                                      await FirebaseAuth.instance
                                          .sendPasswordResetEmail(
                                        email: resetEmailController.text.trim(),
                                      );

                                      Navigator.pop(context);

                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: cardBlack,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            side: BorderSide(
                                              color: richGold.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.mark_email_read,
                                                color: richGold,
                                                size: 28,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Email Sent!',
                                                style: TextStyle(
                                                  color: lightGold,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Password reset link has been sent to:',
                                                style: TextStyle(
                                                  color: softGold.withOpacity(0.8),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                padding: EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                      richGold.withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  resetEmailController.text.trim(),
                                                  style: TextStyle(
                                                    color: richGold,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                '📧 Check your inbox & SPAM folder\n🔗 Click the reset link\n🔐 Enter new password\n✅ Login with new password\n\n⏰ Email may take 1-5 minutes',
                                                style: TextStyle(
                                                  color: softGold.withOpacity(0.8),
                                                  fontSize: 12,
                                                  height: 1.6,
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            Container(
                                              width: double.infinity,
                                              height: 45,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [lightGold, richGold],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  foregroundColor: deepBlack,
                                                  shadowColor: Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                  ),
                                                ),
                                                child: Text(
                                                  'OK',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      setDialogState(() {
                                        isResetting = false;
                                      });

                                      String errorMessage;
                                      if (e.code == 'user-not-found') {
                                        errorMessage =
                                            'No account found with this email. Please sign up first.';
                                      } else if (e.code == 'invalid-email') {
                                        errorMessage = 'Invalid email address format';
                                      } else if (e.code == 'missing-email') {
                                        errorMessage = 'Please enter your email';
                                      } else {
                                        errorMessage =
                                            'Error: ${e.message ?? e.code}. Check Firebase Console.';
                                      }

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red[900],
                                          duration: Duration(seconds: 5),
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: deepBlack,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isResetting
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: deepBlack,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Send Reset Link',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.5,
            colors: [Color(0xFF1F1F1F), deepBlack, Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo Section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [lightGold, richGold],
                          stops: [0.2, 0.8],
                        ),
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

                    // Brand Name
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

                    // Login Card
                    Container(
                      constraints: BoxConstraints(maxWidth: 400),
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBlack,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: richGold.withOpacity(0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: Offset(0, 10),
                          ),
                          BoxShadow(
                            color: richGold.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: lightGold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Please login to your account',
                            style: TextStyle(
                              fontSize: 12,
                              color: richGold.withOpacity(0.6),
                            ),
                          ),
                          SizedBox(height: 24),

                          // Email Field
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: lightGold, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              labelStyle: TextStyle(
                                color: richGold.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: richGold,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: deepBlack.withOpacity(0.5),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: richGold.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: richGold,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Password Field
                          TextField(
                            controller: passwordController,
                            obscureText: !_showPassword,
                            style: TextStyle(color: lightGold, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: richGold.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: richGold,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: deepBlack.withOpacity(0.5),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: richGold.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: richGold,
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: richGold.withOpacity(0.7),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showPassword = !_showPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: showSimplePasswordResetDialog,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: richGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Login Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [lightGold, richGold],
                                stops: [0.2, 0.8],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: richGold.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: deepBlack,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: deepBlack,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: richGold.withOpacity(0.2),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: richGold.withOpacity(0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: richGold.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Sign Up Link
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: softGold.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SignupScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    minimumSize: Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      color: richGold,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Footer
                    Text(
                      '© 2024 LaptopHarbor. All rights reserved.',
                      style: TextStyle(
                        color: richGold.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

