import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Is button ko apne Admin Dashboard mein add karein (temporary testing ke liye)
class TestNotificationButton extends StatelessWidget {
  const TestNotificationButton({Key? key}) : super(key: key);

  Future<void> createTestNotification(BuildContext context) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      if (currentUserId == null || currentUserId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        print('❌ No current user found');
        return;
      }

      print('🔍 Current User ID: $currentUserId');

      final docRef = FirebaseFirestore.instance.collection('notifications').doc();
      
      final notificationData = {
        'id': docRef.id,
        'userId': currentUserId,
        'title': 'Test Notification 🎉',
        'message': 'This is a test notification! If you see this, everything is working perfectly!',
        'vendorName': 'Test System',
        'productId': null,
        'productImage': null,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      print('📝 Creating notification with data: $notificationData');

      await docRef.set(notificationData);
      
      print('✅ Test notification created successfully!');
      print('📄 Document ID: ${docRef.id}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Test notification created! Check your notifications.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Verify the document was created
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ Verification: Document exists in Firestore');
        print('📊 Document data: ${doc.data()}');
      } else {
        print('❌ Verification failed: Document does not exist');
      }

    } catch (e, stackTrace) {
      print('❌ Error creating test notification: $e');
      print('📋 Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.add_alert),
      label: Text('Create Test Notification'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () => createTestNotification(context),
    );
  }
}

// Usage: Admin Dashboard mein yeh button add karein
// TestNotificationButton()