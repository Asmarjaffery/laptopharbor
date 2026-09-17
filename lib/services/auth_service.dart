import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Signup (customer/vendor)
  Future<UserModel?> signup(UserModel user, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: user.email, password: password);

      await _db.collection('users').doc(result.user!.uid).set({
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'role': user.role,
        'profileImage': user.profileImage ?? '',
      });

      return UserModel(
        id: result.user!.uid,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profileImage: user.profileImage,
      );
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  // Login
  Future<UserModel?> login(String email, String password) async {
    try {
      // Hardcoded admin login
      if (email == 'admin@laptopharbor.com' && password == 'Admin123') {
        return UserModel(
          id: 'admin',
          name: 'Admin',
          email: email,
          phone: '0000000000',
          role: 'admin',
          profileImage: null,
        );
      }

      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      final doc = await _db.collection('users').doc(result.user!.uid).get();

      if (doc.exists) {
        return UserModel.fromMap(doc.id, doc.data()!);
      }

      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get current Firebase user
  Future<UserModel?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        final doc = await _db.collection('users').doc(currentUser.uid).get();

        if (doc.exists) {
          return UserModel.fromMap(doc.id, doc.data()!);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Fetch current user failed: $e');
    }
  }
}
