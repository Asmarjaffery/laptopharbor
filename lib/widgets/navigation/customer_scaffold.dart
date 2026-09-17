import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobileapp/constants/colors.dart';
import 'package:mobileapp/routes/app_routes.dart';
import 'package:mobileapp/screens/auth/login_screen.dart';

class CustomerScaffold extends StatefulWidget {
  final Widget child;
  const CustomerScaffold({super.key, required this.child});

  @override
  State<CustomerScaffold> createState() => _CustomerScaffoldState();
}

class _CustomerScaffoldState extends State<CustomerScaffold> {
  Uint8List? _userImage;
  String _userName = 'User';
  int _unreadNotifications = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data();
      if (data == null) return;

      Uint8List? imageBytes;
      if (data['imageBinary'] != null) {
        imageBytes = Uint8List.fromList(List<int>.from(data['imageBinary']));
      }

      if (mounted) {
        setState(() {
          _userName = data['name'] ?? 'User';
          _userImage = imageBytes;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  void _listenToNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _notificationSubscription = FirebaseFirestore.instance
        .collection('customer_notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _unreadNotifications = snapshot.docs.length;
              });
            }
          },
          onError: (error) {
            debugPrint('Error listening to notifications: $error');
          },
        );
  }

  int get _currentIndex {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    switch (currentRoute) {
      case AppRoutes.home:
      case AppRoutes.customerHome:
        return 0;
      case AppRoutes.allProducts:
        return 1;
      case AppRoutes.cart:
        return 2;
      case AppRoutes.myOrders:
        return 3;
      default:
        return 0;
    }
  }

  void _go(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBlack,
        title: Text('Logout', style: TextStyle(color: AppColors.lightGold)),
        content: Text(
          'Are you sure?',
          style: TextStyle(color: AppColors.softGold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.softGold)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('Logout', style: TextStyle(color: AppColors.richGold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.laptop_mac, color: AppColors.richGold, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'LaptopHarbor',
                style: TextStyle(
                  color: AppColors.lightGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // WISHLIST ICON
          IconButton(
            icon: Icon(
              Icons.favorite_outline,
              color: AppColors.richGold,
              size: 22,
            ),
            onPressed: () => _go(AppRoutes.wishlist),
            tooltip: 'Wishlist',
          ),

          // NOTIFICATION ICON WITH BADGE
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              children: [
                Center(
                  child: IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppColors.richGold,
                      size: 22,
                    ),
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.customerNotifications,
                    ),
                    tooltip: 'Notifications',
                    padding: EdgeInsets.zero,
                  ),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.deepBlack,
                          width: 1.5,
                        ),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        _unreadNotifications > 9
                            ? '9+'
                            : '$_unreadNotifications',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // PROFILE AVATAR
          GestureDetector(
            onTap: () => _go(AppRoutes.customerProfile),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.richGold,
                backgroundImage: _userImage != null
                    ? MemoryImage(_userImage!)
                    : null,
                child: _userImage == null
                    ? Icon(Icons.person, color: AppColors.deepBlack, size: 18)
                    : null,
              ),
            ),
          ),

          // MORE MENU
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.richGold),
            color: AppColors.cardBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.richGold.withOpacity(0.3)),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: AppColors.richGold,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: TextStyle(color: AppColors.lightGold),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                _go(AppRoutes.customerProfile);
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppColors.deepBlack,
        selectedItemColor: AppColors.richGold,
        unselectedItemColor: AppColors.softGold,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        iconSize: 24,
        onTap: (index) {
          switch (index) {
            case 0:
              _go(AppRoutes.home);
              break;
            case 1:
              _go(AppRoutes.allProducts);
              break;
            case 2:
              _go(AppRoutes.cart);
              break;
            case 3:
              _go(AppRoutes.myOrders);
              break;
            case 4:
              _go(AppRoutes.chatBot);
              break;
            case 5:
              _go(AppRoutes.customerContactForm);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'ChatBot'),
          BottomNavigationBarItem(
            icon: Icon(Icons.contact_mail),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}
