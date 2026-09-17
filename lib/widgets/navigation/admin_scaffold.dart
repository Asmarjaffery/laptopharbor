import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../constants/colors.dart';
import '../../screens/auth/login_screen.dart';
import '../drawers/admin_drawer.dart';
import '../sheets/admin_notification_sheet.dart';

class AdminScaffold extends StatefulWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {

  /// ✅ Dummy profile image (STATIC – NEVER NULL)
  final String profileImageUrl =
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      drawer: const AdminDrawer(),

      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        iconTheme: IconThemeData(color: AppColors.richGold),

        title: Text(
          'LaptopHarbor Admin',
          style: TextStyle(
            color: AppColors.lightGold,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ✅ FIXED: Wrap actions in Row with proper constraints
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate available space
              final isSmallScreen = MediaQuery.of(context).size.width < 600;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔔 Notifications with Badge
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('admin_notifications')
                        .where('isRead', isEqualTo: false)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.notifications, color: AppColors.richGold, size: 24),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => const AdminNotificationSheet(),
                              );
                            },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.deepBlack, width: 1.5),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('admin_notifications')
                                        .where('isRead', isEqualTo: false)
                                        .snapshots(),
                                    builder: (context, countSnapshot) {
                                      final count = countSnapshot.hasData 
                                          ? countSnapshot.data!.docs.length 
                                          : 0;
                                      return Text(
                                        count > 99 ? '99+' : count.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  /// 💬 Messages (Hide on small screens)
                  if (!isSmallScreen)
                    IconButton(
                      icon: Icon(Icons.message, color: AppColors.richGold, size: 24),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Messages clicked')),
                        );
                      },
                    ),

                  /// 👤 Profile Avatar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => _showProfileMenu(context),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.richGold,
                        child: ClipOval(
                          child: Image.network(
                            profileImageUrl,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.black,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  /// 🚪 Logout (Show as icon button or in menu)
                  if (!isSmallScreen)
                    IconButton(
                      icon: Icon(Icons.logout, color: AppColors.richGold, size: 24),
                      onPressed: _confirmLogout,
                    )
                  else
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.richGold, size: 24),
                      color: AppColors.cardBlack,
                      onSelected: (value) {
                        if (value == 'messages') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Messages clicked')),
                          );
                        } else if (value == 'logout') {
                          _confirmLogout();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'messages',
                          child: Row(
                            children: [
                              Icon(Icons.message, color: AppColors.softGold, size: 20),
                              const SizedBox(width: 12),
                              Text('Messages', style: TextStyle(color: AppColors.softGold)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: AppColors.softGold, size: 20),
                              const SizedBox(width: 12),
                              Text('Logout', style: TextStyle(color: AppColors.softGold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: widget.child,
    );
  }

  /// 👤 Profile Menu
  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.richGold,
              child: ClipOval(
                child: Image.network(
                  profileImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, size: 40, color: Colors.black);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Admin',
              style: TextStyle(
                color: AppColors.lightGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? 'admin@laptopharbor.com',
              style: TextStyle(color: AppColors.softGold, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.richGold),
              title: Text('Logout', style: TextStyle(color: AppColors.softGold)),
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔓 Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (_) => false,
    );
  }

  /// ⚠️ Logout Confirmation
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBlack,

        title: Text(
          'Logout',
          style: TextStyle(color: AppColors.lightGold),
        ),

        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.softGold),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.softGold),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppColors.richGold),
            ),
          ),
        ],
      ),
    );
  }
}