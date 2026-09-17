import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/constants/colors.dart';
import 'package:mobileapp/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // 🔥 Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // ⏳ Navigate after animation
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // 🛍️ ALWAYS go to home page first (Guest Mode)
      // User can browse products without login
      Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      
      // 💡 Login will be required only when:
      // - Adding to cart
      // - Checkout
      // - Viewing orders
      // - Profile access
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.laptop_mac,
                  size: 120,
                  color: AppColors.richGold,
                ),
                const SizedBox(height: 20),
                Text(
                  'LaptopHarbor',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightGold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                CircularProgressIndicator(
                  color: AppColors.richGold,
                  strokeWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}