import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobileapp/customer/ChatBotScreen.dart';


// ========================================
// METHOD 1: Firebase Auth User Photo
// ========================================
class ChatbotWithFirebaseAuth extends StatefulWidget {
  @override
  State<ChatbotWithFirebaseAuth> createState() => _ChatbotWithFirebaseAuthState();
}

class _ChatbotWithFirebaseAuthState extends State<ChatbotWithFirebaseAuth> {
  String? userImageUrl;
  String userName = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        setState(() {
          // Firebase Auth se directly photo URL
          userImageUrl = user.photoURL;
          userName = user.displayName ?? 'User';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChatbotScreen(
      userImageUrl: userImageUrl,
      userName: userName,
      isFullScreen: true,
    );
  }
}


// ========================================
// METHOD 2: Firebase Storage se Custom Path
// ========================================
class ChatbotWithFirebaseStorage extends StatefulWidget {
  final String userId; // User ki unique ID

  const ChatbotWithFirebaseStorage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatbotWithFirebaseStorage> createState() => _ChatbotWithFirebaseStorageState();
}

class _ChatbotWithFirebaseStorageState extends State<ChatbotWithFirebaseStorage> {
  String? userImageUrl;
  String userName = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserImage();
  }

  Future<void> _loadUserImage() async {
    try {
      // Firebase Storage se image URL fetch karna
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles/${widget.userId}/profile_image.jpg');
      
      // Download URL get karna
      final imageUrl = await storageRef.getDownloadURL();
      
      setState(() {
        userImageUrl = imageUrl;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading image from Firebase Storage: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChatbotScreen(
      userImageUrl: userImageUrl,
      userName: userName,
      isFullScreen: true,
    );
  }
}




class ChatbotWithFirestore extends StatefulWidget {
  final String userId;

  const ChatbotWithFirestore({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatbotWithFirestore> createState() => _ChatbotWithFirestoreState();
}

class _ChatbotWithFirestoreState extends State<ChatbotWithFirestore> {
  String? userImageUrl;
  String userName = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserFromFirestore();
  }

  Future<void> _loadUserFromFirestore() async {
    try {
      // Firestore se user data fetch karna
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data();
        
        setState(() {
          // Firestore mein saved image URL
          userImageUrl = userData?['profileImageUrl'];
          userName = userData?['name'] ?? 'User';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user from Firestore: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChatbotScreen(
      userImageUrl: userImageUrl,
      userName: userName,
      isFullScreen: true,
    );
  }
}


// ========================================
// METHOD 4: Real-time Listener (Auto Update)
// ========================================
class ChatbotWithRealtimeFirestore extends StatefulWidget {
  final String userId;

  const ChatbotWithRealtimeFirestore({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatbotWithRealtimeFirestore> createState() => _ChatbotWithRealtimeFirestoreState();
}

class _ChatbotWithRealtimeFirestoreState extends State<ChatbotWithRealtimeFirestore> {
  String? userImageUrl;
  String userName = 'User';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          userImageUrl = userData['profileImageUrl'];
          userName = userData['name'] ?? 'User';
        }

        return ChatbotScreen(
          userImageUrl: userImageUrl,
          userName: userName,
          isFullScreen: true,
        );
      },
    );
  }
}


// ========================================
// USAGE IN YOUR APP
// ========================================

// Example 1: Simple Firebase Auth
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatbotWithFirebaseAuth(),
    );
  }
}

// Example 2: With User ID
class MyApp2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return MaterialApp(
      home: ChatbotWithFirestore(userId: currentUserId),
    );
  }
}

// Example 3: Direct Use (agar pehle se image URL hai)
class MyApp3 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatbotScreen(
        userImageUrl: 'https://firebasestorage.googleapis.com/v0/b/your-app.appspot.com/o/users%2Fuser123%2Fprofile.jpg?alt=media&token=abc123',
        userName: 'Ahmed',
        isFullScreen: true,
      ),
    );
  }
}