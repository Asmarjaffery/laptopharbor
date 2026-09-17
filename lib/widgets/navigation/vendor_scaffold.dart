import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/colors.dart';
import '../../routes/app_routes.dart';
import '../../screens/auth/login_screen.dart';
import '../drawers/vendor_drawer.dart';
import '../sheets/vendor_notification_sheet.dart';
import '../sheets/vendor_message_sheet.dart';

class VendorScaffold extends StatefulWidget {
  final Widget child;
  const VendorScaffold({super.key, required this.child});

  @override
  State<VendorScaffold> createState() => _VendorScaffoldState();
}

class _VendorScaffoldState extends State<VendorScaffold> {
  Uint8List? _userImage;
  String _userName = 'User';
  int _vendorNotificationCount = 0;
  int _vendorMessageCount = 0;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _orderSubscription;
  StreamSubscription? _reviewSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _listenToVendorNotifications();
    _listenToVendorMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _orderSubscription?.cancel();
    _reviewSubscription?.cancel();
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

  void _listenToVendorMessages() {
    final vendorId = FirebaseAuth.instance.currentUser?.uid;
    if (vendorId == null) return;

    _messageSubscription = FirebaseFirestore.instance
        .collection('withdrawals')
        .where('vendorId', isEqualTo: vendorId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      int messageCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        if ((status == 'approved' || status == 'completed') &&
            data['vendorMessageRead'] != true) {
          messageCount++;
        }
      }

      if (mounted) {
        setState(() {
          _vendorMessageCount = messageCount;
        });
      }
    });
  }

  void _listenToVendorNotifications() {
    final vendorId = FirebaseAuth.instance.currentUser?.uid;
    if (vendorId == null) return;

    _orderSubscription = FirebaseFirestore.instance
        .collection('orders')
        .where('vendorId', isEqualTo: vendorId)
        .where('orderStatus', isEqualTo: 'Pending')
        .snapshots()
        .listen((orderSnapshot) {
      if (!mounted) return;

      int orderCount = 0;
      for (var doc in orderSnapshot.docs) {
        final data = doc.data();
        if (data['vendorNotificationRead'] != true) {
          orderCount++;
        }
      }

      _reviewSubscription = FirebaseFirestore.instance
          .collection('reviews')
          .where('vendorId', isEqualTo: vendorId)
          .snapshots()
          .listen((reviewSnapshot) {
        if (!mounted) return;

        int reviewCount = 0;
        for (var doc in reviewSnapshot.docs) {
          final data = doc.data();
          final status = data['status'] ?? '';
          if (status == 'approved' && data['vendorNotificationRead'] != true) {
            reviewCount++;
          }
        }

        if (mounted) {
          setState(() {
            _vendorNotificationCount = orderCount + reviewCount;
          });
        }
      });
    });
  }

  void _showVendorNotifications() async {
    final vendorId = FirebaseAuth.instance.currentUser?.uid;
    if (vendorId == null) return;

    await _orderSubscription?.cancel();
    await _reviewSubscription?.cancel();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VendorNotificationSheet(vendorId: vendorId),
    );

    await _markAllNotificationsAsRead(vendorId);
    _listenToVendorNotifications();
  }

  Future<void> _markAllNotificationsAsRead(String vendorId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final orders = await FirebaseFirestore.instance
          .collection('orders')
          .where('vendorId', isEqualTo: vendorId)
          .where('orderStatus', isEqualTo: 'Pending')
          .get();

      for (var doc in orders.docs) {
        batch.update(doc.reference, {'vendorNotificationRead': true});
      }

      final reviews = await FirebaseFirestore.instance
          .collection('reviews')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      for (var doc in reviews.docs) {
        batch.update(doc.reference, {'vendorNotificationRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  void _showVendorMessages() async {
    final vendorId = FirebaseAuth.instance.currentUser?.uid;
    if (vendorId == null) return;

    await _messageSubscription?.cancel();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VendorMessageSheet(vendorId: vendorId),
    );

    await _markMessagesAsRead(vendorId);
    _listenToVendorMessages();
  }

  Future<void> _markMessagesAsRead(String vendorId) async {
    try {
      final messages = await FirebaseFirestore.instance
          .collection('withdrawals')
          .where('vendorId', isEqualTo: vendorId)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in messages.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().toLowerCase();
        if ((status == 'approved' || status == 'completed') &&
            data['vendorMessageRead'] != true) {
          batch.update(doc.reference, {'vendorMessageRead': true});
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
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
        content: Text('Are you sure?', style: TextStyle(color: AppColors.softGold)),
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
      drawer: VendorDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        title: Text('Vendor Panel', style: TextStyle(color: AppColors.lightGold)),
        iconTheme: IconThemeData(color: AppColors.richGold),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.mail_outline, color: AppColors.richGold, size: 26),
                  onPressed: _showVendorMessages,
                ),
                if (_vendorMessageCount > 0)
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
                          _vendorMessageCount > 99 ? '99+' : '$_vendorMessageCount',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: Icon(Icons.notifications_outlined, color: AppColors.richGold, size: 26),
                  onPressed: _showVendorNotifications,
                ),
                if (_vendorNotificationCount > 0)
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
                          _vendorNotificationCount > 99 ? '99+' : '$_vendorNotificationCount',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.richGold,
              backgroundImage: _userImage != null ? MemoryImage(_userImage!) : null,
              child: _userImage == null
                  ? Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'V',
                      style: TextStyle(color: AppColors.deepBlack, fontSize: 16, fontWeight: FontWeight.bold),
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
}