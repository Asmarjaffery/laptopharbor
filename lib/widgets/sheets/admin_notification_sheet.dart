import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/colors.dart';

class AdminNotificationSheet extends StatelessWidget {
  const AdminNotificationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColors.deepBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildNotificationList(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_rounded, color: AppColors.richGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Notifications',
                  style: TextStyle(
                    color: AppColors.lightGold,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                StreamBuilder<int>(
                  stream: _getUnreadCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Text(
                      '$count unread',
                      style: TextStyle(
                        color: AppColors.softGold.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.done_all, color: AppColors.softGold, size: 24),
            onPressed: () => _markAllAsRead(context),
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Stream<int> _getUnreadCount() {
    return FirebaseFirestore.instance
        .collection('admin_notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Widget _buildNotificationList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        // ===== COMPREHENSIVE DEBUG LOGGING =====
        print('');
        print('📱 ===== NOTIFICATION SHEET DEBUG =====');
        print('📱 Stream State: ${snapshot.connectionState}');
        print('📱 Has Error: ${snapshot.hasError}');
        print('📱 Has Data: ${snapshot.hasData}');
        
        if (snapshot.hasError) {
          print('❌ ===== ERROR DETAILS =====');
          print('❌ Error: ${snapshot.error}');
          print('❌ Error Type: ${snapshot.error.runtimeType}');
          print('❌ Stack Trace: ${snapshot.stackTrace}');
        }
        
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          print('📱 Total Documents: ${docs.length}');
          print('📱 ===== DOCUMENT DETAILS =====');
          
          for (var i = 0; i < docs.length; i++) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            print('📱 --- Document #$i ---');
            print('   ID: ${doc.id}');
            print('   Type: ${data['type']}');
            print('   Title: ${data['title']}');
            print('   Message: ${data['message']}');
            print('   IsRead: ${data['isRead']}');
            print('   CreatedAt: ${data['createdAt']}');
            print('   CreatedAt Type: ${data['createdAt']?.runtimeType}');
            
            if (data['type'] == 'new_user_registration') {
              print('   👤 User Name: ${data['userName']}');
              print('   👤 User Email: ${data['userEmail']}');
              print('   👤 User Role: ${data['userRole']}');
            }
          }
        }
        print('📱 ===== END DEBUG =====');
        print('');
        // ===== END DEBUG LOGGING =====

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.richGold),
                const SizedBox(height: 16),
                Text(
                  'Loading notifications...',
                  style: TextStyle(color: AppColors.softGold),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error Loading Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Future.delayed(const Duration(milliseconds: 300), () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const AdminNotificationSheet(),
                        );
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.richGold,
                      foregroundColor: AppColors.deepBlack,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationCard(context, notifications[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_rounded,
                size: 100,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(height: 32),
              Text(
                'No Notifications',
                style: TextStyle(
                  color: AppColors.lightGold,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'All system notifications will appear here',
                style: TextStyle(
                  color: AppColors.softGold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Test Button - Remove in production
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '🧪 Testing Tools',
                      style: TextStyle(
                        color: AppColors.lightGold,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _createTestNotification(context),
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Create Test Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.richGold,
                        foregroundColor: AppColors.deepBlack,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _checkFirestoreAccess(context),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Check Firestore Access'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _listAllNotifications(context),
                      icon: const Icon(Icons.list),
                      label: const Text('List All Notifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTestNotification(BuildContext context) async {
    try {
      print('🧪 ===== CREATING TEST NOTIFICATION =====');
      
      final docRef = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
        'type': 'new_user_registration',
        'title': '🧪 Test User Registration',
        'message': 'Test User (Customer) just registered with email: test@example.com',
        'userId': 'test_${DateTime.now().millisecondsSinceEpoch}',
        'userName': 'Test User',
        'userEmail': 'test@example.com',
        'userRole': 'Customer',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Test notification created with ID: ${docRef.id}');
      
      // Verify it was created
      await Future.delayed(const Duration(milliseconds: 500));
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ Test notification verified in Firestore');
        print('✅ Data: ${doc.data()}');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ Test notification created: ${docRef.id}',
                style: TextStyle(color: AppColors.deepBlack),
              ),
              backgroundColor: Colors.greenAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error creating test notification: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _checkFirestoreAccess(BuildContext context) async {
    try {
      print('🔍 ===== CHECKING FIRESTORE ACCESS =====');
      
      // Try to read
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .limit(1)
          .get();
      
      print('✅ Read access: OK');
      print('✅ Documents found: ${snapshot.docs.length}');
      
      // Try to write
      final testDoc = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .add({
        'type': 'test',
        'title': 'Access Test',
        'message': 'Testing write access',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Write access: OK');
      print('✅ Test doc ID: ${testDoc.id}');
      
      // Delete test doc
      await testDoc.delete();
      print('✅ Delete access: OK');
      
      print('✅ ===== ALL ACCESS CHECKS PASSED =====');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ All Firestore access checks passed!',
              style: TextStyle(color: AppColors.deepBlack),
            ),
            backgroundColor: Colors.greenAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ ===== FIRESTORE ACCESS ERROR =====');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Firestore access error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _listAllNotifications(BuildContext context) async {
    try {
      print('📋 ===== LISTING ALL NOTIFICATIONS =====');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      print('📋 Total notifications found: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        print('⚠️ No notifications found in database');
      } else {
        for (var i = 0; i < snapshot.docs.length; i++) {
          final doc = snapshot.docs[i];
          final data = doc.data();
          print('');
          print('📋 Notification #${i + 1}:');
          print('   ID: ${doc.id}');
          print('   Type: ${data['type']}');
          print('   Title: ${data['title']}');
          print('   Message: ${data['message']}');
          print('   IsRead: ${data['isRead']}');
          print('   CreatedAt: ${data['createdAt']}');
        }
      }
      
      print('📋 ===== END LISTING =====');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📋 Found ${snapshot.docs.length} notifications. Check console.',
              style: TextStyle(color: AppColors.deepBlack),
            ),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error listing notifications: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildNotificationCard(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final type = data['type'] ?? '';
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final isUnread = data['isRead'] != true;

    // Format timestamp
    String timeAgo = '—';
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      try {
        final date = createdAt.toDate();
        final now = DateTime.now();
        final difference = now.difference(date);

        if (difference.inSeconds < 60) {
          timeAgo = 'Just now';
        } else if (difference.inMinutes < 60) {
          timeAgo = '${difference.inMinutes}m ago';
        } else if (difference.inHours < 24) {
          timeAgo = '${difference.inHours}h ago';
        } else if (difference.inDays < 7) {
          timeAgo = '${difference.inDays}d ago';
        } else {
          timeAgo = DateFormat('dd MMM').format(date);
        }
      } catch (e) {
        print('❌ Error parsing date: $e');
        timeAgo = 'Unknown';
      }
    } else if (createdAt == null) {
      timeAgo = 'Just now';
    }

    // Get icon and color configuration
    final config = _getNotificationConfig(type);

    return InkWell(
      onTap: () => _markAsRead(context, doc),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread
              ? config['color'].withOpacity(0.08)
              : AppColors.cardBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? config['color'].withOpacity(0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: config['color'].withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                config['icon'],
                color: config['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isUnread
                                ? AppColors.lightGold
                                : AppColors.softGold,
                            fontSize: 16,
                            fontWeight:
                                isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: config['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: AppColors.softGold.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      color: AppColors.softGold,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getNotificationConfig(String type) {
    switch (type) {
      case 'new_user_registration':
        return {
          'icon': Icons.person_add_rounded,
          'color': Colors.blueAccent,
        };
      case 'new_order':
        return {
          'icon': Icons.shopping_cart_rounded,
          'color': Colors.greenAccent,
        };
      case 'product_update':
        return {
          'icon': Icons.inventory_rounded,
          'color': Colors.orangeAccent,
        };
      case 'new_review':
        return {
          'icon': Icons.star_rounded,
          'color': AppColors.richGold,
        };
      case 'order_ready':
        return {
          'icon': Icons.check_circle_rounded,
          'color': Colors.tealAccent,
        };
      case 'order_received':
        return {
          'icon': Icons.local_shipping_rounded,
          'color': Colors.purpleAccent,
        };
      case 'order_delivered':
        return {
          'icon': Icons.done_all_rounded,
          'color': Colors.lightGreenAccent,
        };
      default:
        return {
          'icon': Icons.notifications_rounded,
          'color': AppColors.richGold,
        };
    }
  }

  Future<void> _markAsRead(BuildContext context, QueryDocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] == true) return; // Already read

      print('📱 Marking notification as read: ${doc.id}');
      
      await doc.reference.update({'isRead': true});
      
      print('✅ Notification marked as read: ${doc.id}');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notification as read'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    try {
      print('📱 ===== MARKING ALL AS READ =====');
      
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_notifications')
          .where('isRead', isEqualTo: false)
          .get();

      print('📱 Found ${snapshot.docs.length} unread notifications');

      if (snapshot.docs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No unread notifications'),
              backgroundColor: AppColors.softGold,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      
      print('✅ All notifications marked as read');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked ${snapshot.docs.length} notifications as read',
              style: TextStyle(color: AppColors.deepBlack),
            ),
            backgroundColor: AppColors.richGold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}