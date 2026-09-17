import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../screens/auth/login_screen.dart';
import '../drawers/rider_drawer.dart';
import '../sheets/rider_notification_sheet.dart';
import '../sheets/rider_message_sheet.dart';

class RiderScaffold extends StatefulWidget {
  final Widget child;
  const RiderScaffold({super.key, required this.child});

  @override
  State<RiderScaffold> createState() => _RiderScaffoldState();
}

class _RiderScaffoldState extends State<RiderScaffold> {
  Uint8List? _riderImage;
  String _riderName = 'Rider';
  String get _riderId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadRiderProfile();
  }

  Future<void> _loadRiderProfile() async {
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
          _riderName = data['name'] ?? 'Rider';
          _riderImage = imageBytes;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
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

  void _openRiderNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RiderNotificationSheet(riderId: _riderId),
    );
  }

  void _openRiderMessages() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RiderMessageSheet(riderId: _riderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      drawer: RiderDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text(
          'Rider Panel',
          style: TextStyle(color: AppColors.lightGold),
        ),
        iconTheme: IconThemeData(color: AppColors.richGold),
        actions: [
          _buildNotificationIcon(),
          _buildMessageIcon(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.richGold,
              backgroundImage: _riderImage != null ? MemoryImage(_riderImage!) : null,
              child: _riderImage == null
                  ? Text(
                      _riderName.isNotEmpty ? _riderName[0].toUpperCase() : 'R',
                      style: TextStyle(
                        color: AppColors.deepBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.richGold),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: widget.child,
    );
  }

  Widget _buildNotificationIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: _riderId)
          .where('orderStatus', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_outlined, color: AppColors.richGold, size: 26),
              onPressed: _openRiderNotifications,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.deepBlack, width: 1.5),
                  ),
                  constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageIcon() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rider_messages')
          .where('riderId', isEqualTo: _riderId)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.mail_outline, color: AppColors.richGold, size: 26),
              onPressed: _openRiderMessages,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.deepBlack, width: 1.5),
                  ),
                  constraints: BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}